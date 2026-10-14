//
//  DashboardTutorial.swift
//  scrolldeeds
//
//  First-visit skippable coach-mark tour of the live dashboard.
//  Uses Anchor preferences so spotlight frames resolve in the overlay’s
//  coordinate space (avoids ScrollView / safe-area drift).
//

import SwiftUI
import UIKit

// MARK: - Anchors & steps

enum DashboardTutorialAnchor: String, CaseIterable {
    case streak
    case week
    case heart
    case coins
    case shop
    case lockedApps
    case progress
    case navBar
    case navScroll
    case navPractice
    case navProgress
    case navHome
    case navSettings
}

struct DashboardTutorialStep: Identifiable {
    let id: Int
    let anchor: DashboardTutorialAnchor?
    let title: String
    let body: String
}

enum DashboardTutorialCatalog {
    static var steps: [DashboardTutorialStep] {
        [
            DashboardTutorialStep(
                id: 0,
                anchor: nil,
                title: NSLocalizedString("dash_tutorial.welcome.title", comment: "How Nafsi works"),
                body: NSLocalizedString("dash_tutorial.welcome.body", comment: "")
            ),
            DashboardTutorialStep(
                id: 1,
                anchor: .coins,
                title: NSLocalizedString("dash_tutorial.coins.title", comment: "Your coins"),
                body: NSLocalizedString("dash_tutorial.coins.body", comment: "")
            ),
            DashboardTutorialStep(
                id: 2,
                anchor: .heart,
                title: NSLocalizedString("dash_tutorial.heart.title", comment: "Hearts"),
                body: NSLocalizedString("dash_tutorial.heart.body", comment: "")
            ),
            DashboardTutorialStep(
                id: 3,
                anchor: .shop,
                title: NSLocalizedString("dash_tutorial.shop.title", comment: "Earn and shop"),
                body: NSLocalizedString("dash_tutorial.shop.body", comment: "")
            ),
            DashboardTutorialStep(
                id: 4,
                anchor: .lockedApps,
                title: NSLocalizedString("dash_tutorial.apps.title", comment: "Locked apps"),
                body: NSLocalizedString("dash_tutorial.apps.body", comment: "")
            ),
            DashboardTutorialStep(
                id: 5,
                anchor: .week,
                title: NSLocalizedString("dash_tutorial.week.title", comment: "This week"),
                body: NSLocalizedString("dash_tutorial.week.body", comment: "")
            ),
            DashboardTutorialStep(
                id: 6,
                anchor: .navHome,
                title: NSLocalizedString("dash_tutorial.nav_home.title", comment: "Home"),
                body: NSLocalizedString("dash_tutorial.nav_home.body", comment: "")
            ),
            DashboardTutorialStep(
                id: 7,
                anchor: .navScroll,
                title: NSLocalizedString("dash_tutorial.nav_scroll.title", comment: "Scroll"),
                body: NSLocalizedString("dash_tutorial.nav_scroll.body", comment: "")
            ),
            DashboardTutorialStep(
                id: 8,
                anchor: .navSettings,
                title: NSLocalizedString("dash_tutorial.nav_settings.title", comment: "Difficulty"),
                body: NSLocalizedString("dash_tutorial.nav_settings.body", comment: "")
            ),
            DashboardTutorialStep(
                id: 9,
                anchor: nil,
                title: NSLocalizedString("dash_tutorial.ready.title", comment: "You’re ready"),
                body: NSLocalizedString("dash_tutorial.ready.body", comment: "")
            )
        ]
    }
}

// MARK: - Preference (Anchor-based — resolves correctly in overlay)

struct TutorialAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func tutorialAnchor(_ anchor: DashboardTutorialAnchor) -> some View {
        anchorPreference(key: TutorialAnchorPreferenceKey.self, value: .bounds) {
            [anchor.rawValue: $0]
        }
    }

    /// Scroll target plus spotlight. `active` is false on the duplicate that
    /// large phones keep on the whole tools section.
    @ViewBuilder
    func dashboardTutorialTarget(_ anchor: DashboardTutorialAnchor, active: Bool) -> some View {
        if active {
            self.id(anchor.rawValue).tutorialAnchor(anchor)
        } else {
            self
        }
    }
}

enum DashboardTutorialLayout {
    /// SE, 13 mini, and regular 6.1" phones. Taller phones keep the roomy tour.
    static var isCompactPhone: Bool { UIScreen.main.bounds.height < 860 }
}

// MARK: - Overlay

private enum TutorialTipSlot: Equatable {
    case below(offsetY: CGFloat)
    case above(bottomInset: CGFloat)
    case centered
}

struct DashboardTutorialOverlay: View {
    let anchors: [String: Anchor<CGRect>]
    let onSkip: () -> Void
    let onFinish: () -> Void
    var onStepChange: ((DashboardTutorialStep) -> Void)? = nil

    @State private var stepIndex = 0
    @State private var appeared = false
    @State private var tipHeight: CGFloat = 260

    private var steps: [DashboardTutorialStep] { DashboardTutorialCatalog.steps }
    private var step: DashboardTutorialStep { steps[stepIndex] }
    private var isLast: Bool { stepIndex >= steps.count - 1 }

    private let tipGap: CGFloat = 18
    private let edgeMargin: CGFloat = 20
    private var isCompactHeight: Bool { DashboardTutorialLayout.isCompactPhone }

    var body: some View {
        GeometryReader { geo in
            let insets = Self.windowSafeArea
            let hole = resolvedHole(in: geo)
            let bottomSafe = chromeBottom(in: geo, size: geo.size, bottomInset: insets.bottom)
            let slot = tipSlot(
                hole: hole,
                size: geo.size,
                topSafe: insets.top + 10,
                bottomSafe: bottomSafe
            )

            ZStack {
                dimLayer(hole: hole, size: geo.size)
                    .allowsHitTesting(true)

                if let hole {
                    holeRing(hole: hole)
                        .allowsHitTesting(false)
                }

                tipStack(
                    slot: slot,
                    width: geo.size.width,
                    bottomSafe: bottomSafe
                )
                    .opacity(appeared ? 1 : 0)
            }
        }
        .ignoresSafeArea()
        .onPreferenceChange(TutorialTipHeightKey.self) { tipHeight = $0 }
        .onAppear {
            withAnimation(.easeOut(duration: 0.28)) { appeared = true }
            onStepChange?(step)
        }
        .onChange(of: stepIndex) { _ in
            HapticManager.shared.soft()
            onStepChange?(step)
        }
        .accessibilityElement(children: .contain)
    }

    private func tipStack(slot: TutorialTipSlot, width: CGFloat, bottomSafe: CGFloat) -> some View {
        let card = tipCard(maxWidth: min(width - edgeMargin * 2, 360))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, edgeMargin)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: TutorialTipHeightKey.self, value: proxy.size.height)
                }
            )

        return VStack(spacing: 0) {
            switch slot {
            case .below(let offsetY):
                // On a short phone a tall spotlight pushes this offset past the
                // tab bar and clips the Next button. Keep the whole card on screen.
                let height = tipHeight > 1 ? tipHeight : 260
                let maxOffset = max(0, bottomSafe - height - 8)
                let resolved = isCompactHeight ? min(offsetY, maxOffset) : offsetY
                Color.clear.frame(height: max(0, resolved))
                card
                Spacer(minLength: 0)
            case .above(let bottomInset):
                Spacer(minLength: 0)
                card
                Color.clear.frame(height: max(0, bottomInset))
            case .centered:
                Spacer(minLength: 0)
                card
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: Spotlight

    private func holePadding(for anchor: DashboardTutorialAnchor) -> (dx: CGFloat, dy: CGFloat) {
        switch anchor {
        case .streak, .coins: return (4, 3)
        case .week: return (8, 6)
        case .heart, .shop, .lockedApps, .progress: return (6, 6)
        case .navHome: return (7, 7)
        case .navScroll, .navPractice, .navProgress, .navSettings, .navBar:
            return (5, 6)
        }
    }

    private func holeCorner(for hole: CGRect) -> CGFloat {
        switch step.anchor {
        case .streak, .coins, .navHome:
            return min(hole.width, hole.height) / 2
        case .week:
            return 16
        case .heart, .shop, .lockedApps, .progress:
            return 20
        case .navScroll, .navPractice, .navProgress, .navSettings, .navBar:
            return 14
        case nil:
            return 16
        }
    }

    private func resolvedHole(in geo: GeometryProxy) -> CGRect? {
        guard let key = step.anchor?.rawValue, let anchor = anchors[key] else { return nil }
        let raw = geo[anchor]
        guard raw.width > 2, raw.height > 2, !raw.isNull, raw.isFinite else { return nil }

        let pad = holePadding(for: step.anchor ?? .week)
        var hole = raw.insetBy(dx: -pad.dx, dy: -pad.dy)

        let bounds = CGRect(origin: .zero, size: geo.size).insetBy(dx: 10, dy: 10)
        hole = hole.intersection(bounds)
        guard hole.width > 8, hole.height > 8 else { return nil }
        return hole
    }

    private func holeRing(hole: CGRect) -> some View {
        let corner = holeCorner(for: hole)
        return RoundedRectangle(cornerRadius: corner, style: .continuous)
            .stroke(Color.white.opacity(0.95), lineWidth: 2)
            .shadow(color: AppTheme.primary.opacity(0.35), radius: 8)
            .frame(width: hole.width, height: hole.height)
            .position(x: hole.midX, y: hole.midY)
    }

    @ViewBuilder
    private func dimLayer(hole: CGRect?, size: CGSize) -> some View {
        let corner = hole.map { holeCorner(for: $0) } ?? 16
        Canvas { context, canvasSize in
            var path = Path(CGRect(origin: .zero, size: canvasSize))
            if let hole {
                path.addRoundedRect(
                    in: hole,
                    cornerSize: CGSize(width: corner, height: corner)
                )
            }
            context.fill(
                path,
                with: .color(Color.black.opacity(0.32)),
                style: FillStyle(eoFill: true)
            )
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: Tip slot — pin the card edge, never cover the spotlight

    private func chromeBottom(in geo: GeometryProxy, size: CGSize, bottomInset: CGFloat) -> CGFloat {
        var top = size.height - bottomInset - 64
        if let anchor = anchors[DashboardTutorialAnchor.navHome.rawValue] {
            let rect = geo[anchor]
            if rect.height > 8 { top = min(top, rect.minY) }
        }
        if let anchor = anchors[DashboardTutorialAnchor.navBar.rawValue] {
            let rect = geo[anchor]
            if rect.height > 8 { top = min(top, rect.minY) }
        }
        return top - 12
    }

    private func tipSlot(
        hole: CGRect?,
        size: CGSize,
        topSafe: CGFloat,
        bottomSafe: CGFloat
    ) -> TutorialTipSlot {
        guard let hole else { return .centered }

        let belowTop = max(topSafe, hole.maxY + tipGap)
        let aboveBottom = min(bottomSafe, hole.minY - tipGap)
        let roomBelow = bottomSafe - belowTop
        let roomAbove = aboveBottom - topSafe
        let preferAbove = hole.minY > size.height * 0.52
        let preferBelow = hole.maxY < size.height * 0.42

        if preferAbove, roomAbove > 96 {
            return .above(bottomInset: size.height - aboveBottom)
        }
        if preferBelow, roomBelow > 96 {
            return .below(offsetY: belowTop)
        }
        if roomBelow >= roomAbove, roomBelow > 96 {
            return .below(offsetY: belowTop)
        }
        if roomAbove > 96 {
            return .above(bottomInset: size.height - aboveBottom)
        }
        if roomBelow > roomAbove {
            return .below(offsetY: belowTop)
        }
        return .above(bottomInset: size.height - aboveBottom)
    }

    private static var windowSafeArea: UIEdgeInsets {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first
        return window?.safeAreaInsets ?? UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)
    }

    // MARK: Card

    private func tipCard(maxWidth: CGFloat) -> some View {
        let compact = isCompactHeight
        return VStack(alignment: .leading, spacing: compact ? 6 : 12) {
            HStack(spacing: 8) {
                Text("\(stepIndex + 1)/\(steps.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primary)

                Spacer(minLength: 0)

                Button {
                    HapticManager.shared.soft()
                    onSkip()
                } label: {
                    Text(NSLocalizedString("dash_tutorial.skip", comment: "Skip"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 2)
                }
            }

            Text(step.title)
                .font(.system(size: compact ? 17 : 20, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(step.body)
                .font(.system(size: compact ? 13.5 : 15, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(compact ? 2 : 3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if stepIndex > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            stepIndex -= 1
                        }
                    } label: {
                        Text(NSLocalizedString("dash_tutorial.back", comment: "Back"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: compact ? 40 : 46)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppTheme.muted)
                            )
                    }
                }

                Button {
                    if isLast {
                        HapticManager.shared.success()
                        onFinish()
                    } else {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            stepIndex += 1
                        }
                    }
                } label: {
                    Text(
                        isLast
                            ? NSLocalizedString("dash_tutorial.done", comment: "Got it")
                            : NSLocalizedString("dash_tutorial.next", comment: "Next")
                    )
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, compact ? 10 : 13)
                }
                .buttonStyle(ActionCardButtonStyle(depth: 4))
            }
        }
        .padding(compact ? 12 : 18)
        .frame(maxWidth: maxWidth)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: .black.opacity(0.10), radius: 18, y: 6)
        )
    }
}

private struct TutorialTipHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension CGRect {
    var isFinite: Bool {
        origin.x.isFinite && origin.y.isFinite && size.width.isFinite && size.height.isFinite
    }
}
