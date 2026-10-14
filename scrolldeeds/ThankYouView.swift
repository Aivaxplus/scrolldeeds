//
//  ThankYouView.swift
//  scrolldeeds
//
//  Thank you page after successful subscription — premium gold style (matches paywall / onboarding).
//

import SwiftUI

struct ThankYouView: View {
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showButton = false
    @State private var softPulse = false
    @State private var confettiOpacity: Double = 0

    var body: some View {
        ZStack {
            SDPageBackground()

            RadialGradient(
                colors: [AppTheme.primary.opacity(0.08), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    AppTheme.primary.opacity(0.08),
                    AppTheme.primary.opacity(0.06),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 40,
                endRadius: 380
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [AppTheme.primary.opacity(0.08), Color.clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()

            ThankYouStarfield()
            ThankYouConfettiLayer(opacity: confettiOpacity)

            VStack(spacing: 0) {
                Spacer(minLength: 12)

                // Success mark — solid gold + soft rings (like reference)
                ZStack {
                    ForEach(0..<2, id: \.self) { i in
                        Circle()
                            .stroke(
                                AppTheme.primary.opacity(0.22 - Double(i) * 0.08),
                                lineWidth: 1
                            )
                            .frame(width: 132 + CGFloat(i * 18), height: 132 + CGFloat(i * 18))
                            .scaleEffect(softPulse ? 1.02 : 1.0)
                            .animation(
                                .easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                                value: softPulse
                            )
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.86, blue: 0.48),
                                    Color(red: 0.93, green: 0.76, blue: 0.36),
                                    Color(red: 0.88, green: 0.68, blue: 0.30)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.35), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: AppTheme.primary.opacity(0.45), radius: 20, y: 8)

                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.85)

                Spacer().frame(height: 28)

                VStack(spacing: 14) {
                    Text(NSLocalizedString("thankyou.title", comment: ""))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                        .lineLimit(2)

                    Text(NSLocalizedString("thankyou.subtitle", comment: ""))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.primary)

                    Text(NSLocalizedString("thankyou.message", comment: ""))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 28)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 12)

                Spacer(minLength: 20)

                VStack(spacing: 14) {
                    ThankYouBenefitRow(
                        icon: "lock.open.fill",
                        text: NSLocalizedString("thankyou.benefit1", comment: "")
                    )
                    ThankYouBenefitRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: NSLocalizedString("thankyou.benefit2", comment: "")
                    )
                    ThankYouBenefitRow(
                        icon: "bell.badge.fill",
                        text: NSLocalizedString("thankyou.benefit3", comment: "")
                    )
                    ThankYouBenefitRow(
                        icon: "infinity",
                        text: NSLocalizedString("thankyou.benefit4", comment: "")
                    )
                }
                .padding(22)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AppTheme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.primary.opacity(0.55),
                                            AppTheme.primary.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)

                Spacer(minLength: 16)

                Button(action: {
                    HapticManager.shared.success()
                    onContinue()
                }) {
                    HStack(spacing: 10) {
                        Text(NSLocalizedString("thankyou.cta", comment: ""))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 12)

                Spacer(minLength: 12)
                Spacer().frame(height: 8)
            }
        }
        .onAppear {
            PostHogManager.shared.screen(AnalyticsScreen.thankYou)
            PostHogManager.shared.trackThankYouViewed()
            softPulse = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.15)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.65)) {
                showButton = true
            }
            withAnimation(.easeOut(duration: 0.55).delay(0.22)) {
                confettiOpacity = 1
            }
            HapticManager.shared.success()
        }
    }
}

// MARK: - Confetti (restored; uses container size — not UIScreen)

private struct ThankYouConfettiLayer: View {
    var opacity: Double
    private static let count = 22

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<Self.count, id: \.self) { i in
                    ThankYouConfettiPiece(index: i, size: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .opacity(opacity)
    }
}

private struct ThankYouConfettiPiece: View {
    let index: Int
    let size: CGSize

    @State private var falling = false

    private let palette: [Color] = [
        AppTheme.primary,
        AppTheme.primaryLight,
        AppTheme.primary,
        Color.white.opacity(0.92)
    ]

    private var pieceX: CGFloat {
        let u = CGFloat((index * 1103515245 &+ 12345) % 10000) / 10000
        return 24 + u * max(40, size.width - 48)
    }

    private var pieceSize: CGFloat {
        6 + CGFloat((index * 13) % 7)
    }

    private var duration: Double {
        2.4 + Double(index % 6) * 0.28
    }

    private var startDelay: Double {
        Double(index) * 0.09
    }

    var body: some View {
        Circle()
            .fill(palette[index % palette.count])
            .frame(width: pieceSize, height: pieceSize)
            .position(
                x: pieceX,
                y: falling ? size.height + 50 : -45
            )
            .opacity(falling ? 0 : 1)
            .animation(
                .easeIn(duration: duration)
                    .delay(startDelay)
                    .repeatForever(autoreverses: false),
                value: falling
            )
            .onAppear {
                falling = true
            }
    }
}

// MARK: - Starfield (subtle static specks)

private struct ThankYouStarfield: View {
    private let seeds: [CGFloat] = [0.12, 0.28, 0.44, 0.61, 0.78, 0.09, 0.52, 0.67, 0.33, 0.91, 0.22, 0.85, 0.15, 0.73, 0.38]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(seeds.enumerated()), id: \.offset) { i, sx in
                    let sy = seeds[(i + 5) % seeds.count]
                    Circle()
                        .fill(i % 3 == 0 ? AppTheme.primary.opacity(0.35) : AppTheme.primary.opacity(0.25))
                        .frame(width: i % 4 == 0 ? 3 : 2, height: i % 4 == 0 ? 3 : 2)
                        .position(x: sx * geo.size.width, y: sy * geo.size.height)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Benefit row (green icon accents, gold check pill)

private struct ThankYouBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.primary.opacity(0.45), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
            }

            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.86, blue: 0.48),
                                Color(red: 0.90, green: 0.72, blue: 0.32)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    ThankYouView(onContinue: {})
}
