//
//  PostSubscribeGuideMuslimsView.swift
//  scrolldeeds
//
//  “Earn the reward of guiding another Muslim” + review popup.
//  Shown after purchase → Thank You → lock apps, before difficulty.
//

import SwiftUI

struct PostSubscribeGuideMuslimsView: View {
    let onContinue: () -> Void

    @State private var ctaReady = false
    @State private var showReviewPopup = false
    @State private var didHandleReview = false

    var body: some View {
        ZStack {
            SDPageBackground()

            RadialGradient(
                colors: [AppTheme.primary.opacity(0.08), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingGuideMuslimsView()

                Button(action: handleCTA) {
                    Text(
                        didHandleReview
                            ? NSLocalizedString("questionnaire.continue", comment: "Continue")
                            : NSLocalizedString("onboarding.guide_muslims.cta", comment: "Guide other Muslims")
                    )
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 17)
                }
                .buttonStyle(ActionCardButtonStyle())
                .disabled(!ctaReady)
                .opacity(ctaReady ? 1 : 0)
                .allowsHitTesting(ctaReady)
                .animation(.easeIn(duration: 0.35), value: ctaReady)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }

            if showReviewPopup {
                GuideMuslimsReviewPopup(
                    isPresented: $showReviewPopup,
                    onRate: {
                        didHandleReview = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            OnboardingGuideMuslimsView.requestGuideReview()
                        }
                    },
                    onCancel: {
                        didHandleReview = true
                        onContinue()
                    }
                )
                .zIndex(1000)
            }
        }
        .onAppear {
            let delay = OnboardingFunnelConfig.narrativeDelayPerElement
            let fade = OnboardingFunnelConfig.narrativeFadeDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + delay * 3 + fade + 0.15) {
                ctaReady = true
            }
        }
    }

    private func handleCTA() {
        HapticManager.shared.medium()
        if didHandleReview {
            onContinue()
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            showReviewPopup = true
        }
    }
}
