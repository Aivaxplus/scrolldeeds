//
//  NafsiMascot.swift
//  scrolldeeds
//
//  The Nafsi companion. One character; stages change pose, tint and heart glow.
//

import SwiftUI
import UIKit

enum NafsiMascotPose {
    case guarded, upright, confident, elevated, mastery

    /// Per-pose artwork. Missing images fall back to the shared placeholder.
    var imageName: String {
        switch self {
        case .guarded, .upright: return "NafsiHeroCalm"
        case .confident, .elevated, .mastery: return "NafsiHeroRise"
        }
    }

    static let placeholderImageName = "NafsiMascotPlaceholder"

    var resolvedImageName: String {
        UIImage(named: imageName) != nil ? imageName : Self.placeholderImageName
    }

    /// Where the heart sits in the artwork (unit coordinates), so the glow lines up.
    var heartAnchor: UnitPoint {
        switch self {
        case .guarded, .upright: return UnitPoint(x: 0.545, y: 0.245)
        case .confident, .elevated, .mastery: return UnitPoint(x: 0.515, y: 0.29)
        }
    }

    /// Width / height of the full-body artwork.
    var aspectRatio: CGFloat { 1 }
}

struct NafsiMascotView: View {
    let stage: NafsiStage
    var glowBoost: Double = 0
    /// -1 he draws the heart in, 0 rest, 1 the heart answers and he rises.
    var reaction: Double = 0
    var animated: Bool = true
    /// 0...heartCapacity — drives glow intensity on the dashboard.
    var hearts: Int = NafsiLivesManager.fallbackCapacity
    var heartCapacity: Int = NafsiLivesManager.fallbackCapacity
    /// Shop artwork. When set, this image replaces the rank pose.
    var artworkName: String? = nil

    @State private var breathe = false
    @State private var pulse = false

    private var pose: NafsiMascotPose { stage.pose }
    private var heartRatio: Double {
        let cap = max(1, heartCapacity)
        return Double(max(0, min(cap, hearts))) / Double(cap)
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                artwork
                if artworkName == nil {
                    heartGlow(in: size)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .aspectRatio(pose.aspectRatio, contentMode: .fit)
        .scaleEffect(
            x: 1 + rising * 0.02 - gathering * 0.012,
            y: (breathe ? 1.012 : 1) + rising * 0.04 - gathering * 0.03,
            anchor: .bottom
        )
        .offset(y: gathering * 6 - rising * 10)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 4.6).repeatForever(autoreverses: true)) {
                breathe = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityHidden(true)
    }

    private var gathering: CGFloat { CGFloat(max(0, -reaction)) }
    private var rising: CGFloat { CGFloat(max(0, reaction)) }

    /// Two layers so each stage can recolour the character without tinting the white paper:
    /// the ink multiplied onto the scene, then the stage colour applied only where there is ink.
    private var artwork: some View {
        let cutout = pose.resolvedImageName != NafsiMascotPose.placeholderImageName
        return ZStack {
            Group {
                if cutout {
                    baseImage
                } else {
                    edgeFaded(baseImage.saturation(stage.mascotSaturation))
                        .blendMode(.multiply)
                }
            }

            if !cutout && stage.mascotTintStrength > 0 {
                edgeFaded(
                    Rectangle()
                        .fill(stage.mascotTint)
                        .mask(inkMask)
                )
                .opacity(stage.mascotTintStrength)
                .blendMode(.color)
            }
        }
    }

    private var resolvedArtwork: String {
        if let artworkName, UIImage(named: artworkName) != nil {
            return artworkName
        }
        return pose.resolvedImageName
    }

    private var baseImage: some View {
        Image(resolvedArtwork).resizable().scaledToFit()
    }

    /// Opaque where the artwork is dark, transparent on the white paper.
    private var inkMask: some View {
        baseImage.colorInvert().luminanceToAlpha()
    }

    private func edgeFaded<Content: View>(_ content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.04),
                        .init(color: .black, location: 0.82),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.14),
                        .init(color: .black, location: 0.86),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    private func heartGlow(in size: CGSize) -> some View {
        let strength = min(1.5, (stage.heartGlow + glowBoost) * (0.35 + 0.65 * heartRatio) + Double(rising) * 0.9)
        let radius = size.width * (0.16 + 0.10 * strength) * (1 - gathering * 0.2 + rising * 1.15)
        let x = size.width * pose.heartAnchor.x
        let y = size.height * pose.heartAnchor.y
        return ZStack {
            Circle()
                .stroke(stage.heartColor.opacity(0.7 * Double(rising)), lineWidth: 2.5)
                .frame(width: radius * 0.45, height: radius * 0.45)
                .scaleEffect(0.45 + rising * 2.8)
                .opacity(Double(rising) * Double(1 - rising) * 3.2)
                .blendMode(.plusLighter)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [stage.heartColor.opacity(0.9 * strength), stage.heartColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                .frame(width: radius * 2, height: radius * 2)
                .scaleEffect((pulse ? 1.12 : 0.92) * (1 + rising * 0.12))
                .blendMode(.plusLighter)

            Circle()
                .fill(Color.white.opacity(0.7 * strength))
                .frame(width: radius * (0.28 + rising * 0.28), height: radius * (0.28 + rising * 0.28))
                .blur(radius: radius * 0.12)
                .blendMode(.plusLighter)
        }
        .position(x: x, y: y)
        .allowsHitTesting(false)
    }
}
