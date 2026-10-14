//
//  PracticeSessionView.swift
//  scrolldeeds
//

import SwiftUI

// MARK: - Practice Step

enum PracticeStep {
    case taskReveal         // animated task selection
    case dhikrTask          // existing dhikr screen (Arabic + tap 3×)
    case deedTask           // new task card + "I completed it"
}

// MARK: - Dhikr Types

enum DhikrType: String, CaseIterable {
    // Original 4
    case alhamdulillah              = "Alhamdulillah"
    case astaghfirullah             = "Astaghfirullah"
    case allahuAkbar                = "Allahu Akbar"
    case subhanallah                = "Subhanallah"
    // New 4 — added for Good Deed task integration
    case laIlahaIllaAllah           = "La ilaha illa Allah"
    case salawat                    = "Salawat"
    case subhanAllahiWaBihamdihi    = "SubhanAllahi wa bihamdihi"
    case laHawla                    = "La hawla wa la quwwata illa billah"
    case bismillah                  = "Bismillah"
    case hasbunallah                = "Hasbunallah"

    /// Full Salawat Ibrahimiyya (same in all locales).
    static let salawatArabicFull = "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ"

    var arabic: String {
        switch self {
        case .alhamdulillah:             return "اَلْحَمْدُ لِلّٰهِ"
        case .astaghfirullah:            return "أَسْتَغْفِرُ اللّٰهَ"
        case .allahuAkbar:               return "اللّٰهُ أَكْبَرُ"
        case .subhanallah:               return "سُبْحَانَ اللّٰهِ"
        case .laIlahaIllaAllah:          return "لَا إِلٰهَ إِلَّا اللّٰهُ"
        case .salawat:                   return Self.salawatArabicFull
        case .subhanAllahiWaBihamdihi:   return "سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ"
        case .laHawla:                   return "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ"
        case .bismillah:                 return "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
        case .hasbunallah:               return "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ"
        }
    }

    var instruction: String {
        switch self {
        case .alhamdulillah:             return NSLocalizedString("dhikr.alhamdulillah.instruction", comment: "")
        case .astaghfirullah:            return NSLocalizedString("dhikr.astaghfirullah.instruction", comment: "")
        case .allahuAkbar:               return NSLocalizedString("dhikr.allahu_akbar.instruction", comment: "")
        case .subhanallah:               return NSLocalizedString("dhikr.subhanallah.instruction", comment: "")
        case .laIlahaIllaAllah:          return NSLocalizedString("dhikr.la_ilaha.instruction", comment: "")
        case .salawat:                   return NSLocalizedString("dhikr.salawat.instruction", comment: "")
        case .subhanAllahiWaBihamdihi:   return NSLocalizedString("dhikr.subhanallahi_wabihamdihi.instruction", comment: "")
        case .laHawla:                   return NSLocalizedString("dhikr.la_hawla.instruction", comment: "")
        case .bismillah:                 return NSLocalizedString("dhikr.bismillah.instruction", comment: "")
        case .hasbunallah:               return NSLocalizedString("dhikr.hasbunallah.instruction", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .alhamdulillah:             return "hands.sparkles.fill"
        case .astaghfirullah:            return "heart.fill"
        case .allahuAkbar:               return "star.fill"
        case .subhanallah:               return "moon.stars.fill"
        case .laIlahaIllaAllah:          return "infinity"
        case .salawat:                   return "heart.circle.fill"
        case .subhanAllahiWaBihamdihi:   return "sparkles"
        case .laHawla:                   return "shield.fill"
        case .bismillah:                 return "book.fill"
        case .hasbunallah:               return "checkmark.shield.fill"
        }
    }

    var description: String {
        switch self {
        case .alhamdulillah:             return NSLocalizedString("dhikr.alhamdulillah.desc", comment: "")
        case .astaghfirullah:            return NSLocalizedString("dhikr.astaghfirullah.desc", comment: "")
        case .allahuAkbar:               return NSLocalizedString("dhikr.allahu_akbar.desc", comment: "")
        case .subhanallah:               return NSLocalizedString("dhikr.subhanallah.desc", comment: "")
        case .laIlahaIllaAllah:          return NSLocalizedString("dhikr.la_ilaha.desc", comment: "")
        case .salawat:                   return NSLocalizedString("dhikr.salawat.desc", comment: "")
        case .subhanAllahiWaBihamdihi:   return NSLocalizedString("dhikr.subhanallahi_wabihamdihi.desc", comment: "")
        case .laHawla:                   return NSLocalizedString("dhikr.la_hawla.desc", comment: "")
        case .bismillah:                 return NSLocalizedString("dhikr.bismillah.desc", comment: "")
        case .hasbunallah:               return NSLocalizedString("dhikr.hasbunallah.desc", comment: "")
        }
    }

    /// Full meaning in the user's language — shown when translation toggle is active.
    var fullTranslation: String {
        switch self {
        case .alhamdulillah:             return NSLocalizedString("dhikr.alhamdulillah.full", comment: "")
        case .astaghfirullah:            return NSLocalizedString("dhikr.astaghfirullah.full", comment: "")
        case .allahuAkbar:               return NSLocalizedString("dhikr.allahu_akbar.full", comment: "")
        case .subhanallah:               return NSLocalizedString("dhikr.subhanallah.full", comment: "")
        case .laIlahaIllaAllah:          return NSLocalizedString("dhikr.la_ilaha.full", comment: "")
        case .salawat:                   return NSLocalizedString("dhikr.salawat.translation_full", comment: "")
        case .subhanAllahiWaBihamdihi:   return NSLocalizedString("dhikr.subhanallahi_wabihamdihi.full", comment: "")
        case .laHawla:                   return NSLocalizedString("dhikr.la_hawla.full", comment: "")
        case .bismillah:                 return NSLocalizedString("dhikr.bismillah.full", comment: "")
        case .hasbunallah:               return NSLocalizedString("dhikr.hasbunallah.full", comment: "")
        }
    }

    static func random() -> DhikrType {
        DhikrType.allCases.randomElement() ?? .alhamdulillah
    }
}

// MARK: - Main View

struct PracticeSessionView: View {
    @ObservedObject var detector: RecitationDetector
    let onCompleted: () -> Void
    @Environment(\.dismiss) private var dismiss

    @StateObject private var audioRecorder = AudioRecorderManager()
    @StateObject private var webhookService = WebhookService()
    @ObservedObject private var shieldManager = ShieldManager.shared
    @ObservedObject private var userDataManager = UserDataManager.shared

    @State private var showVerificationSheet = false
    @State private var verificationMessage = ""
    @State private var selectedDhikr: DhikrType = .subhanallah
    @State private var hasGrantedGraceUnlock = false
    @State private var shouldUnlockAfterAlert = false
    @State private var showDhikrCompletion = false
    @State private var dhikrCompletionAppeared = false
    @State private var unlockedCoins = 0
    @State private var showForceAppSelection = false
    @State private var hasCompletedFirstDhikr = false

    // Practice step state machine
    @State private var practiceStep: PracticeStep = .taskReveal
    @State private var selectedGoodDeedTask: GoodDeedTask?
    @State private var activeUnlockMinutes: Int = 60
    @State private var showDeedCompletion = false
    @State private var deedCompletionTypedText = ""
    @State private var deedCompletionAppeared = false

    // Dhikr taps (step 2 — dhikr style)
    @State private var dhikrTapCount = 0
    @State private var dhikrAppeared = false
    @State private var showTranslation = false

    /// How many taps the user needs to complete (3 for normal dhikr, 33 for extended tasks).
    private var requiredTaps: Int { selectedGoodDeedTask?.requiredTaps ?? 3 }

    // Global animations
    @State private var breathe = false
    @State private var ripple1Scale: CGFloat = 1.0
    @State private var ripple1Opacity: Double = 0.0
    @State private var ripple2Scale: CGFloat = 1.0
    @State private var ripple2Opacity: Double = 0.0
    @State private var verifyGlow = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            LinearGradient(
                colors: [AppTheme.primary.opacity(0.0), AppTheme.primary.opacity(0.06)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                sessionTopBar
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                GeometryReader { geo in
                    Group {
                        switch practiceStep {
                        case .taskReveal:
                            if let task = selectedGoodDeedTask {
                                TaskRevealView(selectedTask: task) {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                                        if task.isDhikr, let type = task.dhikrType {
                                            selectedDhikr = type
                                            dhikrTapCount = 0
                                            activeUnlockMinutes = task.unlockMinutes
                                            practiceStep = .dhikrTask
                                        } else {
                                            activeUnlockMinutes = task.unlockMinutes
                                            practiceStep = .deedTask
                                        }
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                    removal:   .opacity
                                ))
                            }

                        case .dhikrTask:
                            dhikrScreen(geo: geo)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                    removal:   .opacity
                                ))

                        case .deedTask:
                            if let task = selectedGoodDeedTask {
                                GoodDeedTaskView(
                                    task: task,
                                    onCompleted: { minutes in
                                        finishDeed(task, minutes: minutes)
                                    },
                                    onReadyToConfirm: { typed in
                                        deedCompletionTypedText = typed
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            showDeedCompletion = true
                                        }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                    removal:   .opacity
                                ))
                            }
                        }
                    }
                    .animation(.spring(response: 0.52, dampingFraction: 0.82), value: practiceStep)
                }
            }

            if showDhikrCompletion {
                dhikrCompletionOverlay
            } else if showDeedCompletion, let task = selectedGoodDeedTask {
                deedCompletionOverlay(task: task)
            } else if showVerificationSheet {
                // Warning / error / premium states still use CustomAlertView
                let isWarning = verificationMessage.contains("⚠️")
                CustomAlertView(
                    title: NSLocalizedString("practice.verification_title", comment: ""),
                    message: verificationMessage,
                    icon: isWarning ? "exclamationmark.triangle.fill" : "xmark.circle.fill",
                    iconColor: isWarning ? .orange : .red,
                    isPresented: $showVerificationSheet,
                    primaryAction: {
                        if shouldUnlockAfterAlert {
                            shouldUnlockAfterAlert = false
                            onCompleted()
                            dismiss()
                        }
                    },
                    primaryActionTitle: NSLocalizedString("common.ok", comment: "OK")
                )
            }
        }
        .fullScreenCover(isPresented: $showForceAppSelection) {
            ForceAppSelectionView(shieldManager: shieldManager) {
                showForceAppSelection = false
                verificationMessage = NSLocalizedString("practice.premium_welcome", comment: "")
                showVerificationSheet = true
            }
        }
        .onAppear {
            PostHogManager.shared.screen(AnalyticsScreen.goodDeeds)
            if selectedGoodDeedTask == nil {
                selectedGoodDeedTask = GoodDeedTaskManager.shared.selectTask()
            }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true).delay(0.5)) { breathe = true }
        }
    }

    private var sessionTopBar: some View {
        HStack(spacing: 10) {
            SDBrandMark(iconSize: 22, textSize: 22)

            Spacer(minLength: 8)

            Button {
                HapticManager.shared.soft()
                detector.stop()
                if showDeedCompletion, let task = selectedGoodDeedTask {
                    finishDeed(task, minutes: task.unlockMinutes)
                } else if showDhikrCompletion {
                    showDhikrCompletion = false
                    onCompleted()
                    dismiss()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.muted)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Step 3 (dhikr style): Dhikr Screen

    private func dhikrScreen(geo: GeometryProxy) -> some View {
        // Match good-deed task button layout so all tap buttons share one consistent position near the bottom
        let btnSize: CGFloat = min(geo.size.width * 0.38, 150)
        let safeBottom: CGFloat = max(geo.safeAreaInsets.bottom, 24)
        let gradientHeight: CGFloat = 120
        let minGapAboveButton: CGFloat = 72
        let btnAreaContent: CGFloat = btnSize + 22 + 18 + 24 + safeBottom + 16
        let buttonZoneHeight: CGFloat = gradientHeight + btnAreaContent + minGapAboveButton

        return ZStack(alignment: .bottom) {
            // ── Scrollable content ──────────────────────────────
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 22)

                    // Hero: Arabic first, then transcription
                    VStack(spacing: 18) {

                        // Arabic ↔ Translation (cross-fade) — shown first
                        ZStack {
                            // Arabic
                            Group {
                                if selectedDhikr == .salawat {
                                    Text(DhikrType.salawatArabicFull)
                                        .font(.system(size: 22, weight: .medium))
                                        .lineSpacing(8)
                                } else {
                                    Text(selectedDhikr.arabic)
                                        .font(.system(size: 52, weight: .semibold))
                                        .lineSpacing(6)
                                        .minimumScaleFactor(0.65)
                                }
                            }
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .environment(\.layoutDirection, .rightToLeft)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                            .opacity(showTranslation ? 0 : 1)
                            .scaleEffect(showTranslation ? 0.94 : 1)

                            // Translation
                            Text(selectedDhikr == .salawat
                                 ? NSLocalizedString("dhikr.salawat.translation_full", comment: "")
                                 : selectedDhikr.fullTranslation)
                                .font(.system(size: selectedDhikr == .salawat ? 16 : 22, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .opacity(showTranslation ? 1 : 0)
                                .scaleEffect(showTranslation ? 1 : 0.94)
                        }
                        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: showTranslation)

                        // Translate toggle — directly under Arabic
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

                        // Instruction + transliteration: zelfde font en grootte, transliteratie op nieuwe regel
                        VStack(spacing: 6) {
                            Text(requiredTaps == 1
                                 ? NSLocalizedString("practice.recite_once", comment: "")
                                 : requiredTaps == 3
                                 ? NSLocalizedString("practice.recite_three_times", comment: "")
                                 : String(format: NSLocalizedString("practice.recite_n_times", comment: ""), requiredTaps))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.primary.opacity(0.95))
                                .multilineTextAlignment(.center)
                            Text(selectedDhikr.rawValue)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.primary.opacity(0.95))
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.85)
                        }

                        // Unlock duration pill
                        if let task = selectedGoodDeedTask {
                            DeedCoinBadge(coins: task.coins, size: 12)
                            .foregroundColor(task.difficulty.accentColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(task.difficulty.accentColor.opacity(0.11))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(task.difficulty.accentColor.opacity(0.22), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 32)
                    .opacity(dhikrAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4), value: dhikrAppeared)

                    // Bottom padding so content never hides behind button
                    Color.clear.frame(height: buttonZoneHeight)
                }
            }

            // No background layer — fully transparent, no zwarte kader
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Color.clear
                    .frame(height: buttonZoneHeight)
            }
            .allowsHitTesting(false)

            // Tap area — top padding so 3 dots never overlap content above
            VStack(spacing: 22) {
                // Progress indicator: 3 dots for short dhikr, arc + counter for extended
                if !webhookService.isVerifying {
                    if requiredTaps <= 3 {
                        HStack(spacing: 14) {
                            ForEach(0 ..< requiredTaps, id: \.self) { i in
                                Circle()
                                    .fill(i < dhikrTapCount ? AppTheme.primary : AppTheme.textMuted.opacity(0.2))
                                    .frame(width: 11, height: 11)
                                    .shadow(color: i < dhikrTapCount ? AppTheme.primary.opacity(0.55) : .clear, radius: 6)
                                    .scaleEffect(i < dhikrTapCount ? 1.35 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: dhikrTapCount)
                            }
                        }
                    } else {
                        // Compact counter pill for extended counts (33×, etc.)
                        HStack(spacing: 6) {
                            Text("\(dhikrTapCount)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.primary)
                                .contentTransition(.numericText())
                                .frame(minWidth: 36, alignment: .trailing)
                            Text("/\(requiredTaps)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(AppTheme.primary.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.primary.opacity(0.15), lineWidth: 1))
                        .animation(.easeInOut(duration: 0.15), value: dhikrTapCount)
                    }
                }

                ZStack {
                    if webhookService.isVerifying {
                        Circle()
                            .fill(AppTheme.gradientPrimary)
                            .frame(width: btnSize, height: btnSize)
                            .shadow(color: AppTheme.primary.opacity(0.55), radius: 28, y: 10)
                            .scaleEffect(verifyGlow ? 1.07 : 1.0)
                            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: verifyGlow)
                            .onAppear { verifyGlow = true }

                        Circle()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1.5)
                            .frame(width: btnSize, height: btnSize)

                        SwiftUI.ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                    } else {
                        // Outer breathing ring
                        Circle()
                            .stroke(AppTheme.primary.opacity(breathe ? 0.14 : 0.06), lineWidth: 2)
                            .frame(width: btnSize + 22, height: btnSize + 22)

                        // Progress arc for extended tap counts
                        if requiredTaps > 3 && dhikrTapCount > 0 {
                            Circle()
                                .trim(from: 0, to: CGFloat(dhikrTapCount) / CGFloat(requiredTaps))
                                .stroke(AppTheme.primary.opacity(0.75), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: btnSize + 22, height: btnSize + 22)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.28, dampingFraction: 0.72), value: dhikrTapCount)
                        }

                        Circle()
                            .stroke(AppTheme.primary.opacity(ripple1Opacity), lineWidth: 2)
                            .frame(width: btnSize, height: btnSize)
                            .scaleEffect(ripple1Scale)
                            .allowsHitTesting(false)

                        Circle()
                            .stroke(AppTheme.primary.opacity(ripple2Opacity), lineWidth: 1.5)
                            .frame(width: btnSize, height: btnSize)
                            .scaleEffect(ripple2Scale)
                            .allowsHitTesting(false)

                        Button(action: handleMicTap) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.gradientPrimary)
                                    .frame(width: btnSize, height: btnSize)
                                    .shadow(color: AppTheme.primary.opacity(0.42), radius: 24, y: 10)
                                    .scaleEffect(breathe ? 1.025 : 1.0)

                                Circle()
                                    .strokeBorder(.white.opacity(0.22), lineWidth: 1.5)
                                    .frame(width: btnSize, height: btnSize)

                                if dhikrTapCount > 0 && dhikrTapCount < requiredTaps {
                                    Text("\(dhikrTapCount)")
                                        .font(.system(size: btnSize * 0.38, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .contentTransition(.numericText())
                                } else {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: btnSize * 0.34, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(dhikrTapCount > 0 ? 1.04 : 1.0)
                        .animation(.spring(response: 0.24, dampingFraction: 0.55), value: dhikrTapCount)
                    }
                }
                .frame(width: btnSize + 26, height: btnSize + 26)

                // Only static instruction below button (no running count — count is in pill above and in button)
                Group {
                    if webhookService.isVerifying {
                        Text(NSLocalizedString("practice.verifying", comment: ""))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    } else if dhikrTapCount < requiredTaps {
                        if requiredTaps == 1 {
                            Text(NSLocalizedString("practice.tap_once", comment: ""))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        } else if requiredTaps <= 3 {
                            Text(NSLocalizedString("practice.tap_three_times", comment: ""))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        } else {
                            Text(String(format: NSLocalizedString("practice.tap_n_times", comment: ""), requiredTaps))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 24)
                .animation(.easeInOut(duration: 0.2), value: dhikrTapCount)
            }
            .padding(.top, gradientHeight)
            .opacity(dhikrAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.35).delay(0.1), value: dhikrAppeared)
            .padding(.bottom, safeBottom + 16)
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.38)) { dhikrAppeared = true }
        }
    }

    // MARK: - Dhikr tap logic

    private func handleMicTap() {
        guard !webhookService.isVerifying else { return }
        withAnimation(.spring(response: 0.24, dampingFraction: 0.55)) { dhikrTapCount += 1 }
        triggerRipple()
        if dhikrTapCount >= requiredTaps {
            // Final tap — verified sequence
            HapticManager.shared.dhikrVerified()
            webhookService.isVerifying = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                webhookService.isVerifying = false
                verifyGlow = false
                handleVerificationResult(.approved)
            }
        } else {
            // Progressive build-up per tap
            HapticManager.shared.dhikrTap(count: dhikrTapCount, required: requiredTaps)
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

    // MARK: - Full-screen completion overlay

    private func completionScrim<Card: View>(@ViewBuilder card: () -> Card) -> some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { }
            card()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .transition(.opacity)
    }

    private func completionCard(
        subtitle: String,
        coins: Int,
        typedText: String? = nil,
        appeared: Bool,
        onContinue: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
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

            Text(NSLocalizedString("task.confirmation.title", comment: ""))
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
                .padding(.top, 4)
                .padding(.bottom, typedText == nil ? 24 : 16)

            if let typedText, !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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

            Rectangle()
                .fill(AppTheme.textMuted.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 28)

            DeedCoinBadge(coins: coins, size: 17)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.vertical, 20)

            Rectangle()
                .fill(AppTheme.textMuted.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 28)

            Text(NSLocalizedString("task.confirmation.message", comment: ""))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 28)
                .padding(.vertical, 20)

            Button(action: onContinue) {
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
        .scaleEffect(appeared ? 1 : 0.88)
        .opacity(appeared ? 1 : 0)
    }

    private var dhikrCompletionOverlay: some View {
        completionScrim {
            completionCard(
                subtitle: selectedDhikr.rawValue,
                coins: unlockedCoins,
                appeared: dhikrCompletionAppeared
            ) {
                showDhikrCompletion = false
                dhikrCompletionAppeared = false
                if shouldUnlockAfterAlert {
                    shouldUnlockAfterAlert = false
                    onCompleted()
                    dismiss()
                }
            }
        }
        .onAppear {
            HapticManager.shared.completionShown()
            HapticManager.shared.success()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                dhikrCompletionAppeared = true
            }
        }
    }

    private func deedCompletionOverlay(task: GoodDeedTask) -> some View {
        completionScrim {
            completionCard(
                subtitle: NSLocalizedString("task.\(task.id).title", value: task.title, comment: ""),
                coins: task.coins,
                typedText: task.requiresInput ? deedCompletionTypedText : nil,
                appeared: deedCompletionAppeared
            ) {
                finishDeed(task, minutes: task.unlockMinutes)
            }
        }
        .onAppear {
            HapticManager.shared.completionShown()
            HapticManager.shared.success()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                deedCompletionAppeared = true
            }
        }
    }

    private func finishDeed(_ task: GoodDeedTask, minutes _: Int) {
        HeartJourneyManager.shared.stageDeedCoins(task.coins)
        webhookService.trackDhikrCompletion(dhikrType: task.title)
        PostHogManager.shared.trackGoodDeedCompleted(
            task: task,
            totalSessions: userDataManager.totalSessions + 1
        )
        showDeedCompletion = false
        deedCompletionAppeared = false
        onCompleted()
        dismiss()
    }

    // MARK: - Verification result

    private func handleVerificationResult(_ result: VerificationResult) {
        switch result {
        case .approved:
            HapticManager.shared.dhikrVerified()
            webhookService.trackDhikrCompletion(dhikrType: selectedDhikr.rawValue)
            hasCompletedFirstDhikr = true
            if let task = selectedGoodDeedTask {
                PostHogManager.shared.trackGoodDeedCompleted(
                    task: task,
                    totalSessions: userDataManager.totalSessions + 1
                )
            }

            UserDefaults.standard.set(activeUnlockMinutes, forKey: UserDataManager.pendingUnlockMinutesKey)
            let reward = selectedGoodDeedTask?.coins ?? HeartJourneyManager.deedXP
            unlockedCoins = reward
            HeartJourneyManager.shared.stageDeedCoins(reward)
            shouldUnlockAfterAlert = true
            withAnimation { showDhikrCompletion = true }

        case .rejected(let reason):
            if !hasGrantedGraceUnlock {
                hasGrantedGraceUnlock = true
                HapticManager.shared.dhikrVerified()
                HeartJourneyManager.shared.stageDeedCoins(selectedGoodDeedTask?.coins ?? HeartJourneyManager.deedXP)
                verificationMessage = String(format: NSLocalizedString("practice.grace_unlock", comment: ""), reason)
                shouldUnlockAfterAlert = true
            } else {
                HapticManager.shared.error()
                verificationMessage = String(format: NSLocalizedString("practice.rejected", comment: ""), reason)
            }
            showVerificationSheet = true
            audioRecorder.deleteRecording()

        case .error(let error):
            if !hasGrantedGraceUnlock {
                hasGrantedGraceUnlock = true
                HapticManager.shared.dhikrVerified()
                HeartJourneyManager.shared.stageDeedCoins(selectedGoodDeedTask?.coins ?? HeartJourneyManager.deedXP)
                verificationMessage = String(format: NSLocalizedString("practice.error_grace", comment: ""), error)
                shouldUnlockAfterAlert = true
            } else {
                HapticManager.shared.error()
                verificationMessage = String(format: NSLocalizedString("practice.error_connection", comment: ""), error)
            }
            showVerificationSheet = true
            audioRecorder.deleteRecording()
        }
    }
}

#Preview {
    PracticeSessionView(detector: RecitationDetector(), onCompleted: {})
}
