//
//  GoodDeedTaskView.swift
//  scrolldeeds
//
//  Deed-task screen that mirrors the dhikr screen layout exactly:
//  step indicator → hero content → Spacer → big circle button → Spacer.
//

import SwiftUI

struct GoodDeedTaskView: View {
    let task: GoodDeedTask
    let onCompleted: (Int) -> Void
    /// When set, the parent shows the completion card over the full screen (including the logo).
    var onReadyToConfirm: ((String) -> Void)? = nil

    // ── Appearance ─────────────────────────────────────────────
    @State private var heroAppeared  = false
    @State private var breathe       = false

    // ── Typed input ────────────────────────────────────────────
    @State private var typedText = ""
    @FocusState private var isInputFocused: Bool

    // ── Button ripple (same as dhikr) ───────────────────────────
    @State private var ripple1Scale:   CGFloat = 1
    @State private var ripple1Opacity: Double  = 0
    @State private var ripple2Scale:   CGFloat = 1
    @State private var ripple2Opacity: Double  = 0

    // ── Completion state ────────────────────────────────────────
    @State private var isCompleting  = false
    @State private var verifyGlow    = false
    @State private var showCompletion = false
    @State private var completionAppeared = false

    // ── Surah/Dua: translate toggle (saves space, prevents overlap) ──
    @State private var showTranslation = false

    var body: some View {
        GeometryReader { geo in
            let btnSize: CGFloat = min(geo.size.width * 0.38, 150)
            let safeBottom: CGFloat = max(geo.safeAreaInsets.bottom, 24)
            let gradientHeight: CGFloat = 120
            let minGapAboveButton: CGFloat = 72
            let barHeight: CGFloat = 56
            let barLabelSpace: CGFloat = 10
            let btnAreaContent: CGFloat = task.requiresInput
                ? (barHeight + barLabelSpace + 22 + safeBottom + 20)
                : (btnSize + 22 + 18 + 24 + safeBottom + 16)
            let totalPinHeight: CGFloat = gradientHeight + btnAreaContent + minGapAboveButton
            // Bij input + toetsenbord: geen grote reserve (bar staat in scroll onder badge)
            let reserveHeight: CGFloat = (task.requiresInput && isInputFocused) ? 24 : totalPinHeight

            ZStack(alignment: .bottom) {
                // Background
                AppTheme.background
                LinearGradient(
                    colors: [AppTheme.primary.opacity(0.0), AppTheme.primary.opacity(0.05)],
                    startPoint: .top, endPoint: .bottom
                )

                // ── Scrollable content ─────────────────────────────────────────────────────────────
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 22)

                        heroContent
                            .padding(.horizontal, 28)
                            .padding(.top, 28)
                            .padding(.bottom, 32)
                            .opacity(heroAppeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.4), value: heroAppeared)

                        Color.clear.frame(height: reserveHeight)
                    }
                }

                // ── Pinned button: balk onderaan bij input (toetsenbord dicht), cirkel bij overige taken ──
                // Bij input + toetsenbord open: bar staat in scroll onder badge, hier niets tonen
                if !(task.requiresInput && isInputFocused) {
                    pinnedButtonZone(
                        geo: geo,
                        btnSize: btnSize,
                        safeBottom: safeBottom,
                        gradientHeight: gradientHeight,
                        barHeight: barHeight,
                        barLabelSpace: barLabelSpace
                    )
                }
            }
        }
        .overlay {
            if showCompletion, onReadyToConfirm == nil { completionOverlay }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.38).delay(0.1)) { heroAppeared = true }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { breathe = true }
        }
    }

    // MARK: - Pinned button zone (cirkel of balk)

    @ViewBuilder
    private func pinnedButtonZone(
        geo: GeometryProxy,
        btnSize: CGFloat,
        safeBottom: CGFloat,
        gradientHeight: CGFloat,
        barHeight: CGFloat,
        barLabelSpace: CGFloat
    ) -> some View {
        let inputReady = !task.requiresInput || !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        VStack(spacing: task.requiresInput ? barLabelSpace : 18) {
            if task.requiresInput {
                inputTaskBarButton(inputReady: inputReady)
                    .padding(.horizontal, 24)
            } else {
                ZStack {
                    if isCompleting {
                        Circle()
                            .fill(AppTheme.gradientPrimary)
                            .frame(width: btnSize, height: btnSize)
                            .shadow(color: AppTheme.primary.opacity(0.55), radius: 24, y: 8)
                            .scaleEffect(verifyGlow ? 1.07 : 1.0)
                            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: verifyGlow)
                            .onAppear { verifyGlow = true }
                        SwiftUI.ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                    } else {
                        Button(action: handleDone) {
                            ZStack {
                                Circle()
                                    .fill(inputReady
                                          ? AppTheme.gradientPrimary
                                          : LinearGradient(colors: [AppTheme.textMuted.opacity(0.28), AppTheme.textMuted.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: btnSize, height: btnSize)
                                    .shadow(color: AppTheme.primary.opacity(inputReady ? 0.38 : 0), radius: 20, y: 8)
                                    .scaleEffect(breathe && inputReady ? 1.022 : 1.0)
                                Image(systemName: "checkmark")
                                    .font(.system(size: btnSize * 0.32, weight: .semibold))
                                    .foregroundColor(.white.opacity(inputReady ? 1 : 0.45))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.easeInOut(duration: 0.22), value: inputReady)
                    }
                }
                .frame(width: btnSize + 22, height: btnSize + 22)
            }

            if !task.requiresInput {
                Group {
                    if isCompleting {
                        Text(NSLocalizedString("practice.verifying", comment: ""))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    } else {
                        Text(NSLocalizedString("task.tap_when_done", comment: ""))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.18), value: isCompleting)
            }
        }
        .opacity(heroAppeared ? 1 : 0)
        .animation(.easeOut(duration: 0.35).delay(0.12), value: heroAppeared)
        .padding(.bottom, safeBottom + 20)
        .padding(.top, gradientHeight)
        .background(Color.clear)
        .ignoresSafeArea(edges: .bottom)
    }

    // Balk-knop voor typ-taken (onder badge of onderaan scherm)
    private func inputTaskBarButton(inputReady: Bool) -> some View {
        Button(action: handleDone) {
            HStack(spacing: 10) {
                if isCompleting {
                    SwiftUI.ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.0)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                    Text(typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                         ? NSLocalizedString("task.type_first", comment: "")
                         : NSLocalizedString("task.tap_when_done", comment: ""))
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white.opacity(inputReady ? 1 : 0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(inputReady
                          ? AnyShapeStyle(AppTheme.gradientPrimary)
                          : AnyShapeStyle(LinearGradient(colors: [AppTheme.textMuted.opacity(0.28), AppTheme.textMuted.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(inputReady ? Color.clear : AppTheme.textMuted.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: AppTheme.primary.opacity(inputReady ? 0.35 : 0), radius: 12, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!inputReady || isCompleting)
        .animation(.easeInOut(duration: 0.22), value: inputReady)
    }

    private var localizedTaskTitle: String {
        NSLocalizedString("task.\(task.id).title", value: task.title, comment: "")
    }
    private var localizedTaskInstruction: String {
        NSLocalizedString("task.\(task.id).instruction", value: task.instruction, comment: "")
    }

    // MARK: - Hero content

    @ViewBuilder
    private var heroContent: some View {
        if task.isSurahTask, let key = task.surahKey, let arabic = SurahContent.arabic(key: key) {
            // ── Surah: Arabic + Translate toggle (translation optional to save space, prevent overlap) ───
            VStack(spacing: 20) {
                // Title row
                Text(localizedTaskTitle.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)

                // Arabic óf vertaling — vervangt elkaar (geen uitklap, geen overlap)
                Group {
                    if showTranslation {
                        Text(NSLocalizedString(SurahContent.translationKey(key: key), comment: ""))
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(arabic)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .environment(\.layoutDirection, .rightToLeft)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.78), value: showTranslation)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

                // Translate toggle — wisselt tussen Arabisch en vertaling
                Button(action: {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        showTranslation.toggle()
                    }
                    HapticManager.shared.selection()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showTranslation ? "doc.text.fill" : "globe")
                            .font(.system(size: 13, weight: .semibold))
                        Text(showTranslation
                             ? NSLocalizedString("dhikr.toggle.arabic", comment: "")
                             : NSLocalizedString("dhikr.toggle.translate", comment: ""))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(showTranslation ? AppTheme.textSecondary : AppTheme.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(showTranslation
                                       ? AppTheme.muted
                                       : AppTheme.primary.opacity(0.12))
                    )
                    .overlay(
                        Capsule().stroke(showTranslation
                                         ? AppTheme.textMuted.opacity(0.20)
                                         : AppTheme.primary.opacity(0.30),
                                         lineWidth: 1.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .animation(.easeInOut(duration: 0.22), value: showTranslation)

                unlockPill
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.78), value: showTranslation)
        } else if task.isDuaTask, let key = task.duaKey, let arabic = DuaContent.arabic(key: key) {
            // ── Dua / Verse: Arabic + Translate toggle (translation optional to save space) ────────
            VStack(spacing: 20) {
                // Title row
                Text(localizedTaskTitle.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)

                // Arabic óf vertaling — vervangt elkaar (geen uitklap, geen overlap)
                Group {
                    if showTranslation {
                        Text(NSLocalizedString(DuaContent.translationKey(key: key), comment: ""))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(arabic)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .environment(\.layoutDirection, .rightToLeft)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.78), value: showTranslation)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

                // Translate toggle — wisselt tussen Arabisch en vertaling
                Button(action: {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        showTranslation.toggle()
                    }
                    HapticManager.shared.selection()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showTranslation ? "doc.text.fill" : "globe")
                            .font(.system(size: 13, weight: .semibold))
                        Text(showTranslation
                             ? NSLocalizedString("dhikr.toggle.arabic", comment: "")
                             : NSLocalizedString("dhikr.toggle.translate", comment: ""))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(showTranslation ? AppTheme.textSecondary : AppTheme.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(showTranslation
                                       ? AppTheme.muted
                                       : AppTheme.primary.opacity(0.12))
                    )
                    .overlay(
                        Capsule().stroke(showTranslation
                                         ? AppTheme.textMuted.opacity(0.20)
                                         : AppTheme.primary.opacity(0.30),
                                         lineWidth: 1.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .animation(.easeInOut(duration: 0.22), value: showTranslation)

                unlockPill
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.78), value: showTranslation)
        } else if task.requiresInput {
            // ── Typed reflection task ─────────────────────────────
            VStack(spacing: 18) {
                // Icon (smaller to leave room for input)
                Image(systemName: taskIcon)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [taskAccentColor, taskAccentColor.opacity(0.70)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: taskAccentColor.opacity(0.22), radius: 12, y: 4)

                // Task name
                Text(localizedTaskTitle.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)

                // Instruction as prompt
                Text(localizedTaskInstruction)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                // ── Text input field ─────────────────────────
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.cardSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isInputFocused
                                        ? taskAccentColor.opacity(0.55)
                                        : AppTheme.border,
                                        lineWidth: isInputFocused ? 1.5 : 1)
                        )
                        .animation(.easeInOut(duration: 0.2), value: isInputFocused)

                    // Placeholder
                    if typedText.isEmpty {
                        Text(NSLocalizedString(task.inputPlaceholderKey, comment: ""))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AppTheme.textMuted)
                            .padding(.horizontal, 14)
                            .padding(.top, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $typedText)
                        .focused($isInputFocused)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .frame(minHeight: 90, maxHeight: 120)
                }
                .frame(maxWidth: .infinity)
                .onTapGesture { isInputFocused = true }

                unlockPill

                // Toetsenbord open: balk direct onder badge met mooie spacing
                if isInputFocused {
                    let inputReady = !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    VStack(spacing: 0) {
                        Spacer().frame(height: 24)
                        inputTaskBarButton(inputReady: inputReady)
                            .padding(.horizontal, 0)
                    }
                }
            }
        } else {
            // ── Standard instruction deed ─────────────────────────
            VStack(spacing: 16) {
                // Large icon — matches role of Arabic hero text
                Image(systemName: taskIcon)
                    .font(.system(size: 68, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [taskAccentColor, taskAccentColor.opacity(0.70)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: taskAccentColor.opacity(0.25), radius: 16, y: 6)

                // Task name
                Text(localizedTaskTitle.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)

                // Instruction
                Text(localizedTaskInstruction)
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 8)
                    .fixedSize(horizontal: false, vertical: true)

                unlockPill
            }
        }
    }

    // MARK: - Shared unlock pill (identical to dhikrScreen)

    private var unlockPill: some View {
        DeedCoinBadge(coins: task.coins, size: 12)
        .foregroundColor(taskAccentColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(taskAccentColor.opacity(0.11))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(taskAccentColor.opacity(0.22), lineWidth: 1))
    }

    // MARK: - Icon per task ID

    private var taskIcon: String {
        switch task.id {
        case "med_6":  return "figure.2.and.child.holdinghands"
        case "med_7":  return "person.3.fill"
        case "med_8":  return "sun.max.fill"
        case "hard_1": return "crown.fill"
        case "hard_2": return "hands.sparkles.fill"
        case "hard_3": return "heart.text.square.fill"
        case "med_14": return "sun.and.horizon.fill"
        case "med_15": return "heart.fill"
        case "med_16": return "shield.fill"
        case "med_17": return "moon.stars.fill"
        case "med_18": return "leaf.fill"
        case "med_19": return "drop.fill"
        case "med_20": return "hourglass"
        case "hard_4": return "text.book.closed.fill"
        case "hard_5": return "eye.slash.fill"
        case "hard_6": return "star.fill"
        default:       return "sparkles"
        }
    }

    private var taskAccentColor: Color { task.difficulty.accentColor }

    // MARK: - Completion overlay

    private var completionOverlay: some View {
        ZStack {
            // Soft blurred backdrop
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { } // absorb taps

            VStack(spacing: 0) {
                // ── Icon ────────────────────────────────────────
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(AppTheme.primary.opacity(0.08))
                        .frame(width: 76, height: 76)
                    Image(systemName: "checkmark")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.primaryLight, AppTheme.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 36)
                .padding(.bottom, 20)

                // ── Title ────────────────────────────────────────
                Text(NSLocalizedString("task.confirmation.title", comment: ""))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(localizedTaskTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.top, 4)
                    .padding(.bottom, task.requiresInput && !typedText.isEmpty ? 16 : 24)

                // ── Typed response card (only for input tasks) ────
                if task.requiresInput && !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.primary.opacity(0.6))
                        Text(typedText.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.cardSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.primary.opacity(0.15), lineWidth: 1))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }

                // ── Divider ──────────────────────────────────────
                Rectangle()
                    .fill(AppTheme.textMuted.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 28)

                // ── Unlock row ───────────────────────────────────
                DeedCoinBadge(coins: task.coins, size: 17)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.vertical, 20)

                // ── Divider ──────────────────────────────────────
                Rectangle()
                    .fill(AppTheme.textMuted.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 28)

                // ── Soft message ─────────────────────────────────
                Text(NSLocalizedString("task.confirmation.message", comment: ""))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)

                // ── Continue button ──────────────────────────────
                Button(action: { onCompleted(task.unlockMinutes) }) {
                    Text(NSLocalizedString("task.completion_continue", comment: ""))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(ActionCardButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(AppTheme.card)
                    .shadow(color: .black.opacity(0.18), radius: 40, y: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(AppTheme.primary.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(completionAppeared ? 1 : 0.88)
            .opacity(completionAppeared ? 1 : 0)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                completionAppeared = true
            }
        }
    }

    // MARK: - Action

    private func handleDone() {
        guard !isCompleting else { return }
        guard !task.requiresInput || !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Dismiss keyboard first if open
        isInputFocused = false

        triggerRipple()
        HapticManager.shared.taskCompleted()
        UserDefaults.standard.set(task.unlockMinutes, forKey: UserDataManager.pendingUnlockMinutesKey)

        withAnimation { isCompleting = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            isCompleting = false
            verifyGlow   = false
            HapticManager.shared.completionShown()
            if let onReadyToConfirm {
                onReadyToConfirm(typedText)
            } else {
                withAnimation { showCompletion = true }
            }
        }
    }

    private func triggerRipple() {
        ripple1Scale = 1.0; ripple1Opacity = 0.65
        withAnimation(.easeOut(duration: 0.85)) { ripple1Scale = 1.75; ripple1Opacity = 0.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            ripple2Scale = 1.0; ripple2Opacity = 0.45
            withAnimation(.easeOut(duration: 0.78)) { ripple2Scale = 1.65; ripple2Opacity = 0.0 }
        }
    }
}
