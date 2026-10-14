//
//  OnboardingWidgetDesireView.swift
//  scrolldeeds
//
//  Desire beat after the distraction question: a verse waiting on the Home Screen
//  so unlocking no longer starts with apps. Not a settings page.
//

import SwiftUI

struct OnboardingWidgetDesireView: View {
    var onReady: () -> Void

    private var delayPerElement: Double { OnboardingFunnelConfig.showcaseDelayPerElement }
    private var fadeDuration: Double { OnboardingFunnelConfig.showcaseFadeDuration }

    @State private var headerVisible = false
    @State private var phoneVisible = false
    @State private var featureVisible: [Bool] = [false, false, false]
    @State private var didFinishReveal = false

    private let features = [
        "questionnaire.widget_desire.feature1",
        "questionnaire.widget_desire.feature2",
        "questionnaire.widget_desire.feature3"
    ]

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 560
            let titleSize: CGFloat = compact ? 22 : 25

            ZStack(alignment: .top) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primary.opacity(0.12),
                                AppTheme.primary.opacity(0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 180
                        )
                    )
                    .frame(width: 360, height: 360)
                    .blur(radius: 40)
                    .offset(y: -80)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 0) {
                    header(titleSize: titleSize, compact: compact)
                        .opacity(headerVisible ? 1 : 0)
                        .offset(y: headerVisible ? 0 : 8)

                    Spacer(minLength: compact ? 8 : 12)

                    phoneMockup(compact: compact)
                        .frame(maxWidth: .infinity)
                        .opacity(phoneVisible ? 1 : 0)
                        .offset(y: phoneVisible ? 0 : 12)
                        .scaleEffect(phoneVisible ? 1 : 0.96)

                    Spacer(minLength: compact ? 14 : 20)

                    VStack(alignment: .leading, spacing: compact ? 12 : 14) {
                        ForEach(features.indices, id: \.self) { index in
                            featureRow(
                                number: index + 1,
                                key: features[index],
                                compact: compact
                            )
                            .opacity(featureVisible[index] ? 1 : 0)
                            .offset(y: featureVisible[index] ? 0 : 8)
                        }
                    }
                    .padding(.horizontal, 2)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { startEntrance() }
    }

    private func header(titleSize: CGFloat, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            OnboardingTypewriter.highlightedText(
                full: NSLocalizedString("questionnaire.widget_desire.title", comment: ""),
                visibleCount: NSLocalizedString("questionnaire.widget_desire.title", comment: "").count,
                highlight: NSLocalizedString("questionnaire.widget_desire.title.highlight", comment: ""),
                fontSize: titleSize,
                weight: .bold,
                highlightWeight: .bold
            )
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .minimumScaleFactor(0.82)
            .fixedSize(horizontal: false, vertical: true)

            Text(NSLocalizedString("questionnaire.widget_desire.subtitle", comment: ""))
                .font(.system(size: compact ? 14 : 16, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(4)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func phoneMockup(compact: Bool) -> some View {
        let quote = desireQuote
        let pose = widgetPose(kind: quote.kind, id: quote.id)

        return VStack(alignment: .leading, spacing: compact ? 10 : 12) {
            HStack {
                Text("9:41")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
            }
            .padding(.horizontal, 4)

            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(kindLabel(quote.kind).uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.13, green: 0.45, blue: 0.32))
                    Text(quote.text)
                        .font(.system(size: compact ? 15 : 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.11, green: 0.15, blue: 0.13))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(4)
                        .minimumScaleFactor(0.85)
                    Text(quote.reference)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.36, green: 0.44, blue: 0.39))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(pose)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(height: compact ? 72 : 88)
                    .accessibilityHidden(true)
            }
            .padding(compact ? 12 : 14)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.97, blue: 0.94),
                            Color(red: 0.99, green: 0.98, blue: 0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [AppTheme.primary.opacity(0.16), Color.clear],
                        center: .bottomTrailing,
                        startRadius: 4,
                        endRadius: 140
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            HStack(spacing: compact ? 12 : 14) {
                ForEach(Self.distractionAppIcons, id: \.self) { asset in
                    Image(asset)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: compact ? 40 : 44, height: compact ? 40 : 44)
                        .clipShape(RoundedRectangle(cornerRadius: compact ? 10 : 12, style: .continuous))
                        .shadow(color: .black.opacity(0.28), radius: 4, y: 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
        .padding(compact ? 14 : 16)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.22, blue: 0.18),
                    Color(red: 0.08, green: 0.14, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 18, y: 10)
    }

    private func featureRow(number: Int, key: String, compact: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: compact ? 13 : 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: compact ? 26 : 28, height: compact ? 26 : 28)
                .background(Circle().fill(AppTheme.primary))
                .padding(.top, 1)

            Text(NSLocalizedString(key, comment: ""))
                .font(.system(size: compact ? 15 : 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static let distractionAppIcons = [
        "AppIconTikTok",
        "AppIconInstagram",
        "AppIconYouTube",
        "AppIconSnapchat"
    ]

    private var desireQuote: NafsiWidgetQuote {
        NafsiQuoteCatalog.quotes(language: LanguageManager.shared.currentLanguage)
            .first { $0.kind == "quran" }
            ?? NafsiWidgetQuote(
                id: "q-2-152",
                kind: "quran",
                text: NSLocalizedString("questionnaire.widget_desire.fallback_verse", comment: ""),
                arabic: "فَاذْكُرُونِي أَذْكُرْكُمْ",
                reference: "Qur'an 2:152",
                reflection: ""
            )
    }

    private func kindLabel(_ kind: String) -> String {
        NSLocalizedString("widget.kind.\(kind)", comment: "")
    }

    private func widgetPose(kind: String, id: String) -> String {
        let pool: [String]
        switch kind {
        case "dua":
            pool = ["NafsiPoseOffer", "NafsiPoseSit"]
        case "hadith":
            pool = ["NafsiPoseRise", "NafsiPoseReach", "NafsiPoseStand"]
        default:
            pool = ["NafsiPoseRead", "NafsiPoseWatch", "NafsiPoseCrouch"]
        }
        let hash = id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return pool[abs(hash) % pool.count]
    }

    private func startEntrance() {
        headerVisible = false
        phoneVisible = false
        featureVisible = [false, false, false]
        didFinishReveal = false

        withAnimation(.easeInOut(duration: fadeDuration)) {
            headerVisible = true
        }
        HapticManager.shared.animationReveal(beat: 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + delayPerElement) {
            withAnimation(.easeInOut(duration: fadeDuration)) {
                phoneVisible = true
            }
            HapticManager.shared.animationReveal(beat: 1)
        }

        for index in features.indices {
            let delay = delayPerElement * Double(index + 2)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: fadeDuration)) {
                    featureVisible[index] = true
                }
                HapticManager.shared.animationReveal(beat: index + 2)
            }
        }

        let readyAt = delayPerElement * Double(features.count + 2) + fadeDuration + 0.12
        DispatchQueue.main.asyncAfter(deadline: .now() + readyAt) {
            guard !didFinishReveal else { return }
            didFinishReveal = true
            onReady()
        }
    }
}
