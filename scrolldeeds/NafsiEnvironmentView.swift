//
//  NafsiEnvironmentView.swift
//  scrolldeeds
//
//  Drawn backdrop behind the mascot: sky, mountains, a distant mosque and mist.
//  Used until painted scene art is added for a stage.
//

import SwiftUI

struct NafsiEnvironmentView: View {
    let stage: NafsiStage
    var animated: Bool = true

    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LinearGradient(colors: stage.sky, startPoint: .top, endPoint: .bottom)

                RadialGradient(
                    colors: [stage.sunGlow, stage.sunGlow.opacity(0.35), stage.sunGlow.opacity(0)],
                    center: UnitPoint(x: 0.80, y: 0.30),
                    startRadius: 0,
                    endRadius: w * 0.70
                )

                NafsiMountainShape(peaks: [0.40, 0.54, 0.44, 0.60, 0.48, 0.56], baseline: 0.68)
                    .fill(stage.mountains.far.opacity(0.85))
                    .blur(radius: 1.5)
                    .offset(x: drift ? -6 : 6)

                NafsiMosqueShape()
                    .fill(LinearGradient(colors: [stage.mosque.lit, stage.mosque.shade], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.48, height: h * 0.40)
                    .position(x: w * 0.84, y: h * 0.47)
                    .opacity(0.95)
                    .blur(radius: 0.6)

                NafsiMountainShape(peaks: [0.66, 0.74, 0.62, 0.78, 0.70], baseline: 0.84)
                    .fill(stage.mountains.near.opacity(0.75))
                    .offset(x: drift ? 4 : -4)

                LinearGradient(
                    colors: [stage.mountains.near.opacity(0), stage.mountains.near.opacity(0.55)],
                    startPoint: UnitPoint(x: 0.5, y: 0.72),
                    endPoint: .bottom
                )

                LinearGradient(
                    colors: [Color.white.opacity(0), Color.white.opacity(0.25)],
                    startPoint: UnitPoint(x: 0.5, y: 0.5),
                    endPoint: .bottom
                )

                if stage.particleCount > 0 {
                    NafsiParticles(count: stage.particleCount, color: stage.accentLight, animated: animated)
                }
            }
            .blur(radius: 0.6)
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
        .accessibilityHidden(true)
    }
}

/// Soft ridge line. `peaks` are heights as a fraction of the frame (0 = top).
struct NafsiMountainShape: Shape {
    let peaks: [CGFloat]
    let baseline: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let step = w / CGFloat(max(1, peaks.count - 1))
        p.move(to: CGPoint(x: -w * 0.05, y: h))
        p.addLine(to: CGPoint(x: -w * 0.05, y: h * baseline))
        var prev = CGPoint(x: -w * 0.05, y: h * baseline)
        for (i, peak) in peaks.enumerated() {
            let point = CGPoint(x: CGFloat(i) * step, y: h * peak)
            let control = CGPoint(x: (prev.x + point.x) / 2, y: min(prev.y, point.y) - h * 0.04)
            p.addQuadCurve(to: point, control: control)
            prev = point
        }
        p.addQuadCurve(
            to: CGPoint(x: w * 1.05, y: h * baseline),
            control: CGPoint(x: (prev.x + w) / 2, y: prev.y)
        )
        p.addLine(to: CGPoint(x: w * 1.05, y: h))
        p.closeSubpath()
        return p
    }
}

/// Minimal mosque silhouette: a main dome, two minarets and a low base.
struct NafsiMosqueShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY

        // Base hall
        p.addRect(CGRect(x: x + w * 0.18, y: y + h * 0.62, width: w * 0.64, height: h * 0.38))

        // Main dome
        let domeCenter = CGPoint(x: x + w * 0.5, y: y + h * 0.62)
        let domeRadius = w * 0.20
        p.move(to: CGPoint(x: domeCenter.x - domeRadius, y: domeCenter.y))
        p.addQuadCurve(
            to: CGPoint(x: domeCenter.x, y: domeCenter.y - domeRadius * 1.55),
            control: CGPoint(x: domeCenter.x - domeRadius * 1.05, y: domeCenter.y - domeRadius * 1.2)
        )
        p.addQuadCurve(
            to: CGPoint(x: domeCenter.x + domeRadius, y: domeCenter.y),
            control: CGPoint(x: domeCenter.x + domeRadius * 1.05, y: domeCenter.y - domeRadius * 1.2)
        )
        p.closeSubpath()
        // Finial
        p.addRect(CGRect(x: domeCenter.x - w * 0.006, y: domeCenter.y - domeRadius * 1.85, width: w * 0.012, height: domeRadius * 0.32))

        // Side domes
        for side in [0.30, 0.70] {
            let c = CGPoint(x: x + w * side, y: y + h * 0.66)
            let r = w * 0.08
            p.move(to: CGPoint(x: c.x - r, y: c.y))
            p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x, y: c.y - r * 2.1))
            p.closeSubpath()
        }

        // Minarets
        for side in [0.06, 0.90] {
            let mx = x + w * side
            let mw = w * 0.04
            p.addRect(CGRect(x: mx, y: y + h * 0.18, width: mw, height: h * 0.82))
            p.addRect(CGRect(x: mx - mw * 0.35, y: y + h * 0.34, width: mw * 1.7, height: h * 0.025))
            p.move(to: CGPoint(x: mx - mw * 0.2, y: y + h * 0.18))
            p.addLine(to: CGPoint(x: mx + mw / 2, y: y + h * 0.04))
            p.addLine(to: CGPoint(x: mx + mw * 1.2, y: y + h * 0.18))
            p.closeSubpath()
        }
        return p
    }
}

/// Slow floating motes of light for the higher stages.
private struct NafsiParticles: View {
    let count: Int
    let color: Color
    let animated: Bool

    @State private var rise = false

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<count, id: \.self) { i in
                let seed = Double(i) * 0.6180339
                let x = (seed.truncatingRemainder(dividingBy: 1)) * geo.size.width
                let baseY = geo.size.height * (0.25 + 0.5 * ((seed * 1.7).truncatingRemainder(dividingBy: 1)))
                let size = 2.0 + Double(i % 3)
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .blur(radius: 0.6)
                    .opacity(rise ? 0.15 : 0.7)
                    .position(x: x, y: baseY - (rise ? 18 : 0))
                    .animation(
                        .easeInOut(duration: 4 + Double(i % 4)).repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.3),
                        value: rise
                    )
            }
        }
        .onAppear { if animated { rise = true } }
        .allowsHitTesting(false)
    }
}
