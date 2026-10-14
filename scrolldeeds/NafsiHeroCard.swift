//
//  NafsiHeroCard.swift
//  scrolldeeds
//
//  Dashboard hero: the mascot in its stage scene, the stage ladder and XP progress.
//  Pure presentation; HeartHeroView owns the XP animation state and passes it in.
//

import SwiftUI

struct NafsiHeroStatus {
    let kicker: String
    let title: String
    let subtitle: String
}

struct NafsiHeroCard: View {
    let stage: NafsiStage
    let progress: Double
    let totalXP: Int
    let nextXP: Int
    let status: NafsiHeroStatus
    let isUnlocked: Bool
    let unlockLabel: String
    var barPulse: Bool = false
    var mascotScale: CGFloat = 1
    var glowBoost: Double = 0
    /// -1 he draws the heart in, 0 rest, 1 the heart answers and he rises.
    var reaction: Double = 0
    var reportsFlyTarget: Bool = false

    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let compact = width < 350
            ZStack(alignment: .topLeading) {
                scene(width: width, height: height)

                // Keeps the text legible while letting the stage colour through.
                LinearGradient(
                    colors: [stage.sky[0].opacity(0.85), stage.sky[0].opacity(0)],
                    startPoint: .topLeading,
                    endPoint: UnitPoint(x: 0.6, y: 0.55)
                )
                .allowsHitTesting(false)

                mascot(width: width, height: height)

                // The heart answers: light lifts across the scene with the surge.
                RadialGradient(
                    colors: [
                        stage.heartColor.opacity(0.42 * max(0, reaction)),
                        stage.heartColor.opacity(0)
                    ],
                    center: UnitPoint(x: 0.72, y: 0.28),
                    startRadius: 0,
                    endRadius: width * 0.72
                )
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

                // Sunlight falling over the whole scene, mascot included.
                RadialGradient(
                    colors: [stage.sunGlow.opacity(0.55), stage.sunGlow.opacity(0)],
                    center: UnitPoint(x: 0.85, y: 0.12),
                    startRadius: 0,
                    endRadius: width * 0.8
                )
                .blendMode(.softLight)
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 0) {
                    statusBlock(compact: compact)
                        .frame(maxWidth: width * 0.44, alignment: .leading)
                    Spacer(minLength: 10)
                    NafsiStageLadder(current: stage, compact: compact)
                    Spacer(minLength: 10)
                    xpCard
                }
                .padding(14)

                unlockChip
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .id(languageManager.currentLanguage)
    }

    // MARK: Scene

    @ViewBuilder
    private func scene(width: CGFloat, height: CGFloat) -> some View {
        if stage.hasSceneArt {
            Image(stage.sceneImageName)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
        } else {
            NafsiEnvironmentView(stage: stage)
                .frame(width: width, height: height)
        }
    }

    @ViewBuilder
    private func mascot(width: CGFloat, height: CGFloat) -> some View {
        if !stage.hasSceneArt {
            let xpCardSpace: CGFloat = 104
            let mascotHeight = (height - xpCardSpace) * 0.86
            NafsiMascotView(stage: stage, glowBoost: glowBoost, reaction: reaction)
                .frame(height: mascotHeight)
                .scaleEffect(mascotScale, anchor: .bottom)
                .frame(width: width, height: height - xpCardSpace + 6, alignment: .bottom)
                .offset(x: width * 0.14)
                .allowsHitTesting(false)
        }
    }

    // MARK: Text

    private func statusBlock(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(status.kicker.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundColor(stage.accent)
            Text(status.title)
                .font(.system(size: compact ? 21 : 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textOnLight)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
            Text(status.subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.35, green: 0.40, blue: 0.37))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    private var unlockChip: some View {
        HStack(spacing: 6) {
            Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 13, weight: .bold))
            Text(unlockLabel)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
        }
        .foregroundColor(isUnlocked ? AppTheme.primaryDark : Color(red: 0.35, green: 0.40, blue: 0.37))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.82))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
    }

    // MARK: XP

    private var xpCard: some View {
        let isTop = stage.next == nil
        let remaining = max(0, nextXP - totalXP)
        let footnote: String = isTop
            ? String(format: NSLocalizedString("heart.xp_to_next_milestone", comment: "%d XP to next milestone"), remaining)
            : String(
                format: NSLocalizedString("heart.xp_to_next", comment: "%d XP to %@"),
                remaining,
                NSLocalizedString(stage.next?.nameKey ?? stage.nameKey, comment: "")
            )

        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                NafsiStageGem(stage: stage, size: 22)
                Text(NSLocalizedString(stage.nameKey, comment: ""))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textOnLight)
                Spacer(minLength: 6)
                Text("\(totalXP) / \(nextXP) \(NSLocalizedString("heart.xp_label", comment: "XP"))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textOnLight)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            NafsiProgressBar(progress: progress, stage: stage, pulse: barPulse, reportsFlyTarget: reportsFlyTarget)

            Text(footnote)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.45, green: 0.49, blue: 0.47))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(stage.accentLight.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
                .shadow(color: stage.accent.opacity(0.14), radius: 12, y: 4)
        )
        .scaleEffect(barPulse ? 1.02 : 1)
        .animation(.spring(response: 0.42, dampingFraction: 0.7), value: barPulse)
    }
}

// MARK: - Progress bar

struct NafsiProgressBar: View {
    let progress: Double
    let stage: NafsiStage
    var pulse: Bool = false
    var reportsFlyTarget: Bool = false

    private var clamped: Double { min(1, max(0, progress)) }
    private let barHeight: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let fillWidth = clamped < 0.02 ? 0 : max(barHeight, geo.size.width * CGFloat(clamped))
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.07))
                Capsule(style: .continuous)
                    .fill(LinearGradient(colors: [stage.accent, stage.accent.opacity(0.78)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: fillWidth)
                    .shadow(color: stage.accent.opacity(pulse ? 0.55 : 0), radius: pulse ? 8 : 0)
                    .animation(.spring(response: 0.72, dampingFraction: 0.84), value: clamped)
                    .animation(.easeInOut(duration: 0.45), value: stage)
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
    }
}

// MARK: - Stage ladder

struct NafsiStageLadder: View {
    let current: NafsiStage
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            ForEach(NafsiStage.allCases.reversed()) { stage in
                row(stage)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(NSLocalizedString(current.nameKey, comment: ""))
    }

    private func row(_ stage: NafsiStage) -> some View {
        let isCurrent = stage == current
        let reached = stage <= current
        return HStack(spacing: 8) {
            Capsule()
                .fill(isCurrent ? stage.accent : Color.clear)
                .frame(width: 3, height: 18)
            NafsiStageGem(stage: stage, size: isCurrent ? 20 : 16)
                .opacity(reached ? 1 : 0.45)
            Text(NSLocalizedString(stage.nameKey, comment: ""))
                .font(.system(size: isCurrent ? (compact ? 13 : 14) : (compact ? 11 : 13), weight: isCurrent ? .bold : .medium, design: .rounded))
                .foregroundColor(isCurrent ? AppTheme.textOnLight : Color(red: 0.45, green: 0.49, blue: 0.47).opacity(reached ? 1 : 0.7))
                .lineLimit(1)
                .fixedSize()
        }
        .animation(.easeInOut(duration: 0.4), value: current)
    }
}

// MARK: - Gem

/// Faceted rhombus in the stage colour.
struct NafsiStageGem: View {
    let stage: NafsiStage
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            NafsiGemShape()
                .fill(LinearGradient(colors: [stage.accentLight, stage.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
            NafsiGemShape()
                .inset(fraction: 0.30)
                .fill(Color.white.opacity(0.38))
            NafsiGemShape()
                .stroke(stage.accent.opacity(0.9), lineWidth: max(0.8, size * 0.05))
        }
        .frame(width: size, height: size)
        .shadow(color: stage.accent.opacity(0.35), radius: size * 0.15, y: 1)
    }
}

struct NafsiGemShape: Shape {
    var insetFraction: CGFloat = 0

    func inset(fraction: CGFloat) -> NafsiGemShape {
        NafsiGemShape(insetFraction: fraction)
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: rect.width * insetFraction, dy: rect.height * insetFraction)
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}
