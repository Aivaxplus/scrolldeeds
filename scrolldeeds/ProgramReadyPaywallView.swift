//
//  ProgramReadyPaywallView.swift
//  scrolldeeds
//
//  Compact conversion screen: check → “program is ready” → fanned iPhone
//  mockups of the Quick Guide screens → yearly / weekly → Continue.
//  (cream page, emerald accents, 3D primary CTA) — not a full-bleed green shell.
//  Close returns to the benefits sales scroll. Purchase cancel is handled by the parent.
//

import SwiftUI
import UIKit

struct ProgramReadyPaywallView: View {
    let yearlyPrice: String
    let yearlyPerWeek: String
    let weeklyPrice: String
    let savePercent: Int
    let selectedIsYearly: Bool
    let isPurchasing: Bool
    let onSelectYearly: () -> Void
    let onSelectWeekly: () -> Void
    let onContinue: () -> Void
    let onClose: () -> Void
    let onRestore: () -> Void
    let onOpenTerms: () -> Void
    let onOpenPrivacy: () -> Void
    var redeemFooter: PaywallInlineRedeem

    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var featuredMockupIndex = 0

    var body: some View {
        ZStack {
            SDPageBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    PaywallCloseButton(
                        iconColor: UIColor(AppTheme.textMuted),
                        backgroundColor: UIColor(AppTheme.card),
                        action: onClose
                    )
                    .frame(width: 28, height: 28)
                    .padding(.trailing, 18)
                    .padding(.top, 8)
                }

                Spacer(minLength: 4)

                VStack(spacing: 10) {
                    SDIconBadge(
                        systemName: "checkmark",
                        size: 52,
                        iconSize: 20
                    )

                    Text(NSLocalizedString("conv_paywall.program.title", comment: "Your personalized program is ready"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 28)

                    Text(NSLocalizedString("conv_paywall.program.subtitle", comment: "Get unlimited access to ScrollDeeds Pro."))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                }

                Spacer(minLength: 6)

                fannedMockups
                    .padding(.horizontal, 4)

                Spacer(minLength: 16)

                HStack(alignment: .top, spacing: 12) {
                    yearlyPlanCard
                    weeklyPlanCard
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 22)
                .padding(.top, savePercent > 0 ? 12 : 0)

                Button(action: onContinue) {
                    HStack(spacing: 10) {
                        if isPurchasing {
                            SwiftUI.ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(NSLocalizedString("conv_paywall.program.continue", comment: "Continue"))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                }
                .buttonStyle(PrimaryButtonStyle(stylesLabel: false))
                .disabled(isPurchasing)
                .opacity(isPurchasing ? 0.7 : 1)
                .padding(.horizontal, 22)
                .padding(.top, 16)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(NSLocalizedString("paywall.trust.cancel", comment: "Cancel anytime"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, 12)

                redeemFooter
                    .padding(.horizontal, 22)
                    .padding(.top, 10)

                HStack(spacing: 14) {
                    footerLink(NSLocalizedString("paywall.terms_eula", comment: "Terms"), action: onOpenTerms)
                    footerDot
                    footerLink(NSLocalizedString("paywall.privacy", comment: "Privacy Policy"), action: onOpenPrivacy)
                    footerDot
                    footerLink(NSLocalizedString("paywall.restore", comment: "Restore"), action: onRestore)
                }
                .padding(.top, 10)
                .padding(.bottom, 18)
            }
        }
    }

    private var footerDot: some View {
        Text("·")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(AppTheme.textMuted)
    }

    private func footerLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
                .underline()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var mockupNames: [String] {
        QuickGuideMockupAssets.programReadyFanNames(languageCode: languageManager.currentLanguage)
    }

    private var fannedMockups: some View {
        let names = mockupNames
        return VStack(spacing: 10) {
            GeometryReader { geo in
                ZStack {
                    ForEach(names.indices, id: \.self) { index in
                        let slot = fanSlot(for: index, featured: featuredMockupIndex, count: names.count)
                        mockupPhone(named: names[index], scale: slot.scale)
                            .rotationEffect(.degrees(slot.rotation))
                            .offset(x: slot.x, y: slot.y)
                            .zIndex(slot.z)
                            .opacity(slot.opacity)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                                    featuredMockupIndex = index
                                }
                            }
                    }
                }
                .frame(width: geo.size.width, height: 252)
                .scaleEffect(min(1, geo.size.height / 252))
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(minHeight: 150, maxHeight: 252)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        guard names.count > 1 else { return }
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                            if value.translation.width < -24 {
                                featuredMockupIndex = (featuredMockupIndex + 1) % names.count
                            } else if value.translation.width > 24 {
                                featuredMockupIndex = (featuredMockupIndex - 1 + names.count) % names.count
                            }
                        }
                    }
            )

            HStack(spacing: 6) {
                ForEach(names.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == featuredMockupIndex ? AppTheme.primary : AppTheme.border)
                        .frame(width: index == featuredMockupIndex ? 16 : 6, height: 6)
                }
            }
        }
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(2.7))
                } catch {
                    break
                }
                guard !Task.isCancelled, names.count > 1 else { return }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                    featuredMockupIndex = (featuredMockupIndex + 1) % names.count
                }
            }
        }
    }

    private func mockupPhone(named name: String, scale: CGFloat) -> some View {
        iPhoneMockupView {
            mockupScreen(named: name)
        }
        .scaleEffect(scale)
        .frame(width: 280 * scale, height: 568 * scale)
        .shadow(color: Color.black.opacity(0.16), radius: 16, y: 8)
    }

    @ViewBuilder
    private func mockupScreen(named name: String) -> some View {
        if let ui = QuickGuideMockupAssets.uiImage(
            named: name,
            languageCode: languageManager.currentLanguage
        ) {
            Image(uiImage: ui)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            AppTheme.card
        }
    }

    private func fanSlot(
        for index: Int,
        featured: Int,
        count: Int
    ) -> (x: CGFloat, y: CGFloat, rotation: Double, scale: CGFloat, z: Double, opacity: Double) {
        var delta = index - featured
        if count > 0 {
            let half = count / 2
            if delta > half { delta -= count }
            if delta < -half { delta += count }
        }
        switch delta {
        case 0:
            return (0, 0, 0, 0.44, 10, 1)
        case -1:
            return (-74, 12, -12, 0.34, 6, 1)
        case 1:
            return (74, 12, 12, 0.34, 6, 1)
        case -2:
            return (-124, 24, -22, 0.28, 2, 0.95)
        case 2:
            return (124, 24, 22, 0.28, 2, 0.95)
        default:
            return (0, 36, 0, 0.24, 0, 0.4)
        }
    }

    private var yearlyPlanCard: some View {
        planCard(
            title: NSLocalizedString("paywall.yearly.title", comment: "Yearly"),
            badge: savePercent > 0
                ? String(format: NSLocalizedString("paywall.save_percent", comment: "SAVE %d%%"), savePercent)
                : nil,
            price: yearlyPrice,
            detail: yearlyPerWeek,
            selected: selectedIsYearly,
            action: onSelectYearly
        )
    }

    private var weeklyPlanCard: some View {
        planCard(
            title: NSLocalizedString("paywall.weekly.title", comment: "Weekly"),
            badge: nil,
            price: weeklyPrice,
            detail: NSLocalizedString("paywall.trust.cancel", comment: "Cancel anytime"),
            selected: !selectedIsYearly,
            action: onSelectWeekly
        )
    }

    private func planCard(
        title: String,
        badge: String?,
        price: String,
        detail: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)

                    Spacer(minLength: 0)

                    ZStack {
                        Circle()
                            .stroke(selected ? AppTheme.primary : AppTheme.border, lineWidth: 2)
                            .frame(width: 20, height: 20)
                        if selected {
                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 12, height: 12)
                        }
                    }
                }

                Text(price)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(selected ? AppTheme.primary : AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(detail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? AppTheme.primary.opacity(0.08) : AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                selected ? AppTheme.primary : AppTheme.border.opacity(0.75),
                                lineWidth: selected ? 2 : 1
                            )
                    )
            )
            .overlay(alignment: .top) {
                if let badge, !badge.isEmpty {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.paywallTrialBadgeBackground)
                        )
                        .offset(y: -12)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
