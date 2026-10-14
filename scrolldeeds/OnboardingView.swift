import SwiftUI

struct OnboardingView: View {
    let onNext: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showLanguageSettings = false
    @ObservedObject private var languageManager = LanguageManager.shared

    @State private var animateMockup    = false
    @State private var animateTitle     = false
    @State private var animateSubtitle  = false
    @State private var animateCTA       = false

    // UIKit-backed insets: always the real status-bar / home-indicator sizes,
    // unaffected by NavigationView hierarchy that skews geo.safeAreaInsets.
    @State private var deviceTopInset: CGFloat    = 59
    @State private var deviceBottomInset: CGFloat = 34

    /// Background (also used by streak preview previews).
    static let pageBg = AppTheme.background

    var body: some View {
        ZStack {
            SDPageBackground()
            RadialGradient(
                colors: [AppTheme.primary.opacity(0.08), AppTheme.primary.opacity(0.04), Color.clear],
                center: .top, startRadius: 0, endRadius: 420
            )
            .ignoresSafeArea()

            // Root ZStack uses .ignoresSafeArea() so the GeometryReader reports the
            // full-screen size.  We rely on deviceTopInset / deviceBottomInset (read
            // from UIKit in onAppear) instead of geo.safeAreaInsets, which is unstable
            // inside NavigationView regardless of toolbar visibility.
            GeometryReader { geo in
                let w         = geo.size.width
                let h         = geo.size.height
                let topInset  = deviceTopInset
                let bottomInset = deviceBottomInset
                let isLandscape = w > h
                let usableH   = h - topInset - bottomInset

                if isLandscape {
                    let innerH = h - topInset - bottomInset - 42 - max(16, bottomInset + 8)
                    let landscapeScaleH = innerH / 568.0
                    let landscapeScaleW = (w * 0.42 - 24) / 280.0
                    let mockupScaleL = max(0.38, min(landscapeScaleH, landscapeScaleW, 0.96))
                    let refW = min(w, 400)
                    let ls = min(max(refW / 390.0, 0.82), 1.05)
                    onboardingLayout(
                        mode: .landscape,
                        w: w, h: h,
                        layoutContentWidth: nil,
                        topInset: topInset,
                        bottomInset: bottomInset,
                        topBarH: 42,
                        titleSize: max(19, min(25 * ls, 28)),
                        subSize: max(12, min(14 * ls, 16)),
                        ctaSize: max(13, min(15 * ls, 17)),
                        buttonHeight: 48,
                        mockupScale: mockupScaleL,
                        mockupW: 280 * mockupScaleL,
                        mockupH: 568 * mockupScaleL,
                        compactVertical: true,
                        languageFlagSize: 20
                    )
                } else {
                    let layoutW = min(w, 440)
                    let m = Self.portraitFitMetrics(
                        usableH: usableH,
                        layoutWidth: layoutW,
                        bottomInset: bottomInset,
                        dynamicTypeSize: dynamicTypeSize
                    )
                    onboardingLayout(
                        mode: .portrait,
                        w: w, h: h,
                        layoutContentWidth: layoutW,
                        topInset: topInset,
                        bottomInset: bottomInset,
                        topBarH: m.topBarH,
                        titleSize: m.title,
                        subSize: m.sub,
                        ctaSize: m.cta,
                        buttonHeight: m.btnH,
                        mockupScale: m.mockupScale,
                        mockupW: 280 * m.mockupScale,
                        mockupH: 568 * m.mockupScale,
                        compactVertical: m.compactBottom,
                        languageFlagSize: m.flagSize
                    )
                }
            }
        }
        .ignoresSafeArea() // ZStack fills full screen; geo reports correct full-screen size
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showLanguageSettings) { LanguageSettingsView() }
        .onAppear {
            // Read device safe-area from UIKit — immune to NavigationView interference.
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first {
                deviceTopInset    = window.safeAreaInsets.top
                deviceBottomInset = window.safeAreaInsets.bottom
            }
            PostHogManager.shared.screen(AnalyticsScreen.getStarted)
            PostHogManager.shared.trackGetStartedViewed()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { HapticManager.shared.soft() }
            withAnimation { animateMockup = true }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25))  { animateTitle = true }
            withAnimation(.spring(response: 0.5,  dampingFraction: 0.8).delay(0.4))   { animateSubtitle = true }
            withAnimation(.spring(response: 0.5,  dampingFraction: 0.75).delay(0.55)) { animateCTA = true }
        }
    }

    // MARK: - Fit metrics (no scrolling; everything scales down on short/narrow screens)

    private struct PortraitFit {
        let title: CGFloat
        let sub: CGFloat
        let cta: CGFloat
        let btnH: CGFloat
        let mockupScale: CGFloat
        let topBarH: CGFloat
        let compactBottom: Bool
        let flagSize: CGFloat
    }

    /// Extra shrink when users use larger text (Settings → Display → Text Size).
    private static func dynamicTypeCompaction(_ d: DynamicTypeSize) -> CGFloat {
        if d >= .accessibility5 { return 0.64 }
        if d >= .accessibility3 { return 0.68 }
        if d >= .accessibility1 { return 0.72 }
        if d >= .xxxLarge { return 0.80 }
        if d >= .xxLarge { return 0.86 }
        if d >= .xLarge { return 0.91 }
        if d >= .large { return 0.96 }
        return 1.0
    }

    /// Iteratively shrink typography until mockup + bottom block + spacers fit in `usableH`.
    /// `layoutWidth` caps iPad width so the phone mockup matches phone-like proportions.
    private static func portraitFitMetrics(
        usableH: CGFloat,
        layoutWidth: CGFloat,
        bottomInset: CGFloat,
        dynamicTypeSize: DynamicTypeSize
    ) -> PortraitFit {
        let topBarH: CGFloat = 40
        let typeComp = dynamicTypeCompaction(dynamicTypeSize)
        var layoutScale: CGFloat = min(1.12, usableH / 708) * min(1.06, layoutWidth / 390) * typeComp
        layoutScale = min(max(layoutScale, 0.58), 1.08)

        let horizontalGutter: CGFloat = 44
        let bottomSafetyBuffer: CGFloat = 8   // trimmed — avoids over-shrinking mockup
        let minFlexBetweenSections: CGFloat = 6
        let mockupScaleCap: CGFloat = 0.93    // raised from 0.86 for a bigger mockup

        for _ in 0..<16 {
            let title = max(16.5, min(27 * layoutScale, 30))
            let sub = max(11, min(15 * layoutScale, 17.5))
            let cta = max(12, min(16 * layoutScale, 18))
            let btnH = max(44, min(50 * layoutScale, 54))
            let compact = layoutScale < 0.92 || usableH < 640
            let flagSize = max(17, min(20 * layoutScale, 22))

            // Bottom copy + footer (tighter estimate — footer usually 1 line + links)
            let bottomIntrinsic: CGFloat = title * 2.9 + (compact ? 6 : 8) + sub * 1.7
                + (compact ? 12 : 14) + btnH + (compact ? 8 : 10) + (compact ? 36 : 40)
                + bottomSafetyBuffer

            let mockAvail = usableH - topBarH - bottomIntrinsic - bottomInset - minFlexBetweenSections

            let scaleW = max(0.15, (layoutWidth - horizontalGutter) / 280)
            let scaleH = max(0, mockAvail) / 568
            var ms = min(scaleW, scaleH, mockupScaleCap)
            ms = max(0.30, ms)
            ms *= 0.98

            if mockAvail >= 568 * ms + 2 {
                return PortraitFit(
                    title: title, sub: sub, cta: cta, btnH: btnH,
                    mockupScale: ms, topBarH: topBarH, compactBottom: compact,
                    flagSize: flagSize
                )
            }
            layoutScale *= 0.89
        }

        let title = CGFloat(16.5)
        let sub = CGFloat(11)
        let cta = CGFloat(12)
        let btnH = CGFloat(44)
        let bottomIntrinsic: CGFloat = title * 2.9 + 6 + sub * 1.7 + 12 + btnH + 8 + 36 + bottomSafetyBuffer
        let mockAvail = usableH - topBarH - bottomIntrinsic - bottomInset - minFlexBetweenSections
        var ms = max(0.30, min((layoutWidth - horizontalGutter) / 280, max(0, mockAvail) / 568, mockupScaleCap))
        ms *= 0.98
        return PortraitFit(
            title: title, sub: sub, cta: cta, btnH: btnH,
            mockupScale: ms, topBarH: topBarH, compactBottom: true,
            flagSize: 17
        )
    }

    private enum LayoutMode { case portrait, landscape }

    @ViewBuilder
    private func onboardingLayout(
        mode: LayoutMode,
        w: CGFloat, h: CGFloat,
        layoutContentWidth: CGFloat? = nil,
        topInset: CGFloat, bottomInset: CGFloat,
        topBarH: CGFloat,
        titleSize: CGFloat, subSize: CGFloat, ctaSize: CGFloat,
        buttonHeight: CGFloat,
        mockupScale: CGFloat, mockupW: CGFloat, mockupH: CGFloat,
        compactVertical: Bool,
        languageFlagSize: CGFloat = 20
    ) -> some View {
        switch mode {
        case .landscape:
            VStack(spacing: 0) {
                Spacer().frame(height: topInset)
                languageBar(height: topBarH)
                HStack(alignment: .center, spacing: 14) {
                    HStack {
                        Spacer(minLength: 0)
                        mockupBlock(mockupScale: mockupScale, mockupW: mockupW, mockupH: mockupH)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: w * 0.44)
                    bottomCopyBlock(
                        titleSize: max(19, titleSize * 0.92),
                        subSize: max(12, subSize * 0.95),
                        ctaSize: max(13, ctaSize * 0.95),
                        horizontalPadding: 16,
                        buttonHeight: min(buttonHeight, 48),
                        compactVertical: true
                    )
                    .frame(maxWidth: w * 0.54, maxHeight: .infinity, alignment: .center)
                }
                .padding(.horizontal, max(16, (w - min(w, 900)) / 2 + 16))
                Spacer(minLength: 4)
                Spacer().frame(height: max(bottomInset, 12))
            }
            .frame(width: w, height: h)

        case .portrait:
            let contentW = layoutContentWidth ?? w
            let hPad = min(28, contentW * 0.075 + 18)
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack(spacing: 0) {
                    Spacer().frame(height: topInset)
                    languageBar(height: topBarH, flagSize: languageFlagSize)
                    Spacer(minLength: 0)
                    mockupBlock(mockupScale: mockupScale, mockupW: mockupW, mockupH: mockupH)
                    Spacer(minLength: 0)
                    bottomCopyBlock(
                        titleSize: titleSize,
                        subSize: subSize,
                        ctaSize: ctaSize,
                        horizontalPadding: hPad,
                        buttonHeight: buttonHeight,
                        compactVertical: compactVertical
                    )
                    Spacer().frame(height: max(bottomInset, 12))
                }
                .frame(width: contentW, height: h, alignment: .top)
                Spacer(minLength: 0)
            }
            .frame(width: w, height: h)
        }
    }

    private func languageBar(height: CGFloat, flagSize: CGFloat = 20) -> some View {
                    HStack {
                        Spacer()
                        Button(action: { HapticManager.shared.soft(); showLanguageSettings = true }) {
                            HStack(spacing: 6) {
                    Text(currentLanguageFlag()).font(.system(size: flagSize))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(
                                Capsule().fill(AppTheme.card.opacity(0.8))
                                    .overlay(Capsule().strokeBorder(AppTheme.border.opacity(0.5), lineWidth: 1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 20)
        }
        .frame(height: height)
                    }

    private func mockupBlock(mockupScale: CGFloat, mockupW: CGFloat, mockupH: CGFloat) -> some View {
                    iPhoneMockupView { OnboardingDemoVideoView() }
                        .scaleEffect(animateMockup ? mockupScale : 0.92 * mockupScale)
                        .frame(width: mockupW, height: mockupH)
            .opacity(animateMockup ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.1), value: animateMockup)
    }

    private func bottomCopyBlock(
        titleSize: CGFloat,
        subSize: CGFloat,
        ctaSize: CGFloat,
        horizontalPadding: CGFloat,
        buttonHeight: CGFloat,
        compactVertical: Bool
    ) -> some View {
        let gapTitleSub: CGFloat = compactVertical ? 6 : 8
        let gapSubButton: CGFloat = compactVertical ? 12 : 16
        let gapAfterButton: CGFloat = compactVertical ? 8 : 10

        return VStack(spacing: 0) {
                    Text(NSLocalizedString("onboarding.title", comment: "Break Phone Addiction"))
                        .font(.system(size: titleSize, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .opacity(animateTitle ? 1 : 0)
                        .offset(y: animateTitle ? 0 : 12)
                        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.3), value: animateTitle)

            Spacer().frame(height: gapTitleSub)

                    Text(NSLocalizedString("onboarding.subtitle", comment: "Through the Power of Good Deeds"))
                .font(.system(size: subSize, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                        .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .opacity(animateSubtitle ? 1 : 0)
                        .offset(y: animateSubtitle ? 0 : 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.45), value: animateSubtitle)

            Spacer().frame(height: gapSubButton)

                    Button(action: {
                        HapticManager.shared.medium()
                        PostHogManager.shared.trackGetStartedCTAClicked()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    HapticManager.shared.heavy()
                    onNext()
                        }
                    }) {
                        HStack(spacing: 10) {
                            Text(NSLocalizedString("onboarding.cta_button", comment: "Start Your Journey"))
                        .minimumScaleFactor(0.82)
                        .lineLimit(1)
                            Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .scaleEffect(animateCTA ? 1 : 0.95)
            .opacity(animateCTA ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.6), value: animateCTA)

            Spacer().frame(height: gapAfterButton)

            OnboardingLegalFooter()
                .opacity(animateCTA ? 1 : 0)
        }
        .padding(.horizontal, horizontalPadding)
    }

    private func currentLanguageFlag() -> String {
        LanguageManager.supportedLanguages.first { $0.code == languageManager.currentLanguage }?.flag ?? "🇬🇧"
    }
}

// MARK: - Legal footer (horizontal when wide; stacked links when narrow / long copy)

private struct OnboardingLegalFooter: View {
    private static let termsURL = URL(string: "https://getnafsi.lovable.app/terms")!
    private static let privacyURL = URL(string: "https://getnafsi.lovable.app/privacy")!

    var body: some View {
        VStack(spacing: 6) {
            Text(LocalizedKey.Onboarding.termsPrefix.localized)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 4) {
                    termsButton
                    Text(LocalizedKey.Onboarding.termsAnd.localized)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                    privacyButton
                }

                VStack(spacing: 8) {
                    termsButton
                    privacyButton
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var termsButton: some View {
        Button(action: { UIApplication.shared.open(Self.termsURL) }) {
            Text(LocalizedKey.Onboarding.termsLink.localized)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.primary.opacity(0.95))
                .underline()
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var privacyButton: some View {
        Button(action: { UIApplication.shared.open(Self.privacyURL) }) {
            Text(LocalizedKey.Onboarding.privacyLink.localized)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.primary.opacity(0.95))
                .underline()
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Press animation button style
private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview { OnboardingView(onNext: {}) }
