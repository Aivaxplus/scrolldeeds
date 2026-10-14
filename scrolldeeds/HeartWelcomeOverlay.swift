import SwiftUI

struct HeartXPBarFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

private struct HeartXPChipFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// Welcome gift popup. The +XP chip flies into the heart XP bar, then the bar fills.
struct HeartWelcomeOverlay: View {
    let barGlobalFrame: CGRect

    @ObservedObject private var journey = HeartJourneyManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    @State private var appeared = false
    @State private var popupOpacity: Double = 1
    @State private var dimOpacity: Double = 0
    @State private var flying = false
    @State private var fly: CGFloat = 0
    @State private var chipOpacity: Double = 1
    @State private var chipScale: CGFloat = 1
    @State private var liveChipFrame: CGRect = .zero
    @State private var startChipFrame: CGRect = .zero

    private var bonus: Int { HeartJourneyManager.welcomeBonusXP }

    var body: some View {
        GeometryReader { proxy in
            let overlayOrigin = proxy.frame(in: .global).origin
            ZStack {
                Color.black.opacity(dimOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(!flying)

                if !flying {
                    popupCard
                        .scaleEffect(appeared ? 1 : 0.94)
                        .opacity(appeared ? popupOpacity : 0)
                        .offset(y: appeared ? 0 : 14)
                        .padding(.horizontal, 32)
                }

                if flying {
                    flyingChip(in: proxy, overlayOrigin: overlayOrigin)
                }
            }
            .allowsHitTesting(!flying)
            .onPreferenceChange(HeartXPChipFrameKey.self) { liveChipFrame = $0 }
        }
        .id(languageManager.currentLanguage)
        .onAppear {
            HapticManager.shared.soft()
            withAnimation(.easeOut(duration: 0.28)) {
                dimOpacity = 0.42
            }
            withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    private var popupCard: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 64, height: 64)
                NafsiCoinGlyph(size: 36)
            }
            .padding(.top, 26)
            .padding(.bottom, 16)

            Text(NSLocalizedString("heart.welcome.title", comment: "Welcome gift"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 22)
                .padding(.bottom, 14)

            bonusChip
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: HeartXPChipFrameKey.self,
                            value: geo.frame(in: .global)
                        )
                    }
                )
                .padding(.bottom, 14)

            Text(NSLocalizedString("heart.welcome.body", comment: "XP explanation"))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 22)
                .padding(.bottom, 22)

            Button(action: collect) {
                Text(String(
                    format: NSLocalizedString("heart.welcome.cta", comment: "Collect %d XP"),
                    bonus
                ))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryLight, AppTheme.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: AppTheme.primary.opacity(0.35), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: Color.black.opacity(0.16), radius: 24, y: 10)
        )
    }

    private var bonusChip: some View {
        HStack(spacing: 8) {
            NafsiCoinGlyph(size: 26)
            Text(String(
                format: NSLocalizedString("heart.welcome.bonus", comment: "+%d XP"),
                bonus
            ))
        }
        .font(.system(size: 26, weight: .bold, design: .rounded))
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryLight, AppTheme.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AppTheme.primary.opacity(0.32), radius: 10, y: 4)
        )
    }

    private func flyingChip(in proxy: GeometryProxy, overlayOrigin: CGPoint) -> some View {
        let start = local(startChipFrame, origin: overlayOrigin)
        let endGlobal = barGlobalFrame == .zero
            ? CGRect(
                x: overlayOrigin.x + proxy.size.width / 2 - 40,
                y: overlayOrigin.y + proxy.size.height * 0.38,
                width: 80,
                height: 28
              )
            : barGlobalFrame
        let end = local(endGlobal, origin: overlayOrigin)
        let t = fly
        let arc = -110 * sin(t * .pi)
        let x = start.midX + (end.midX - start.midX) * t
        let y = start.midY + (end.midY - start.midY) * t + arc

        return bonusChip
            .scaleEffect(chipScale)
            .opacity(chipOpacity)
            .position(x: x, y: y)
            .allowsHitTesting(false)
    }

    private func local(_ global: CGRect, origin: CGPoint) -> CGRect {
        CGRect(
            x: global.minX - origin.x,
            y: global.minY - origin.y,
            width: global.width,
            height: global.height
        )
    }

    private func collect() {
        guard !flying else { return }
        startChipFrame = liveChipFrame == .zero ? startChipFrame : liveChipFrame
        HapticManager.shared.medium()

        withAnimation(.easeOut(duration: 0.22)) {
            popupOpacity = 0
            dimOpacity = 0.08
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            flying = true
            chipOpacity = 1
            chipScale = 1

            withAnimation(.timingCurve(0.2, 0.85, 0.25, 1, duration: 0.78)) {
                fly = 1
                chipScale = 0.38
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
                HapticManager.shared.coinsLanded()
                withAnimation(.easeOut(duration: 0.14)) {
                    chipOpacity = 0
                }
                journey.collectWelcomeBonus()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.86) {
                withAnimation(.easeOut(duration: 0.32)) {
                    dimOpacity = 0
                }
                journey.endWelcome()
            }
        }
    }
}
