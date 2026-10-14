import SwiftUI

// MARK: - Heart Health (0...100)
// Compact onboarding demo still uses this unlock-budget scale.

struct HeartHealth {

    static func current(
        isUnlockActive: Bool,
        unlockBudgetMinutes: Int,
        spentMinutes: Int
    ) -> Double {
        guard isUnlockActive else { return 0 }

        let budget = max(0, unlockBudgetMinutes)
        guard budget > 0 else { return 100 }

        let spent = min(max(0, spentMinutes), budget)
        let remaining = Double(budget - spent)
        let pct = (remaining / Double(budget)) * 100
        return min(100, max(0, pct))
    }
}

// MARK: - Heart Hero

struct HeartHeroView: View {
    @ObservedObject private var journey = HeartJourneyManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    var playUnlockFill: Bool = false
    var onUnlockFillPlayed: (() -> Void)? = nil
    var onWelcomeFinished: (() -> Void)? = nil
    var isUnlocked: Bool = false
    var unlockLabel: String = ""

    @State private var displayedXP: Double = 0
    @State private var beatScale: CGFloat = 1
    @State private var glowBoost: Double = 0
    @State private var bonusAmount: Int = 0
    @State private var bonusOpacity: Double = 0
    @State private var bonusScale: CGFloat = 0.86
    /// -1 he draws the heart in, 0 rest, 1 the heart answers and he rises.
    @State private var reaction: Double = 0
    @State private var didStartWelcome = false
    @State private var isPlayingDeedUpgrade = false
    @State private var barReceiving = false
    /// During a rank-up: keep showing the old rank while the bar hits full, then flip.
    @State private var rankHold: HeartRank? = nil
    @State private var holdingFullBar = false
    @State private var heldFill: Double = 0

    private var displayedXPInt: Int { max(0, Int(displayedXP.rounded())) }
    private var displayedRank: HeartRank { rankHold ?? HeartRank.from(xp: displayedXPInt) }
    private var displayedStage: HeartVisualStage {
        if holdingFullBar, let rankHold {
            return .filling(rankHold, piece: HeartVisualStage.step(forFill: heldFill, rank: rankHold))
        }
        return HeartVisualStage.from(xp: displayedXPInt)
    }
    private var displayedStart: Int { displayedRank.startXP(totalXP: displayedXPInt) }
    private var displayedNext: Int { displayedRank.nextThreshold(totalXP: displayedXPInt) }

    private var displayedFill: Double {
        if holdingFullBar { return heldFill }
        let start = Double(displayedStart)
        let next = Double(displayedNext)
        guard next > start else { return 1 }
        return min(1, max(0, (displayedXP - start) / (next - start)))
    }

    var body: some View {
        ZStack {
            NafsiHeroCard(
                stage: NafsiStage(rank: displayedRank),
                progress: displayedFill,
                totalXP: holdingFullBar ? displayedNext : displayedXPInt,
                nextXP: displayedNext,
                status: heroStatus,
                isUnlocked: isUnlocked,
                unlockLabel: unlockLabel,
                barPulse: barReceiving,
                mascotScale: beatScale,
                glowBoost: glowBoost,
                reaction: reaction,
                reportsFlyTarget: true
            )
            .animation(.easeInOut(duration: 0.6), value: displayedRank)

            if bonusOpacity > 0.01 {
                    Text(String(
                        format: NSLocalizedString("heart.welcome.bonus", comment: "+%d XP"),
                        bonusAmount
                    ))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.primary)
                            .shadow(color: AppTheme.primary.opacity(0.35), radius: 12, y: 4)
                    )
                    .scaleEffect(bonusScale)
                    .opacity(bonusOpacity)
                    .offset(y: -30)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .id(languageManager.currentLanguage)
        .onAppear {
            if journey.isPlayingWelcome {
                displayedXP = 0
                if journey.welcomePhase == .collecting {
                    playWelcomeFill()
                }
            } else if playUnlockFill {
                rewindAndPlayDeedUpgrade()
            } else {
                displayedXP = Double(journey.totalXP)
            }
        }
        .onChange(of: journey.isPlayingWelcome) { playing in
            if playing { displayedXP = 0 }
        }
        .onChange(of: journey.welcomePhase) { phase in
            if phase == .collecting { playWelcomeFill() }
        }
        .onChange(of: journey.totalXP) { newValue in
            guard !journey.isPlayingWelcome, !didStartWelcome else { return }
            playDeedUpgrade(to: newValue, from: displayedXPInt)
        }
        .onChange(of: playUnlockFill) { play in
            if play { rewindAndPlayDeedUpgrade() }
        }
    }

    private var accessibilityText: String {
        let rankName = NSLocalizedString(displayedRank.localizationKey, comment: "")
        let xpLabel = NSLocalizedString("heart.xp_label", comment: "XP")
        return "\(rankName), \(displayedXPInt) \(xpLabel)"
    }

    private var heroStatus: NafsiHeroStatus {
        if isUnlocked {
            return NafsiHeroStatus(
                kicker: NSLocalizedString("nafsi.hero.kicker_unlocked", comment: "Good job"),
                title: NSLocalizedString("nafsi.hero.title_unlocked", comment: "You're in control."),
                subtitle: NSLocalizedString("nafsi.hero.subtitle_unlocked", comment: "Every good choice strengthens your heart.")
            )
        }
        return NafsiHeroStatus(
            kicker: NSLocalizedString("nafsi.hero.kicker_locked", comment: "Your heart"),
            title: NSLocalizedString("nafsi.hero.title_locked", comment: "Protect your heart."),
            subtitle: NSLocalizedString("nafsi.hero.subtitle_locked", comment: "One good deed opens your apps.")
        )
    }

    private func rewindAndPlayDeedUpgrade() {
        onUnlockFillPlayed?()
        guard !isPlayingDeedUpgrade else { return }
        let to = journey.totalXP
        let from = max(0, to - HeartJourneyManager.deedXP)
        var snap = Transaction()
        snap.disablesAnimations = true
        withTransaction(snap) {
            displayedXP = Double(from)
        }
        DispatchQueue.main.async {
            self.playDeedUpgrade(to: to, from: from)
        }
    }

    private func playDeedUpgrade(to xp: Int, from: Int) {
        guard !isPlayingDeedUpgrade else { return }
        guard xp != from else {
            displayedXP = Double(xp)
            return
        }
        isPlayingDeedUpgrade = true

        let fromRank = HeartRank.from(xp: from)
        let toRank = HeartRank.from(xp: xp)
        let rankUp = toRank > fromRank
        let fromFill = HeartRank.fillProgress(xp: from)

        bonusAmount = max(0, xp - from)
        rankHold = nil
        holdingFullBar = false
        reaction = 0

        HapticManager.shared.heartBarFilling(completed: rankUp)

        // He draws the heart in before it answers.
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            bonusOpacity = 1
            bonusScale = 1
            beatScale = 0.92
            glowBoost = 0.04
            reaction = -1
            barReceiving = true
        }

        let answerAt: TimeInterval = rankUp ? 0.62 : 0.32

        if rankUp {
            rankHold = fromRank
            heldFill = fromFill
            holdingFullBar = true
            withAnimation(.timingCurve(0.22, 0.82, 0.28, 1, duration: 0.55)) {
                heldFill = 1
            }
        } else {
            withAnimation(.timingCurve(0.22, 0.82, 0.28, 1, duration: 0.9)) {
                displayedXP = Double(xp)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + answerAt) {
            if rankUp {
                HapticManager.shared.heartUnlockFill(rankUp: true, pieceChanged: true)
            }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                if rankUp {
                    holdingFullBar = false
                    rankHold = nil
                    displayedXP = Double(xp)
                }
                beatScale = rankUp ? 1.08 : 1.04
                glowBoost = rankUp ? 0.55 : 0.4
                reaction = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + answerAt + 0.85) {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.86)) {
                beatScale = 1
                glowBoost = 0
                reaction = 0
                barReceiving = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + answerAt + 0.85) {
            withAnimation(.easeOut(duration: 0.28)) {
                bonusOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + answerAt + 1.35) {
            bonusScale = 0.86
            rankHold = nil
            holdingFullBar = false
            reaction = 0
            isPlayingDeedUpgrade = false
            displayedXP = Double(journey.totalXP)
        }
    }

    private func playWelcomeFill() {
        guard !didStartWelcome else { return }
        didStartWelcome = true
        bonusOpacity = 0
        reaction = 0

        var snap = Transaction()
        snap.disablesAnimations = true
        withTransaction(snap) {
            displayedXP = 0
            barReceiving = false
            beatScale = 1
            glowBoost = 0
        }

        HapticManager.shared.heartBarFilling(completed: true)

        withAnimation(.easeOut(duration: 0.2)) {
            barReceiving = true
            glowBoost = 0.16
        }

        withAnimation(.timingCurve(0.22, 0.8, 0.28, 1, duration: 1.05)) {
            displayedXP = Double(HeartJourneyManager.welcomeBonusXP)
            beatScale = 1.05
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.62)) {
                beatScale = 1.1
                glowBoost = 0.45
                reaction = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                beatScale = 1
                glowBoost = 0
                reaction = 0
                barReceiving = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            reaction = 0
            journey.endWelcome()
            didStartWelcome = false
            displayedXP = Double(journey.totalXP)
            onWelcomeFinished?()
        }
    }
}

struct HeartXPBar: View {
    let progress: Double
    let rank: HeartRank
    let totalXP: Int
    let nextRankAt: Int
    var pulse: Bool = false
    var reportsFlyTarget: Bool = false
    @ObservedObject private var languageManager = LanguageManager.shared

    private var clamped: Double { min(1, max(0, progress)) }
    private let barHeight: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(NSLocalizedString(rank.localizationKey, comment: ""))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text("\(totalXP) / \(nextRankAt) \(NSLocalizedString("heart.xp_label", comment: "XP"))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .monospacedDigit()
            }
            .id(languageManager.currentLanguage)

            GeometryReader { geo in
                let fillWidth = max(clamped < 0.02 ? 0 : barHeight, geo.size.width * CGFloat(clamped))

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(AppTheme.textMuted.opacity(0.16))

                    Capsule(style: .continuous)
                        .fill(barColor)
                        .frame(width: fillWidth)
                        .animation(.spring(response: 0.72, dampingFraction: 0.84), value: clamped)
                        .animation(.easeInOut(duration: 0.35), value: rank)

                    if pulse {
                        Capsule(style: .continuous)
                            .stroke(barColor.opacity(0.7), lineWidth: 2)
                            .blur(radius: 0.4)
                    }
                }
                .background(
                    GeometryReader { barGeo in
                        Color.clear.preference(
                            key: HeartXPBarFrameKey.self,
                            value: reportsFlyTarget ? barGeo.frame(in: .global) : .zero
                        )
                    }
                )
            }
            .frame(height: barHeight)

            Text(String(
                format: NSLocalizedString("heart.xp_to_next", comment: "%d XP to %@"),
                max(0, nextRankAt - totalXP),
                NSLocalizedString(nextRankNameKey, comment: "")
            ))
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(AppTheme.textMuted)
        }
        .scaleEffect(pulse ? 1.055 : 1)
        .shadow(color: barColor.opacity(pulse ? 0.42 : 0), radius: pulse ? 14 : 0, y: 0)
        .animation(.spring(response: 0.42, dampingFraction: 0.62), value: pulse)
    }

    private var barColor: Color {
        switch rank {
        case .spark: return AppTheme.primary
        case .bronze: return Color(red: 0.78, green: 0.52, blue: 0.22)
        case .silver: return Color(red: 0.62, green: 0.68, blue: 0.76)
        case .gold: return AppTheme.accent
        case .diamond: return Color(red: 0.36, green: 0.66, blue: 0.86)
        case .emerald: return AppTheme.primary
        }
    }

    private var nextRankNameKey: String {
        switch rank {
        case .spark: return "heart.rank.bronze"
        case .bronze: return "heart.rank.silver"
        case .silver: return "heart.rank.gold"
        case .gold: return "heart.rank.diamond"
        case .diamond, .emerald: return "heart.rank.emerald"
        }
    }
}

extension HeartRank {
    var badgeMetal: Color {
        switch self {
        case .spark: return Color(red: 0.62, green: 0.64, blue: 0.63)
        case .bronze: return Color(red: 0.78, green: 0.52, blue: 0.22)
        case .silver: return Color(red: 0.72, green: 0.76, blue: 0.82)
        case .gold: return Color(red: 0.85, green: 0.66, blue: 0.22)
        case .diamond: return Color(red: 0.35, green: 0.78, blue: 0.62)
        case .emerald: return Color(red: 0.16, green: 0.60, blue: 0.40)
        }
    }

    var badgeMetalHighlight: Color {
        switch self {
        case .spark: return Color(red: 0.86, green: 0.88, blue: 0.87)
        case .bronze: return Color(red: 0.93, green: 0.74, blue: 0.45)
        case .silver: return Color.white
        case .gold: return Color(red: 1.0, green: 0.90, blue: 0.55)
        case .diamond: return Color(red: 0.78, green: 1.0, blue: 0.90)
        case .emerald: return Color(red: 0.62, green: 0.92, blue: 0.74)
        }
    }

    var badgeMetalShadow: Color {
        switch self {
        case .spark: return Color(red: 0.40, green: 0.42, blue: 0.41)
        case .bronze: return Color(red: 0.42, green: 0.24, blue: 0.08)
        case .silver: return Color(red: 0.42, green: 0.46, blue: 0.52)
        case .gold: return Color(red: 0.48, green: 0.32, blue: 0.06)
        case .diamond: return Color(red: 0.10, green: 0.38, blue: 0.28)
        case .emerald: return Color(red: 0.05, green: 0.28, blue: 0.18)
        }
    }
}

/// Heraldic shield — the plate of a real badge, not a circle.
struct HeartBadgeShield: InsettableShape {
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> HeartBadgeShield {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let w = r.width
        let h = r.height
        let x = r.minX
        let y = r.minY
        let corner = min(w, h) * 0.13

        var p = Path()
        p.move(to: CGPoint(x: x + corner, y: y))
        p.addLine(to: CGPoint(x: x + w - corner, y: y))
        p.addQuadCurve(
            to: CGPoint(x: x + w, y: y + corner),
            control: CGPoint(x: x + w, y: y)
        )
        p.addLine(to: CGPoint(x: x + w, y: y + h * 0.55))
        p.addCurve(
            to: CGPoint(x: x + w * 0.5, y: y + h),
            control1: CGPoint(x: x + w, y: y + h * 0.76),
            control2: CGPoint(x: x + w * 0.76, y: y + h * 0.93)
        )
        p.addCurve(
            to: CGPoint(x: x, y: y + h * 0.55),
            control1: CGPoint(x: x + w * 0.24, y: y + h * 0.93),
            control2: CGPoint(x: x, y: y + h * 0.76)
        )
        p.addLine(to: CGPoint(x: x, y: y + corner))
        p.addQuadCurve(
            to: CGPoint(x: x + corner, y: y),
            control: CGPoint(x: x, y: y)
        )
        p.closeSubpath()
        return p
    }
}

/// Swallowtail banner that sits across the badge.
struct HeartBadgeRibbon: Shape {
    func path(in rect: CGRect) -> Path {
        let notch = min(rect.height * 0.48, rect.width * 0.08)
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width - notch, y: rect.height / 2))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: notch, y: rect.height / 2))
        p.closeSubpath()
        return p
    }
}

/// Shield badge that keeps each rank's chrome, then adds a little more with every deed.
struct HeartBadgeView: View {
    let xp: Int
    var glowBoost: Double = 0
    @ObservedObject private var languageManager = LanguageManager.shared

    private var rank: HeartRank { HeartRank.from(xp: xp) }
    private var stage: NafsiStage { NafsiStage(rank: rank) }
    private var filledDots: Int { HeartRank.deedsIntoRank(xp: xp) }
    private var deedsNeeded: Int { max(1, rank.deedsRequired) }
    private var dotSize: CGFloat {
        switch deedsNeeded {
        case ...3: return 9
        case ...6: return 7
        case ...9: return 6
        default: return 5
        }
    }
    private var dotSpacing: CGFloat {
        switch deedsNeeded {
        case ...3: return 8
        case ...6: return 5
        default: return 3.5
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                characterArt
                    .frame(maxWidth: .infinity)
                    .frame(height: 248)
                    .clipped()

                LinearGradient(
                    colors: [AppTheme.background.opacity(0), AppTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 56)
                .allowsHitTesting(false)

                rankRibbon
                    .padding(.bottom, 4)
            }

            HStack(spacing: dotSpacing) {
                ForEach(1...deedsNeeded, id: \.self) { mark in
                    Circle()
                        .fill(filledDots >= mark ? stage.accent : AppTheme.textMuted.opacity(0.22))
                        .overlay(
                            Circle()
                                .stroke(stage.accentLight.opacity(filledDots >= mark ? 0.55 : 0), lineWidth: 0.8)
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(
                            color: filledDots >= mark ? stage.accent.opacity(0.45) : .clear,
                            radius: 2
                        )
                }
            }
            .padding(.bottom, 2)
        }
        .id(languageManager.currentLanguage)
        .animation(.easeInOut(duration: 0.35), value: filledDots)
        .animation(.easeInOut(duration: 0.35), value: rank)
    }

    @ViewBuilder
    private var characterArt: some View {
        if stage.hasSceneArt {
            Image(stage.sceneImageName)
                .resizable()
                .scaledToFit()
                .shadow(color: stage.accent.opacity(0.22 + glowBoost * 0.2), radius: 18, y: 8)
        } else {
            NafsiMascotView(stage: stage, glowBoost: glowBoost)
                .shadow(color: stage.accent.opacity(0.22 + glowBoost * 0.2), radius: 18, y: 8)
        }
    }

    private var rankRibbon: some View {
        Text(NSLocalizedString(rank.localizationKey, comment: "").uppercased())
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .tracking(0.8)
            .foregroundColor(ribbonTextColor)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [stage.accentLight, stage.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: stage.accent.opacity(0.35), radius: 8, y: 3)
            )
    }

    private var ribbonTextColor: Color {
        switch rank {
        case .spark, .silver: return rank.badgeMetalShadow
        default: return .white
        }
    }
}

private struct HeartBadgeOrnaments: View {
    let rank: HeartRank
    let filledDots: Int

    private var showBail: Bool { rank >= .bronze }
    private var showTopRivets: Bool { rank >= .bronze }
    private var showSideRivets: Bool { rank >= .silver || (rank == .bronze && filledDots >= 2) }
    private var showBeads: Bool { rank >= .silver }
    private var showJewel: Bool { rank >= .silver }
    private var showScrolls: Bool { rank >= .silver }
    private var showCrest: Bool { rank >= .gold }
    private var showLaurel: Bool { rank >= .gold }
    private var showTipJewel: Bool { rank >= .gold }
    private var showGlints: Bool { rank >= .diamond }

    private var jewelSize: CGFloat {
        switch rank {
        case .spark, .bronze: return 10
        case .silver: return filledDots >= 2 ? 13 : 11
        case .gold: return filledDots >= 2 ? 16 : 14
        case .diamond, .emerald: return 17
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                if showBail {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [rank.badgeMetalHighlight, rank.badgeMetal, rank.badgeMetalShadow],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(Capsule().stroke(rank.badgeMetalShadow.opacity(0.4), lineWidth: 0.6))
                        .frame(width: rank >= .gold ? 28 : 20, height: rank >= .gold ? 9 : 7)
                        .position(x: w * 0.5, y: h * 0.024)
                }

                if showCrest {
                    HeartBadgeCrest()
                        .fill(
                            LinearGradient(
                                colors: [rank.badgeMetalHighlight, rank.badgeMetal],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 28, height: 14)
                        .position(x: w * 0.5, y: h * 0.052)
                }

                if showTopRivets {
                    HeartBadgeRivet(rank: rank)
                        .position(x: w * 0.175, y: h * 0.20)
                    HeartBadgeRivet(rank: rank)
                        .position(x: w * 0.825, y: h * 0.20)
                }
                if showSideRivets {
                    HeartBadgeRivet(rank: rank)
                        .position(x: w * 0.12, y: h * 0.45)
                    HeartBadgeRivet(rank: rank)
                        .position(x: w * 0.88, y: h * 0.45)
                }
                if rank == .diamond {
                    HeartBadgeRivet(rank: rank)
                        .position(x: w * 0.22, y: h * 0.68)
                    HeartBadgeRivet(rank: rank)
                        .position(x: w * 0.78, y: h * 0.68)
                }

                if showBeads {
                    ForEach(Array(beadPoints(w: w, h: h).enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(rank.badgeMetalHighlight)
                            .overlay(Circle().stroke(rank.badgeMetalShadow.opacity(0.45), lineWidth: 0.5))
                            .frame(width: rank >= .gold ? 5 : 4, height: rank >= .gold ? 5 : 4)
                            .position(point)
                    }
                }

                if showJewel {
                    HeartBadgeJewel(rank: rank, size: jewelSize)
                        .position(x: w * 0.5, y: showCrest ? h * 0.105 : h * 0.086)
                }

                if showScrolls {
                    HeartBadgeScroll(flipped: false)
                        .stroke(rank.badgeMetal.opacity(0.82), lineWidth: rank >= .gold ? 1.7 : 1.35)
                        .frame(width: w * (rank >= .gold ? 0.24 : 0.20), height: h * (rank >= .gold ? 0.24 : 0.20))
                        .position(x: w * 0.155, y: h * 0.32)
                    HeartBadgeScroll(flipped: true)
                        .stroke(rank.badgeMetal.opacity(0.82), lineWidth: rank >= .gold ? 1.7 : 1.35)
                        .frame(width: w * (rank >= .gold ? 0.24 : 0.20), height: h * (rank >= .gold ? 0.24 : 0.20))
                        .position(x: w * 0.845, y: h * 0.32)
                }

                if showLaurel {
                    HeartBadgeLaurel(flipped: false)
                        .stroke(rank.badgeMetal, lineWidth: 1.5)
                        .frame(width: w * 0.28, height: h * 0.30)
                        .position(x: w * 0.22, y: h * 0.74)
                    HeartBadgeLaurel(flipped: true)
                        .stroke(rank.badgeMetal, lineWidth: 1.5)
                        .frame(width: w * 0.28, height: h * 0.30)
                        .position(x: w * 0.78, y: h * 0.74)
                }

                if showTipJewel {
                    HeartBadgeJewel(rank: rank, size: rank == .diamond ? 10 : 8)
                        .position(x: w * 0.5, y: h * 0.90)
                }

                if showGlints {
                    Circle()
                        .fill(Color.white.opacity(0.62))
                        .frame(width: 4, height: 4)
                        .position(x: w * 0.33, y: h * 0.16)
                    Circle()
                        .fill(Color.white.opacity(0.48))
                        .frame(width: 3, height: 3)
                        .position(x: w * 0.68, y: h * 0.21)
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 2.5, height: 2.5)
                        .position(x: w * 0.58, y: h * 0.12)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func beadPoints(w: CGFloat, h: CGFloat) -> [CGPoint] {
        var points: [CGPoint] = [
            CGPoint(x: w * 0.30, y: h * 0.10),
            CGPoint(x: w * 0.70, y: h * 0.10),
            CGPoint(x: w * 0.08, y: h * 0.32),
            CGPoint(x: w * 0.92, y: h * 0.32),
            CGPoint(x: w * 0.10, y: h * 0.58),
            CGPoint(x: w * 0.90, y: h * 0.58)
        ]
        if rank >= .gold {
            points.append(contentsOf: [
                CGPoint(x: w * 0.26, y: h * 0.82),
                CGPoint(x: w * 0.74, y: h * 0.82)
            ])
        }
        return points
    }
}

private struct HeartBadgeRibbonTab: Shape {
    var leading: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        if leading {
            p.move(to: CGPoint(x: rect.width * 0.42, y: 0))
            p.addLine(to: CGPoint(x: rect.width, y: 0))
            p.addLine(to: CGPoint(x: rect.width * 0.58, y: rect.height))
            p.addLine(to: CGPoint(x: 0, y: rect.height * 0.62))
        } else {
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: rect.width * 0.58, y: 0))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.62))
            p.addLine(to: CGPoint(x: rect.width * 0.42, y: rect.height))
        }
        p.closeSubpath()
        return p
    }
}

private struct HeartBadgeRivet: View {
    let rank: HeartRank

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [rank.badgeMetalHighlight, rank.badgeMetal, rank.badgeMetalShadow],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 7
                )
            )
            .frame(width: rank >= .gold ? 11 : 10, height: rank >= .gold ? 11 : 10)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 3, height: 3)
                    .offset(x: -1.4, y: -1.4)
            )
            .overlay(Circle().stroke(rank.badgeMetalShadow.opacity(0.45), lineWidth: 0.7))
    }
}

private struct HeartBadgeJewel: View {
    let rank: HeartRank
    var size: CGFloat = 8

    private var gem: Color {
        switch rank {
        case .spark: return rank.badgeMetalHighlight
        case .bronze: return Color(red: 0.72, green: 0.28, blue: 0.18)
        case .silver: return Color(red: 0.55, green: 0.70, blue: 0.82)
        case .gold: return Color(red: 0.78, green: 0.18, blue: 0.22)
        case .diamond: return Color(red: 0.28, green: 0.72, blue: 0.55)
        case .emerald: return Color(red: 0.12, green: 0.55, blue: 0.36)
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1.6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.9), gem, gem.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 1.6, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.7)
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: size * 0.26, height: size * 0.26)
                .offset(x: -size * 0.16, y: -size * 0.16)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(45))
        .shadow(color: gem.opacity(0.5), radius: 2.4)
    }
}

private struct HeartBadgeScroll: Shape {
    var flipped: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let s: CGFloat = flipped ? -1 : 1
        let midX = rect.midX
        p.move(to: CGPoint(x: midX + s * rect.width * 0.08, y: rect.minY))
        p.addCurve(
            to: CGPoint(x: midX - s * rect.width * 0.42, y: rect.midY),
            control1: CGPoint(x: midX + s * rect.width * 0.48, y: rect.minY + rect.height * 0.08),
            control2: CGPoint(x: midX + s * rect.width * 0.38, y: rect.midY - rect.height * 0.28)
        )
        p.addCurve(
            to: CGPoint(x: midX + s * rect.width * 0.06, y: rect.maxY),
            control1: CGPoint(x: midX - s * rect.width * 0.55, y: rect.midY + rect.height * 0.28),
            control2: CGPoint(x: midX + s * rect.width * 0.42, y: rect.maxY - rect.height * 0.06)
        )
        return p
    }
}

private struct HeartBadgeCrest: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.52))
        p.addLine(to: CGPoint(x: rect.width * 0.33, y: rect.height * 0.72))
        p.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.width * 0.67, y: rect.height * 0.72))
        p.addLine(to: CGPoint(x: rect.width * 0.82, y: rect.height * 0.52))
        p.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct HeartBadgeLaurel: Shape {
    var flipped: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let s: CGFloat = flipped ? -1 : 1
        let stemX = flipped ? rect.maxX * 0.78 : rect.minX + rect.width * 0.22
        p.move(to: CGPoint(x: stemX, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.midX + s * rect.width * 0.08, y: rect.maxY),
            control: CGPoint(x: stemX - s * rect.width * 0.12, y: rect.midY)
        )
        for t in [0.22, 0.48, 0.74] as [CGFloat] {
            let y = rect.minY + rect.height * t
            let base = CGPoint(x: stemX - s * rect.width * 0.04, y: y)
            p.move(to: base)
            p.addQuadCurve(
                to: CGPoint(x: stemX + s * rect.width * 0.42, y: y + rect.height * 0.02),
                control: CGPoint(x: stemX + s * rect.width * 0.18, y: y - rect.height * 0.10)
            )
            p.addQuadCurve(
                to: base,
                control: CGPoint(x: stemX + s * rect.width * 0.18, y: y + rect.height * 0.10)
            )
        }
        return p
    }
}

struct HeartStageImage: View {
    let xp: Int

    private var imageName: String { HeartVisualStage.from(xp: xp).imageName }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .id(imageName)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 1.04)),
                removal: .opacity
            ))
    }
}

/// Compact heart used in onboarding demos.
struct CompactHeartView: View {
    let health: Double
    var beatScale: CGFloat = 1

    private var t: Double { min(max(health / 100, 0), 1) }

    var body: some View {
        ZStack {
            Image("HeartWeak")
                .resizable()
                .scaledToFit()
                .opacity(1 - t * t * (3 - 2 * t))

            Image("HeartHealthy")
                .resizable()
                .scaledToFit()
                .opacity(t * t * (3 - 2 * t))
                .blendMode(.multiply)
        }
        .compositingGroup()
        .scaleEffect(beatScale)
    }
}
