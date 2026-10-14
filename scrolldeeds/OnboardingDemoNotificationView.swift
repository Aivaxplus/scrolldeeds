//
//  OnboardingDemoNotificationView.swift
//  scrolldeeds
//
//  Just Pray–inspired beat, ScrollDeeds chrome:
//  iOS banner (above headline) → benefits-identical 2×3 icons → Dhikr press → demo.
//

import SwiftUI

struct OnboardingDemoNotificationView: View {
    let onFinished: () -> Void

    @State private var headlineVisible = false
    @State private var notificationOffset: CGFloat = -160
    @State private var notificationOpacity: Double = 0
    @State private var notificationScale: CGFloat = 0.92
    @State private var cardsVisible = false
    @State private var dhikrPressed = false
    @State private var dhikrSelected = false
    @State private var sceneOpacity: Double = 1
    @State private var hasFinished = false

    /// Same data as QuestionnaireView.prayerLockDeedCards
    private let cards: [(id: String, titleKey: String, icon: String)] = [
        ("dhikr", "benefits.card.dhikr", "waveform"),
        ("dua", "benefits.card.dua", "hands.sparkles.fill"),
        ("quran", "benefits.card.quran", "book.fill"),
        ("istighfar", "benefits.card.istighfar", "heart.fill"),
        ("sadaqah", "benefits.card.sadaqah", "gift.fill"),
        ("salawat", "benefits.card.salawat", "sparkles")
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
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

                VStack(spacing: 0) {
                    // 1) Notification ABOVE the headline
                    notificationBanner
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .offset(y: notificationOffset)
                        .scaleEffect(notificationScale, anchor: .top)
                        .opacity(notificationOpacity)

                    Spacer()
                        .frame(height: max(28, geometry.size.height * 0.045))

                    // 2) Headline under the banner
                    Text(NSLocalizedString("demo.notification.headline", comment: ""))
                        .font(.system(size: max(24, min(28, geometry.size.width * 0.065)), weight: .regular, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .opacity(headlineVisible ? 1 : 0)
                        .offset(y: headlineVisible ? 0 : 8)

                    // Same breathing room as benefits page before icons
                    Spacer()
                        .frame(height: max(56, geometry.size.height * 0.08))

                    // 3) Exact same 2×3 icon structure as benefits
                    benefitsStyleDeedGrid
                        .padding(.horizontal, max(20, geometry.size.width * 0.06))
                        .opacity(cardsVisible ? 1 : 0)
                        .offset(y: cardsVisible ? 0 : 10)

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .opacity(sceneOpacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { startSequence() }
        .onDisappear { hasFinished = true }
    }

    // MARK: - iOS-style notification banner

    private var notificationBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image("ScrollDeedsAppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text("NAFSI")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(0.4)

                Spacer(minLength: 8)

                Text(NSLocalizedString("demo.notification.now", comment: "now"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
            }

            Text(NSLocalizedString("demo.notification.title", comment: ""))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(2)

            Text(NSLocalizedString("demo.notification.body", comment: ""))
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AppTheme.card.opacity(0.72))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 24, y: 10)
                .shadow(color: Color.black.opacity(0.06), radius: 4, y: 1)
        )
    }

    // MARK: - Benefits-identical 2×3 grid (prayerLockDeedCardsGrid / prayerLockDeedCard)

    private var benefitsStyleDeedGrid: some View {
        VStack(spacing: 22) {
            HStack(spacing: 14) {
                ForEach(Array(cards.prefix(3)), id: \.id) { card in
                    benefitsStyleDeedCard(card)
                }
            }
            HStack(spacing: 14) {
                ForEach(Array(cards.suffix(3)), id: \.id) { card in
                    benefitsStyleDeedCard(card)
                }
            }
        }
    }

    private func benefitsStyleDeedCard(_ card: (id: String, titleKey: String, icon: String)) -> some View {
        let isDhikr = card.id == "dhikr"
        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(isDhikr && dhikrSelected ? 0.18 : 0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: card.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
            }
            Text(NSLocalizedString(card.titleKey, comment: ""))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(isDhikr && dhikrPressed ? 0.90 : 1.0)
        .animation(.spring(response: 0.26, dampingFraction: 0.72), value: dhikrPressed)
        .onTapGesture {
            guard isDhikr, !hasFinished else { return }
            runDhikrPressAndFinish(immediate: true)
        }
    }

    // MARK: - Sequence

    private func startSequence() {
        hasFinished = false
        headlineVisible = false
        notificationOffset = -160
        notificationOpacity = 0
        notificationScale = 0.92
        cardsVisible = false
        dhikrPressed = false
        dhikrSelected = false
        sceneOpacity = 1

        // Banner drops first (above headline)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            guard !hasFinished else { return }
            withAnimation(.spring(response: 0.72, dampingFraction: 0.82, blendDuration: 0)) {
                notificationOffset = 0
                notificationOpacity = 1
                notificationScale = 1
            }
            HapticManager.shared.soft()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.05) {
            guard !hasFinished else { return }
            withAnimation(.easeOut(duration: 0.70)) {
                headlineVisible = true
            }
            HapticManager.shared.animationReveal(beat: 1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.55) {
            guard !hasFinished else { return }
            withAnimation(.easeOut(duration: 0.75)) {
                cardsVisible = true
            }
            HapticManager.shared.animationReveal(beat: 2)
        }

        // Hold the scene long enough to read, then auto-press Dhikr
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.4) {
            guard !hasFinished else { return }
            runDhikrPressAndFinish(immediate: false)
        }
    }

    private func runDhikrPressAndFinish(immediate: Bool) {
        guard !hasFinished else { return }

        withAnimation(.easeOut(duration: 0.25)) {
            dhikrSelected = true
        }

        let pressDelay = immediate ? 0.05 : 0.38
        DispatchQueue.main.asyncAfter(deadline: .now() + pressDelay) {
            guard !hasFinished else { return }
            withAnimation(.easeInOut(duration: 0.14)) {
                dhikrPressed = true
            }
            HapticManager.shared.medium()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                guard !hasFinished else { return }
                withAnimation(.spring(response: 0.30, dampingFraction: 0.70)) {
                    dhikrPressed = false
                }
                HapticManager.shared.soft()

                // Pause on selected Dhikr before leaving
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                    guard !hasFinished else { return }
                    withAnimation(.spring(response: 0.58, dampingFraction: 0.9)) {
                        notificationOffset = -180
                        notificationOpacity = 0
                        notificationScale = 0.94
                    }
                    withAnimation(.easeInOut(duration: 0.55).delay(0.12)) {
                        cardsVisible = false
                        headlineVisible = false
                        sceneOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
                        finish()
                    }
                }
            }
        }
    }

    private func finish() {
        guard !hasFinished else { return }
        hasFinished = true
        onFinished()
    }
}
