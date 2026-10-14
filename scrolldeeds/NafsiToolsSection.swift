//
//  NafsiToolsSection.swift
//  scrolldeeds
//
//  Calm 2-column “Nafsi tools” grid plus the coins / hearts wallet card.
//

import SwiftUI

enum NafsiTool: String, CaseIterable, Identifiable {
    case lockedApps
    case homeWidgets
    case lockWidgets
    case fajr
    case reminders
    case saved

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .lockedApps: return "nafsi.tools.locked_apps"
        case .homeWidgets: return "nafsi.tools.home_widgets"
        case .lockWidgets: return "nafsi.tools.lock_widgets"
        case .fajr: return "nafsi.tools.fajr"
        case .reminders: return "nafsi.tools.reminders"
        case .saved: return "nafsi.tools.saved"
        }
    }

    /// Flat illustration per tool. All are square cutouts on transparency, so
    /// they sit on the tile plate without ever cropping or stretching.
    var illustration: String {
        switch self {
        case .lockedApps: return "ToolLockedApps"
        case .homeWidgets: return "ToolHomeWidgets"
        case .lockWidgets: return "ToolLockWidgets"
        case .fajr: return "ToolFajrAlarm"
        case .reminders: return "ToolReminders"
        case .saved: return "ToolSaved"
        }
    }

    /// Flat SF Symbol per tool — crisp at every size and always fits its frame.
    var symbol: String {
        switch self {
        case .lockedApps: return "lock.fill"
        case .homeWidgets: return "square.grid.2x2.fill"
        case .lockWidgets: return "lock.rectangle.stack.fill"
        case .fajr: return "sunrise.fill"
        case .reminders: return "bell.badge.fill"
        case .saved: return "bookmark.fill"
        }
    }

    var tint: Color {
        switch self {
        case .lockedApps: return AppTheme.primary
        case .homeWidgets: return Color(red: 0.29, green: 0.55, blue: 0.86)
        case .lockWidgets: return Color(red: 0.46, green: 0.44, blue: 0.82)
        case .fajr: return AppTheme.accent
        case .reminders: return Color(red: 0.90, green: 0.49, blue: 0.33)
        case .saved: return Color(red: 0.20, green: 0.63, blue: 0.56)
        }
    }

    var requiresPremium: Bool {
        switch self {
        case .lockedApps, .saved: return false
        case .homeWidgets, .lockWidgets, .fajr, .reminders: return true
        }
    }
}

struct NafsiToolsSection: View {
    var premiumLocked: Bool
    /// On a short phone the spotlight is the locked-apps tile, so the tour
    /// does not center the whole grid under the header.
    var tutorialOnLockedAppsTile: Bool = false
    var onSelect: (NafsiTool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("nafsi.tools.title", comment: "Nafsi tools"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 2)

            let tools = Array(NafsiTool.allCases)
            VStack(spacing: 12) {
                ForEach(Array(stride(from: 0, to: tools.count, by: 2)), id: \.self) { index in
                    HStack(spacing: 12) {
                        tile(tools[index])
                        if index + 1 < tools.count {
                            tile(tools[index + 1])
                        }
                    }
                }
            }
        }
    }

    private func tile(_ tool: NafsiTool) -> some View {
        NafsiToolTile(
            tool: tool,
            locked: tool.requiresPremium && premiumLocked
        ) {
            onSelect(tool)
        }
        .dashboardTutorialTarget(
            .lockedApps,
            active: tutorialOnLockedAppsTile && tool == .lockedApps
        )
    }
}

private struct NafsiToolTile: View {
    let tool: NafsiTool
    let locked: Bool
    let action: () -> Void

    /// Warm plate the illustrations were drawn on, fixed in both colour schemes
    /// so the deep green shapes keep their contrast in dark mode.
    private static let plate = Color(red: 0.969, green: 0.957, blue: 0.925)

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Self.plate)

                    Image(tool.illustration)
                        .resizable()
                        .scaledToFit()
                        .padding(14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                            .padding(6)
                            .background(Circle().fill(Color.white.opacity(0.9)))
                            .padding(8)
                    }
                }
                .frame(height: 96)

                Text(NSLocalizedString(tool.titleKey, comment: ""))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(NafsiPressStyle())
        .accessibilityLabel(NSLocalizedString(tool.titleKey, comment: ""))
    }
}

/// Soft press feedback shared by the dashboard cards.
struct NafsiPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

// MARK: - Coins + hearts wallet

/// One calm card: coins with progress to the next rank, then the hearts that
/// keep the apps open.
struct NafsiCoinsChip: View {
    let coins: Int
    let hearts: Int
    var heartCapacity: Int = NafsiLivesManager.fallbackCapacity
    var minutesRemaining: Int = 0
    var onBuyHearts: (() -> Void)?

    @ObservedObject private var journey = HeartJourneyManager.shared
    @State private var floatingChange: CoinChange?
    @State private var floatUp = false
    @State private var coinKick = false

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                NafsiCoinGlyph(size: 30)
                    .scaleEffect(coinKick ? 1.22 : 1)
                    .rotationEffect(.degrees(coinKick ? -12 : 0))

                Text(NSLocalizedString("heart.xp_label", comment: "Coins"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer(minLength: 8)

                Text("\(coins)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .scaleEffect(coinKick ? 1.12 : 1)
                    .overlay(alignment: .top) { floatingBadge }
            }

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    NafsiHeartsRow(hearts: hearts, maxHearts: heartCapacity, size: 20)

                    if minutesRemaining > 0 {
                        Text(String(
                            format: NSLocalizedString("nafsi.hearts.time_left", comment: "%d min left"),
                            minutesRemaining
                        ))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    }
                }

                Spacer(minLength: 8)

                if let onBuyHearts {
                    Button(action: onBuyHearts) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .black))
                            Text(NSLocalizedString("nafsi.hearts.buy", comment: "Buy hearts"))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AppTheme.primary.opacity(0.12)))
                    }
                    .buttonStyle(NafsiPressStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.border.opacity(0.6), lineWidth: 1)
        )
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: HeartXPBarFrameKey.self,
                    value: geo.frame(in: .global)
                )
            }
        )
        .onChange(of: journey.lastCoinChange) { change in
            guard let change else { return }
            play(change)
        }
    }

    /// Floating “+20” / “−40” that rises off the balance whenever coins move.
    @ViewBuilder
    private var floatingBadge: some View {
        if let floatingChange {
            let positive = floatingChange.amount > 0
            Text(positive ? "+\(floatingChange.amount)" : "\(floatingChange.amount)")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(positive ? AppTheme.primary : AppTheme.statusNegative)
                .monospacedDigit()
                .shadow(color: AppTheme.card.opacity(0.9), radius: 2)
                .offset(y: floatUp ? -26 : 2)
                .opacity(floatUp ? 0 : 1)
                .allowsHitTesting(false)
                .transition(.identity)
        }
    }

    private func play(_ change: CoinChange) {
        floatingChange = change
        floatUp = false
        if change.amount < 0 {
            HapticManager.shared.soft()
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) { coinKick = true }
        withAnimation(.easeOut(duration: 1.0)) { floatUp = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { coinKick = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            if floatingChange?.id == change.id { floatingChange = nil }
        }
    }

}

struct NafsiCoinGlyph: View {
    var size: CGFloat = 20

    var body: some View {
        Image("NafsiCoinMark")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct NafsiHeartsRow: View {
    let hearts: Int
    var maxHearts: Int = NafsiLivesManager.fallbackCapacity
    var size: CGFloat = 18

    private var iconSize: CGFloat {
        if maxHearts > 8 { return min(size, 13) }
        if maxHearts > 5 { return min(size, 16) }
        return size
    }

    private var iconSpacing: CGFloat {
        maxHearts > 8 ? 2 : 6
    }

    var body: some View {
        HStack(spacing: iconSpacing) {
            ForEach(0..<maxHearts, id: \.self) { index in
                Image(systemName: index < hearts ? "heart.fill" : "heart")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(index < hearts ? AppTheme.statusNegative : AppTheme.textMuted.opacity(0.3))
                    .scaleEffect(index < hearts ? 1 : 0.9)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hearts)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(
                format: NSLocalizedString("nafsi.hearts.count", comment: "%d of %d hearts"),
                hearts,
                maxHearts
            )
        )
    }
}

struct BuyHeartsSheet: View {
    @ObservedObject private var lives = NafsiLivesManager.shared
    @ObservedObject private var journey = HeartJourneyManager.shared
    @Environment(\.dismiss) private var dismiss

    var onPurchased: (() -> Void)?

    var body: some View {
        NavigationView {
            ZStack {
                SDPageBackground()

                VStack(spacing: 20) {
                    NafsiHeartsRow(hearts: lives.hearts, maxHearts: lives.capacity, size: 22)
                        .padding(.top, 8)

                    Text(NSLocalizedString("nafsi.hearts.buy.title", comment: "Keep your apps open"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(String(
                        format: NSLocalizedString("nafsi.hearts.buy.body", comment: ""),
                        lives.minutesPerHeart
                    ))
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)

                    VStack(spacing: 0) {
                        walletRow(
                            icon: .coin,
                            title: NSLocalizedString("heart.xp_label", comment: "Coins"),
                            value: "\(journey.coins)"
                        )

                        Rectangle()
                            .fill(AppTheme.border.opacity(0.8))
                            .frame(height: 1)

                        walletRow(
                            icon: .heart,
                            title: NSLocalizedString("nafsi.hearts.cost", comment: "Cost per heart"),
                            value: "\(NafsiLivesManager.coinCostPerHeart)"
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.border.opacity(0.6), lineWidth: 1)
                    )

                    Button {
                        if lives.buyHeart() {
                            HapticManager.shared.success()
                            onPurchased?()
                        } else {
                            HapticManager.shared.soft()
                        }
                    } label: {
                        Text(
                            lives.hearts >= lives.capacity
                                ? NSLocalizedString("nafsi.hearts.full", comment: "Hearts full")
                                : String(
                                    format: NSLocalizedString("nafsi.hearts.buy.cta", comment: "Buy 1 heart · %d coins"),
                                    NafsiLivesManager.coinCostPerHeart
                                )
                        )
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(ActionCardButtonStyle())
                    .opacity(lives.canBuyHeart ? 1 : 0.55)
                    .disabled(!lives.canBuyHeart)

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .navigationTitle(NSLocalizedString("nafsi.hearts.buy", comment: "Buy hearts"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SDDismissButton {
                        dismiss()
                    }
                }
            }
        }
    }

    private enum WalletRowIcon {
        case coin
        case heart
    }

    private func walletRow(icon: WalletRowIcon, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            switch icon {
            case .coin:
                NafsiCoinGlyph(size: 22)
            case .heart:
                Image(systemName: "heart.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.statusNegative)
                    .frame(width: 22)
            }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .monospacedDigit()
                .overlay(alignment: .top) {
                    if icon == .coin {
                        CoinSpendFloater()
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
