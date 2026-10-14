//
//  CommitmentView.swift
//  scrolldeeds
//
//  Redesigned to match onboarding: warm gold, subtle motion, circular progress ring.
//

import SwiftUI
import UIKit

struct CommitmentView: View {
    let userName: String?
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isPressing = false
    @State private var hasCompleted = false
    @State private var completionWorkItem: DispatchWorkItem?
    @State private var hapticTimer: Timer?
    @State private var appeared = false
    @State private var breath: Bool = false

    private let holdDuration: TimeInterval = 3.0
    private let hapticInitialInterval: TimeInterval = 0.32
    private let hapticMinInterval: TimeInterval = 0.06

    private static let pageBg = AppTheme.background

    private var displayName: String {
        let name = userName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let n = name, !n.isEmpty { return n }
        return NSLocalizedString("commitment.fallback_name", comment: "there")
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Same warm canvas as the rest of onboarding.
                SDPageBackground()

                RadialGradient(
                    colors: [
                        AppTheme.primary.opacity(0.08),
                        AppTheme.accent.opacity(0.05),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 420
                )
                .ignoresSafeArea()

                // Zachte gloed achter de button (groeit met progress)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primary.opacity(0.25 * progress),
                                AppTheme.primary.opacity(0.08 * progress),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 20)
                    .offset(y: 20)

                VStack(spacing: 0) {
                    Spacer(minLength: 20)

                    VStack(spacing: 18) {
                        ZStack {
                            SDIconBadge(systemName: "hand.raised.fill", size: 58, iconSize: 26)

                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.05), value: appeared)

                        Text(String(format: NSLocalizedString("commitment.title", comment: "Will you stick with our system, %@?"), displayName))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .lineLimit(4)
                            .minimumScaleFactor(0.82)
                            .padding(.horizontal, 28)
                            .frame(maxWidth: .infinity)
                            .shadow(color: Color.clear, radius: 0, y: 0)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 14)
                            .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.12), value: appeared)

                        Text(NSLocalizedString("commitment.instruction", comment: "Hold your finger on the button to confirm"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.primary.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 36)
                            .frame(maxWidth: .infinity)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.22), value: appeared)
                    }

                    Spacer(minLength: 28)

                    commitmentButtonWithRing(geometry: geometry)

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, geometry.safeAreaInsets.top)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            prepareHaptics()
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.3)) { breath = true }
        }
        .onDisappear {
            hapticTimer?.invalidate()
            hapticTimer = nil
            completionWorkItem?.cancel()
            completionWorkItem = nil
        }
    }

    private func commitmentButtonWithRing(geometry: GeometryProxy) -> some View {
        let size: CGFloat = 96
        let ringWidth: CGFloat = 4
        let bottomPadding = geometry.safeAreaInsets.bottom + 32

        return ZStack {
            // Buitenste progress-ring (groen, vult bij hold)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: size + ringWidth * 2 + 12, height: size + ringWidth * 2 + 12)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.22), value: progress)

            // Rustige ring (subtiel zichtbaar als niet aan het vullen)
            Circle()
                .stroke(AppTheme.primary.opacity(0.35), lineWidth: ringWidth)
                .frame(width: size + 12, height: size + 12)

            // Button — groene gradient (zelfde groen als onboarding)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: AppTheme.primary.opacity(0.4), radius: 16, y: 6)
                .scaleEffect((breath ? 1.03 : 1.0) * (isPressing ? 0.96 : 1.0))
                .animation(.easeInOut(duration: 0.2), value: isPressing)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: breath)

            Image(systemName: "touchid")
                .font(.system(size: 44))
                .foregroundColor(.white)
        }
        .frame(width: size + 40, height: size + 40)
        .padding(.bottom, bottomPadding)
        .onLongPressGesture(minimumDuration: holdDuration, pressing: { pressing in
            if pressing {
                if !isPressing && !hasCompleted { startHold() }
            } else {
                if isPressing && !hasCompleted { cancelHold() }
            }
        }, perform: {
            if !hasCompleted { completeCommitment() }
        })
    }

    private func prepareHaptics() {
        let light = UIImpactFeedbackGenerator(style: .light)
        let medium = UIImpactFeedbackGenerator(style: .medium)
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        let notif = UINotificationFeedbackGenerator()
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notif.prepare()
    }

    private func startHold() {
        guard !isPressing, !hasCompleted else { return }
        isPressing = true
        progress = 0

        let light = UIImpactFeedbackGenerator(style: .light)
        let notif = UINotificationFeedbackGenerator()
        light.prepare()
        notif.prepare()
        light.impactOccurred(intensity: 0.7)

        withAnimation(.easeInOut(duration: holdDuration)) {
            progress = 1
        }

        var hapticCount = 0
        hapticTimer?.invalidate()
        func scheduleNextHaptic() {
            guard isPressing, !hasCompleted else { return }
            hapticCount += 1
            let progressFraction = Double(hapticCount) * 0.04
            let intensity = min(1.0, 0.5 + progressFraction)
            let style: UIImpactFeedbackGenerator.FeedbackStyle = intensity < 0.6 ? .light : (intensity < 0.85 ? .medium : .heavy)
            let gen = UIImpactFeedbackGenerator(style: style)
            gen.prepare()
            gen.impactOccurred(intensity: CGFloat(intensity))
            let nextInterval = max(hapticMinInterval, hapticInitialInterval - TimeInterval(hapticCount) * 0.028)
            hapticTimer = Timer.scheduledTimer(withTimeInterval: nextInterval, repeats: false) { _ in
                DispatchQueue.main.async { scheduleNextHaptic() }
            }
            RunLoop.main.add(hapticTimer!, forMode: .common)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + hapticInitialInterval * 0.5) {
            scheduleNextHaptic()
        }

        completionWorkItem?.cancel()
        let complete = DispatchWorkItem { [self] in
            guard isPressing, !hasCompleted else { return }
            completeCommitment()
        }
        completionWorkItem = complete
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration, execute: complete)
    }

    private func cancelHold() {
        isPressing = false
        completionWorkItem?.cancel()
        completionWorkItem = nil
        hapticTimer?.invalidate()
        hapticTimer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            progress = 0
        }
        let gen = UIImpactFeedbackGenerator(style: .soft)
        gen.prepare()
        gen.impactOccurred(intensity: 0.4)
    }

    private func completeCommitment() {
        guard !hasCompleted else { return }
        hasCompleted = true
        completionWorkItem?.cancel()
        hapticTimer?.invalidate()
        hapticTimer = nil
        isPressing = false

        let notif = UINotificationFeedbackGenerator()
        notif.prepare()
        notif.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.prepare()
            heavy.impactOccurred(intensity: 0.8)
        }

        withAnimation(.easeOut(duration: 0.25)) {
            progress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete()
        }
    }
}

// MARK: - Life change beat (after hold commitment)

struct OnboardingLifeChangeView: View {
    let userName: String?
    let onFinished: () -> Void

    /// Total time on screen before advancing (text reveal + hold).
    private var autoAdvanceAfterSeconds: Double { OnboardingFunnelConfig.lifeChangeAutoAdvanceSeconds }
    private var delayPerLine: Double { OnboardingFunnelConfig.showcaseDelayPerElement }
    private var fadeDuration: Double { OnboardingFunnelConfig.showcaseFadeDuration }
    private let revealOffset: CGFloat = 3

    @State private var lineVisible: [Int: Bool] = [:]
    @State private var advanceWorkItem: DispatchWorkItem?

    private var displayName: String {
        let trimmed = userName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty { return trimmed }
        return NSLocalizedString("questionnaire.consider_this.fallback_name", comment: "there")
    }

    private var lines: [(text: String, highlight: String)] {
        let greeting = String(
            format: NSLocalizedString("questionnaire.life_change.name_greeting", comment: "%@,"),
            displayName
        )
        return [
            (greeting, displayName),
            (
                NSLocalizedString("questionnaire.life_change.line1", comment: ""),
                NSLocalizedString("questionnaire.life_change.highlight.change", comment: "")
            ),
            (
                NSLocalizedString("questionnaire.life_change.line2", comment: ""),
                NSLocalizedString("questionnaire.life_change.highlight.serious", comment: "")
            )
        ]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SDPageBackground()

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primary.opacity(0.10),
                                AppTheme.primary.opacity(0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: 36)
                    .offset(y: -geometry.size.height * 0.08)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: max(48, geometry.safeAreaInsets.top + 28))

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                            highlightedLine(text: line.text, highlight: line.highlight)
                                .opacity(lineVisible[index] == true ? 1 : 0)
                                .offset(y: lineVisible[index] == true ? 0 : revealOffset)
                        }
                    }
                    .padding(.horizontal, max(24, geometry.size.width * 0.07))
                    .frame(maxWidth: 340, alignment: .leading)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { start() }
        .onDisappear {
            advanceWorkItem?.cancel()
            advanceWorkItem = nil
        }
    }

    private func highlightedLine(text: String, highlight: String) -> some View {
        Group {
            if !highlight.isEmpty, text.contains(highlight), let range = text.range(of: highlight) {
                let before = String(text[..<range.lowerBound])
                let after = String(text[range.upperBound...])
                (Text(before)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                + Text(highlight)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                + Text(after)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary))
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(text)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func start() {
        for index in lines.indices {
            let delay = delayPerLine * Double(index)
            withAnimation(.easeInOut(duration: fadeDuration).delay(delay)) {
                lineVisible[index] = true
            }
            HapticManager.shared.scheduleAnimationReveal(after: delay, beat: index)
        }

        let work = DispatchWorkItem {
            // Soft fade-out before handing off to paywall loading
            withAnimation(.easeInOut(duration: 0.4)) {
                for index in self.lines.indices {
                    self.lineVisible[index] = false
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                self.onFinished()
            }
        }
        advanceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + autoAdvanceAfterSeconds, execute: work)
    }
}

#Preview("Commitment") {
    CommitmentView(userName: "Sa", onComplete: {})
}
