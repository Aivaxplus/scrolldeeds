//
//  OnboardingFajrWakeView.swift
//  scrolldeeds
//
//  Visual 1–2–3 of the photo Fajr alarm: landscape art on top of each card,
//  numbered copy underneath. Fits a single screen — no scrolling.
//

import SwiftUI

struct OnboardingFajrWakeView: View {
    var onReady: () -> Void

    private var delayPerElement: Double { OnboardingFunnelConfig.showcaseDelayPerElement }
    private var fadeDuration: Double { OnboardingFunnelConfig.showcaseFadeDuration }

    @State private var headerVisible = false
    @State private var stepVisible: [Bool] = [false, false, false]
    @State private var didFinishReveal = false

    private let steps: [(image: String, titleKey: String, bodyKey: String)] = [
        ("OnboardingFajrStep1", "questionnaire.fajr_wake.step1.title", "questionnaire.fajr_wake.step1.body"),
        ("OnboardingFajrStep2", "questionnaire.fajr_wake.step2.title", "questionnaire.fajr_wake.step2.body"),
        ("OnboardingFajrStep3", "questionnaire.fajr_wake.step3.title", "questionnaire.fajr_wake.step3.body")
    ]

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 560
            let titleSize: CGFloat = compact ? 22 : 25
            let cardSpacing: CGFloat = compact ? 8 : 10
            let sideInset: CGFloat = 24
            let headerReserve: CGFloat = compact ? 104 : 118
            let textRow: CGFloat = compact ? 38 : 42
            let cardChrome = textRow + 18
            let gapAfterHeader: CGFloat = compact ? 8 : 12
            let gapBeforeBottom: CGFloat = 4
            let used = headerReserve + gapAfterHeader + gapBeforeBottom + cardSpacing * 2 + cardChrome * 3
            let imageHeight = max(96, (geometry.size.height - used) / 3)
            let cardWidth = max(0, geometry.size.width - sideInset * 2)

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

                    Spacer(minLength: gapAfterHeader)

                    VStack(spacing: cardSpacing) {
                        ForEach(steps.indices, id: \.self) { index in
                            stepCard(
                                number: index + 1,
                                imageName: steps[index].image,
                                titleKey: steps[index].titleKey,
                                bodyKey: steps[index].bodyKey,
                                imageHeight: imageHeight,
                                cardWidth: cardWidth,
                                compact: compact
                            )
                            .opacity(stepVisible[index] ? 1 : 0)
                            .offset(y: stepVisible[index] ? 0 : 10)
                        }
                    }

                    Spacer(minLength: gapBeforeBottom)
                }
                .padding(.horizontal, sideInset)
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
                full: NSLocalizedString("questionnaire.fajr_wake.title", comment: ""),
                visibleCount: NSLocalizedString("questionnaire.fajr_wake.title", comment: "").count,
                highlight: NSLocalizedString("questionnaire.fajr_wake.title.highlight", comment: ""),
                fontSize: titleSize,
                weight: .bold,
                highlightWeight: .bold
            )
            .multilineTextAlignment(.leading)
            .lineLimit(2)
            .minimumScaleFactor(0.82)
            .fixedSize(horizontal: false, vertical: true)

            Text(NSLocalizedString("questionnaire.fajr_wake.subtitle", comment: ""))
                .font(.system(size: compact ? 14 : 16, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(5)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stepCard(
        number: Int,
        imageName: String,
        titleKey: String,
        bodyKey: String,
        imageHeight: CGFloat,
        cardWidth: CGFloat,
        compact: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: imageHeight)
                .clipped()

            HStack(alignment: .center, spacing: 10) {
                Text("\(number)")
                    .font(.system(size: compact ? 13 : 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: compact ? 24 : 28, height: compact ? 24 : 28)
                    .background(Circle().fill(AppTheme.primary))

                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString(titleKey, comment: ""))
                        .font(.system(size: compact ? 15 : 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(NSLocalizedString(bodyKey, comment: ""))
                        .font(.system(size: compact ? 13 : 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, compact ? 8 : 10)
        }
        .frame(width: cardWidth)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    private func startEntrance() {
        headerVisible = false
        stepVisible = [false, false, false]
        didFinishReveal = false

        withAnimation(.easeInOut(duration: fadeDuration)) {
            headerVisible = true
        }
        HapticManager.shared.animationReveal(beat: 0)

        for index in steps.indices {
            let delay = delayPerElement * Double(index + 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: fadeDuration)) {
                    stepVisible[index] = true
                }
                HapticManager.shared.animationReveal(beat: index + 1)
            }
        }

        let readyAt = delayPerElement * Double(steps.count + 1) + fadeDuration + 0.12
        DispatchQueue.main.asyncAfter(deadline: .now() + readyAt) {
            guard !didFinishReveal else { return }
            didFinishReveal = true
            onReady()
        }
    }
}
