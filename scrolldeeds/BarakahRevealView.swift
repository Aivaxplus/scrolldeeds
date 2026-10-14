//
//  BarakahRevealView.swift
//  scrolldeeds
//
//  Magical sealed-card moment after a good deed: light, Arabic, meaning, level minutes.
//

import SwiftUI

struct BarakahRevealView: View {
    let result: DeedAscentResult
    let onAmin: () -> Void

    @State private var glow = 0.12
    @State private var sealScale: CGFloat = 0.28
    @State private var sealOpacity: Double = 1
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0
    @State private var arabicVisible = false
    @State private var meaningVisible = false
    @State private var metaVisible = false
    @State private var aminVisible = false

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.08, blue: 0.06)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    AppTheme.primary.opacity(glow),
                    AppTheme.accent.opacity(glow * 0.35),
                    Color.clear
                ],
                center: .center,
                startRadius: 12,
                endRadius: 340
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            Circle()
                .stroke(AppTheme.primaryLight.opacity(ringOpacity * 0.7), lineWidth: 1.5)
                .frame(width: 160, height: 160)
                .scaleEffect(ringScale)
                .allowsHitTesting(false)

            if sealOpacity > 0.02 {
                seal
                    .scaleEffect(sealScale)
                    .opacity(sealOpacity)
            }

            VStack(spacing: 0) {
                Spacer()

                Text(result.card.arabic)
                    .font(.system(size: result.card.arabic.count > 28 ? 28 : 36, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 32)
                    .environment(\.layoutDirection, .rightToLeft)
                    .opacity(arabicVisible ? 1 : 0)
                    .offset(y: arabicVisible ? 0 : 12)

                Text(NSLocalizedString(result.card.meaningKey, comment: ""))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.86))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 36)
                    .padding(.top, 18)
                    .opacity(meaningVisible ? 1 : 0)
                    .offset(y: meaningVisible ? 0 : 8)

                Text(
                    String(
                        format: NSLocalizedString("barakah.level_minutes", comment: "Level %d · +%d min"),
                        result.level,
                        result.minutes
                    )
                )
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.accentLight)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
                .padding(.top, 22)
                .opacity(metaVisible ? 1 : 0)

                Spacer()

                Button(action: {
                    HapticManager.shared.medium()
                    onAmin()
                }) {
                    Text(NSLocalizedString("barakah.amin", comment: "Amin"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                }
                .buttonStyle(PrimaryButtonStyle(stylesLabel: false))
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
                .opacity(aminVisible ? 1 : 0)
                .offset(y: aminVisible ? 0 : 10)
            }
        }
        .onAppear { play() }
    }

    private var seal: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.accentLight.opacity(0.95),
                            AppTheme.primary,
                            AppTheme.primaryDark
                        ],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 70
                    )
                )
                .frame(width: 92, height: 92)
                .shadow(color: AppTheme.primary.opacity(0.7), radius: 28, y: 4)

            Circle()
                .stroke(Color.white.opacity(0.45), lineWidth: 1.2)
                .frame(width: 92, height: 92)

            Image(systemName: "sparkle")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private func play() {
        HapticManager.shared.soft()
        withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
            sealScale = 1
            glow = 0.42
        }
        withAnimation(.easeOut(duration: 0.9)) {
            ringOpacity = 0.9
            ringScale = 1.15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            HapticManager.shared.heavy()
            withAnimation(.easeOut(duration: 0.45)) {
                sealScale = 1.55
                sealOpacity = 0
                ringOpacity = 0
                glow = 0.55
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            HapticManager.shared.soft()
            withAnimation(.easeOut(duration: 0.7)) {
                arabicVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
            withAnimation(.easeOut(duration: 0.65)) {
                meaningVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                metaVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.85) {
            withAnimation(.easeOut(duration: 0.4)) {
                aminVisible = true
            }
        }
    }
}
