//
//  OnboardingHeroIllustration.swift
//  scrolldeeds
//
//  Compact storybook illustration for onboarding question pages.
//

import SwiftUI

struct OnboardingHeroIllustration: View {
    let imageName: String
    var revealed: Bool
    var compact: Bool = false

    @State private var isFloating = false
    @State private var glowPulse = false

    /// Upper bound only — the card always shrinks to the width its parent offers.
    private var maxCardWidth: CGFloat { compact ? 312 : 360 }
    private var aspectRatio: CGFloat { compact ? 312.0 / 168.0 : 360.0 / 210.0 }

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .frame(maxWidth: maxCardWidth)
            .overlay(
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                AppTheme.primary.opacity(0.35),
                                Color.black.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primary.opacity(glowPulse ? 0.22 : 0.10),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 90
                        )
                    )
                    .padding(-14)
                    .blur(radius: 10)
            )
            .shadow(color: Color.black.opacity(0.22), radius: 12, y: 8)
            .offset(y: isFloating ? -4 : 2)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .scaleEffect(revealed ? 1 : 0.86)
            .opacity(revealed ? 1 : 0)
            .rotation3DEffect(
                .degrees(revealed ? 0 : 12),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.7
            )
            .animation(.spring(response: 0.58, dampingFraction: 0.78), value: revealed)
            .animation(
                revealed ? .easeInOut(duration: 2.4).repeatForever(autoreverses: true) : .default,
                value: isFloating
            )
            .animation(
                revealed ? .easeInOut(duration: 2.8).repeatForever(autoreverses: true) : .default,
                value: glowPulse
            )
            .onAppear { updateMotion() }
            .onChange(of: revealed) { _ in updateMotion() }
    }

    private func updateMotion() {
        guard revealed else {
            isFloating = false
            glowPulse = false
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard revealed else { return }
            isFloating = true
            glowPulse = true
        }
    }
}
