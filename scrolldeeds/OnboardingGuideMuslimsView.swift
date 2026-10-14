//
//  OnboardingGuideMuslimsView.swift
//  scrolldeeds
//
//  Just Pray–inspired “earn the reward” beat, ScrollDeeds chrome.
//  CTA framed as guiding other Muslims (in-app review popup on tap).
//

import SwiftUI
import StoreKit

struct OnboardingGuideMuslimsView: View {
    private var delayPerElement: Double { OnboardingFunnelConfig.narrativeDelayPerElement }
    private var fadeDuration: Double { OnboardingFunnelConfig.narrativeFadeDuration }
    private let revealOffset: CGFloat = 3

    @State private var headlineVisible = false
    @State private var heroVisible = false
    @State private var quoteLabelVisible = false
    @State private var quoteBodyVisible = false
    @State private var quoteSourceVisible = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: max(16, geometry.size.height * 0.03))

                        headlineBlock(fontSize: max(24, min(28, geometry.size.width * 0.065)))
                            .opacity(headlineVisible ? 1 : 0)
                            .offset(y: headlineVisible ? 0 : revealOffset)
                            .padding(.horizontal, max(20, geometry.size.width * 0.06))

                        Spacer().frame(height: max(28, geometry.size.height * 0.04))

                        OnboardingHeroEmojiIcon(
                            emoji: "🤝",
                            glowColor: AppTheme.primary,
                            emojiSize: 64,
                            revealed: heroVisible
                        )

                        Spacer().frame(height: max(28, geometry.size.height * 0.04))

                        quoteBlock(fontSize: max(18, min(22, geometry.size.width * 0.052)))
                            .padding(.horizontal, max(24, geometry.size.width * 0.08))

                        Spacer().frame(height: 32)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { startEntrance() }
    }

    // MARK: - Headline

    private func headlineBlock(fontSize: CGFloat) -> some View {
        let full = NSLocalizedString("onboarding.guide_muslims.headline", comment: "")
        let highlight = NSLocalizedString("onboarding.guide_muslims.headline_highlight", comment: "reward")

        return Group {
            if !highlight.isEmpty, full.contains(highlight), let range = full.range(of: highlight) {
                let before = String(full[..<range.lowerBound])
                let after = String(full[range.upperBound...])
                (Text(before)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                + Text(highlight)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                + Text(after)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            } else {
                Text(full)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quote

    private func quoteBlock(fontSize: CGFloat) -> some View {
        VStack(spacing: 14) {
            Text(NSLocalizedString("onboarding.guide_muslims.quote_label", comment: ""))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primary)
                .opacity(quoteLabelVisible ? 1 : 0)
                .offset(y: quoteLabelVisible ? 0 : revealOffset)

            Text(NSLocalizedString("onboarding.guide_muslims.quote", comment: ""))
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(quoteBodyVisible ? 1 : 0)
                .offset(y: quoteBodyVisible ? 0 : revealOffset)

            Text(NSLocalizedString("onboarding.guide_muslims.quote_source", comment: ""))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textMuted)
                .opacity(quoteSourceVisible ? 1 : 0)
                .offset(y: quoteSourceVisible ? 0 : revealOffset)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Entrance

    private func revealAnimation(delay: Double) -> Animation {
        .easeInOut(duration: fadeDuration).delay(delay)
    }

    private func startEntrance() {
        withAnimation(revealAnimation(delay: 0)) {
            headlineVisible = true
        }
        HapticManager.shared.animationReveal(beat: 0)
        withAnimation(revealAnimation(delay: delayPerElement * 0.6)) {
            heroVisible = true
        }
        HapticManager.shared.scheduleAnimationReveal(after: delayPerElement * 0.6, beat: 1)
        withAnimation(revealAnimation(delay: delayPerElement * 1.4)) {
            quoteLabelVisible = true
        }
        HapticManager.shared.scheduleAnimationReveal(after: delayPerElement * 1.4, beat: 2)
        withAnimation(revealAnimation(delay: delayPerElement * 2.2)) {
            quoteBodyVisible = true
        }
        HapticManager.shared.scheduleAnimationReveal(after: delayPerElement * 2.2, beat: 3)
        withAnimation(revealAnimation(delay: delayPerElement * 3.0)) {
            quoteSourceVisible = true
        }
        HapticManager.shared.scheduleAnimationReveal(after: delayPerElement * 3.0, beat: 4)
    }

    /// Shows Apple’s in-app star rating popup (does not leave ScrollDeeds).
    static func requestGuideReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }

        if #available(iOS 18.0, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Review popup (Cancel advances — Apple’s API has no cancel callback)

struct GuideMuslimsReviewPopup: View {
    @Binding var isPresented: Bool
    let onRate: () -> Void
    let onCancel: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss(then: onCancel)
                }

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "star.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(AppTheme.starYellow)
                }

                VStack(spacing: 10) {
                    Text(NSLocalizedString("onboarding.guide_muslims.popup.title", comment: ""))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(NSLocalizedString("onboarding.guide_muslims.popup.subtitle", comment: ""))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                VStack(spacing: 12) {
                    Button {
                        HapticManager.shared.medium()
                        dismiss(then: onRate)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(NSLocalizedString("onboarding.guide_muslims.popup.rate", comment: ""))
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(ActionCardButtonStyle())

                    Button {
                        HapticManager.shared.soft()
                        dismiss(then: onCancel)
                    } label: {
                        Text(NSLocalizedString("common.cancel", comment: "Cancel"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.card)
                    .shadow(color: Color.black.opacity(0.25), radius: 32, y: 16)
            )
            .padding(.horizontal, 28)
            .scaleEffect(appeared ? 1 : 0.92)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    private func dismiss(then action: @escaping () -> Void) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            appeared = false
            isPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            action()
        }
    }
}
