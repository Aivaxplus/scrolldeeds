//
//  OnboardingAllowNotificationsView.swift
//  scrolldeeds
//
//  Just Pray–inspired notification permission beat, ScrollDeeds chrome:
//  headline + stacked reminder previews + Qur’an quote.
//  System permission is requested by the parent CTA (not here).
//

import SwiftUI

struct OnboardingAllowNotificationsView: View {
    /// Slower than other narrative pages — stacked previews need to be readable.
    private var delayPerElement: Double { OnboardingFunnelConfig.showcaseDelayPerElement }
    private var fadeDuration: Double { OnboardingFunnelConfig.showcaseFadeDuration }
    private let revealOffset: CGFloat = 3

    @State private var headlineVisible = false
    @State private var cardVisible: [Bool] = [false, false, false]
    @State private var quoteVisible = false

    private let cards: [(titleKey: String, bodyKey: String)] = [
        ("onboarding.allow_notifications.card1.title", "onboarding.allow_notifications.card1.body"),
        ("onboarding.allow_notifications.card2.title", "onboarding.allow_notifications.card2.body"),
        ("onboarding.allow_notifications.card3.title", "onboarding.allow_notifications.card3.body")
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
                    .offset(y: -geometry.size.height * 0.10)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: max(20, geometry.size.height * 0.02))

                        headline
                            .opacity(headlineVisible ? 1 : 0)
                            .offset(y: headlineVisible ? 0 : revealOffset)
                            .padding(.horizontal, max(4, geometry.size.width * 0.01))

                        Spacer().frame(height: max(28, geometry.size.height * 0.04))

                        VStack(spacing: 12) {
                            ForEach(cards.indices, id: \.self) { index in
                                notificationCard(
                                    titleKey: cards[index].titleKey,
                                    bodyKey: cards[index].bodyKey
                                )
                                .opacity(cardVisible[index] ? 1 : 0)
                                .offset(y: cardVisible[index] ? 0 : revealOffset)
                            }
                        }

                        Spacer().frame(height: max(32, geometry.size.height * 0.05))

                        quoteBlock
                            .opacity(quoteVisible ? 1 : 0)
                            .offset(y: quoteVisible ? 0 : revealOffset)

                        Spacer().frame(height: 24)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, max(4, geometry.size.width * 0.02))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { startEntrance() }
    }

    // MARK: - Headline

    private var headline: some View {
        let full = NSLocalizedString("onboarding.allow_notifications.headline", comment: "")
        let highlight = NSLocalizedString("onboarding.allow_notifications.headline_highlight", comment: "")
        let size = CGFloat(26)

        return Group {
            if !highlight.isEmpty, full.contains(highlight), let range = full.range(of: highlight) {
                let before = String(full[..<range.lowerBound])
                let after = String(full[range.upperBound...])
                (Text(before)
                    .font(.system(size: size, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                + Text(highlight)
                    .font(.system(size: size, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                + Text(after)
                    .font(.system(size: size, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary))
                .multilineTextAlignment(.leading)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(full)
                    .font(.system(size: size, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: 340, alignment: .leading)
    }

    // MARK: - Cards

    private func notificationCard(titleKey: String, bodyKey: String) -> some View {
        OnboardingNotificationPreviewCard(
            title: NSLocalizedString(titleKey, comment: ""),
            message: NSLocalizedString(bodyKey, comment: "")
        )
    }

    // MARK: - Quote

    private var quoteBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("onboarding.allow_notifications.quote_label", comment: "Allah SWT said:"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primary)

            Text(NSLocalizedString("onboarding.allow_notifications.quote", comment: ""))
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(NSLocalizedString("onboarding.allow_notifications.quote_source", comment: ""))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: 340, alignment: .leading)
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
        for index in cards.indices {
            let delay = delayPerElement * Double(index + 1)
            withAnimation(revealAnimation(delay: delay)) {
                cardVisible[index] = true
            }
            HapticManager.shared.scheduleAnimationReveal(after: delay, beat: index + 1)
        }
        let quoteDelay = delayPerElement * Double(cards.count + 1)
        withAnimation(revealAnimation(delay: quoteDelay)) {
            quoteVisible = true
        }
        HapticManager.shared.scheduleAnimationReveal(after: quoteDelay, beat: cards.count + 1)
    }
}

struct OnboardingNotificationPreviewCard: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.primary.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image("ScrollDeedsAppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(NSLocalizedString("demo.notification.now", comment: "now"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textMuted)
                }
                Text(message)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppTheme.primary.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: AppTheme.primary.opacity(0.06), radius: 12, y: 4)
        )
    }
}

private struct SpiritualTypeOptionsHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct SpiritualTypePickerCard: View {
    @Binding var isExpanded: Bool
    var selected: SpiritualContentFilter
    var onSelect: (SpiritualContentFilter) -> Void

    @State private var measuredHeight: CGFloat = 0

    private var expandAnimation: Animation {
        .spring(response: 0.52, dampingFraction: 0.90)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .overlay(alignment: .topLeading) {
                    optionsColumn
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: SpiritualTypeOptionsHeightKey.self,
                                    value: geo.size.height
                                )
                            }
                        )
                }
                .onPreferenceChange(SpiritualTypeOptionsHeightKey.self) { measuredHeight = $0 }

            optionsColumn
                .frame(height: isExpanded ? (measuredHeight > 1 ? measuredHeight : 200) : 0, alignment: .top)
                .opacity(isExpanded ? 1 : 0)
                .clipped()
                .allowsHitTesting(isExpanded)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppTheme.primary.opacity(isExpanded ? 0.18 : 0.12), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(expandAnimation, value: isExpanded)
        .animation(.easeInOut(duration: 0.2), value: selected)
    }

    private var header: some View {
        Button {
            HapticManager.shared.soft()
            isExpanded.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("questionnaire.daily_reminder_type.label", comment: "What should I send?"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(selected.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var optionsColumn: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.primary.opacity(0.10))
                .frame(height: 1)
                .padding(.horizontal, 16)

            ForEach(Array(SpiritualContentFilter.allCases.enumerated()), id: \.element.id) { index, filter in
                if index > 0 {
                    Rectangle()
                        .fill(AppTheme.primary.opacity(0.06))
                        .frame(height: 1)
                        .padding(.leading, 16)
                }

                Button {
                    HapticManager.shared.selection()
                    onSelect(filter)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        isExpanded = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text(filter.title)
                            .font(.system(size: 16, weight: selected == filter ? .semibold : .medium, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                            .opacity(selected == filter ? 1 : 0)
                            .scaleEffect(selected == filter ? 1 : 0.6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(selected == filter ? AppTheme.primary.opacity(0.08) : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
