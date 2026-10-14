//
//  NafsiStage.swift
//  scrolldeeds
//
//  Visual configuration per progression stage. XP and promotion stay in
//  HeartJourneyManager / HeartRank; this only decides how a stage looks.
//

import SwiftUI
import UIKit

enum NafsiStage: Int, CaseIterable, Identifiable, Comparable {
    case bronze, silver, gold, diamond, emerald

    var id: Int { rawValue }

    static func < (lhs: NafsiStage, rhs: NafsiStage) -> Bool { lhs.rawValue < rhs.rawValue }

    init(rank: HeartRank) {
        switch rank {
        case .spark, .bronze: self = .bronze
        case .silver: self = .silver
        case .gold: self = .gold
        case .diamond: self = .diamond
        case .emerald: self = .emerald
        }
    }

    var rank: HeartRank {
        switch self {
        case .bronze: return .bronze
        case .silver: return .silver
        case .gold: return .gold
        case .diamond: return .diamond
        case .emerald: return .emerald
        }
    }

    var next: NafsiStage? { NafsiStage(rawValue: rawValue + 1) }

    var nameKey: String { rank.localizationKey }

    /// Minimum XP to be in this stage. The top stage keeps repeating its bar.
    var minXP: Int { rank.startXP(totalXP: 0) }

    // MARK: Artwork

    /// Full painted scene (mascot + environment) per stage. Drop an image with this
    /// name into Assets.xcassets and the hero uses it instead of the drawn fallback.
    var sceneImageName: String {
        switch self {
        case .bronze: return "NafsiSceneBronze"
        case .silver: return "NafsiSceneSilver"
        case .gold: return "NafsiSceneGold"
        case .diamond: return "NafsiSceneDiamond"
        case .emerald: return "NafsiSceneEmerald"
        }
    }

    var hasSceneArt: Bool { UIImage(named: sceneImageName) != nil }

    var pose: NafsiMascotPose {
        switch self {
        case .bronze: return .guarded
        case .silver: return .upright
        case .gold: return .confident
        case .diamond: return .elevated
        case .emerald: return .mastery
        }
    }

    // MARK: Palette

    var accent: Color {
        switch self {
        case .bronze: return Color(red: 0.72, green: 0.47, blue: 0.27)
        case .silver: return Color(red: 0.55, green: 0.61, blue: 0.69)
        case .gold: return Color(red: 0.80, green: 0.62, blue: 0.20)
        case .diamond: return Color(red: 0.33, green: 0.64, blue: 0.86)
        case .emerald: return Color(red: 0.12, green: 0.55, blue: 0.36)
        }
    }

    var accentLight: Color {
        switch self {
        case .bronze: return Color(red: 0.93, green: 0.76, blue: 0.58)
        case .silver: return Color(red: 0.86, green: 0.89, blue: 0.93)
        case .gold: return Color(red: 0.99, green: 0.88, blue: 0.56)
        case .diamond: return Color(red: 0.80, green: 0.92, blue: 0.99)
        case .emerald: return Color(red: 0.62, green: 0.88, blue: 0.72)
        }
    }

    /// Sky, top to bottom.
    var sky: [Color] {
        switch self {
        case .bronze:
            return [Color(red: 0.98, green: 0.86, blue: 0.70), Color(red: 0.95, green: 0.80, blue: 0.64), Color(red: 0.86, green: 0.72, blue: 0.60)]
        case .silver:
            return [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.88, green: 0.91, blue: 0.94), Color(red: 0.80, green: 0.84, blue: 0.88)]
        case .gold:
            return [Color(red: 1.00, green: 0.94, blue: 0.72), Color(red: 0.98, green: 0.90, blue: 0.64), Color(red: 0.86, green: 0.84, blue: 0.64)]
        case .diamond:
            return [Color(red: 0.86, green: 0.94, blue: 1.00), Color(red: 0.80, green: 0.90, blue: 0.98), Color(red: 0.88, green: 0.94, blue: 0.98)]
        case .emerald:
            return [Color(red: 0.86, green: 0.94, blue: 0.86), Color(red: 0.72, green: 0.86, blue: 0.74), Color(red: 0.52, green: 0.70, blue: 0.56)]
        }
    }

    /// Far and near mountain tones.
    var mountains: (far: Color, near: Color) {
        switch self {
        case .bronze: return (Color(red: 0.80, green: 0.64, blue: 0.52), Color(red: 0.56, green: 0.42, blue: 0.32))
        case .silver: return (Color(red: 0.78, green: 0.82, blue: 0.87), Color(red: 0.54, green: 0.60, blue: 0.66))
        case .gold: return (Color(red: 0.84, green: 0.76, blue: 0.52), Color(red: 0.50, green: 0.54, blue: 0.34))
        case .diamond: return (Color(red: 0.82, green: 0.90, blue: 0.97), Color(red: 0.62, green: 0.74, blue: 0.86))
        case .emerald: return (Color(red: 0.52, green: 0.70, blue: 0.56), Color(red: 0.20, green: 0.40, blue: 0.27))
        }
    }

    /// Distant mosque: a lit face and a shaded base, clearly darker than the sky.
    var mosque: (lit: Color, shade: Color) {
        switch self {
        case .bronze: return (Color(red: 0.86, green: 0.66, blue: 0.46), Color(red: 0.66, green: 0.48, blue: 0.34))
        case .silver: return (Color(red: 0.76, green: 0.80, blue: 0.86), Color(red: 0.58, green: 0.64, blue: 0.71))
        case .gold: return (Color(red: 0.90, green: 0.74, blue: 0.40), Color(red: 0.68, green: 0.58, blue: 0.32))
        case .diamond: return (Color(red: 0.78, green: 0.87, blue: 0.96), Color(red: 0.56, green: 0.68, blue: 0.82))
        case .emerald: return (Color(red: 0.50, green: 0.70, blue: 0.54), Color(red: 0.28, green: 0.48, blue: 0.34))
        }
    }

    /// Soft light source behind the scene (sunrise, daylight, glow).
    var sunGlow: Color {
        switch self {
        case .bronze: return Color(red: 1.00, green: 0.78, blue: 0.48)
        case .silver: return Color.white
        case .gold: return Color(red: 1.00, green: 0.86, blue: 0.44)
        case .diamond: return Color(red: 0.90, green: 0.97, blue: 1.00)
        case .emerald: return Color(red: 0.82, green: 0.97, blue: 0.80)
        }
    }

    // MARK: Mascot colouring

    /// The character's clothing takes on the stage colour; emerald is its native colour.
    var mascotTint: Color {
        switch self {
        case .bronze: return Color(red: 0.62, green: 0.40, blue: 0.24)
        case .silver: return Color(red: 0.56, green: 0.61, blue: 0.68)
        case .gold: return Color(red: 0.62, green: 0.56, blue: 0.26)
        case .diamond: return Color(red: 0.34, green: 0.56, blue: 0.80)
        case .emerald: return Color(red: 0.10, green: 0.45, blue: 0.28)
        }
    }

    var mascotTintStrength: Double {
        switch self {
        case .bronze: return 0.85
        case .silver: return 0.35
        case .gold: return 0.45
        case .diamond: return 0.75
        case .emerald: return 0
        }
    }

    var mascotSaturation: Double {
        switch self {
        case .bronze: return 0
        case .silver: return 0
        case .gold: return 0.55
        case .diamond: return 0
        case .emerald: return 1
        }
    }

    // MARK: Heart and atmosphere

    /// 0…1. The heart burns brighter as the user grows.
    var heartGlow: Double {
        switch self {
        case .bronze: return 0.45
        case .silver: return 0.55
        case .gold: return 0.70
        case .diamond: return 0.85
        case .emerald: return 1.0
        }
    }

    var heartColor: Color {
        switch self {
        case .bronze: return Color(red: 1.00, green: 0.72, blue: 0.40)
        case .silver: return Color(red: 0.78, green: 0.88, blue: 1.00)
        case .gold: return Color(red: 1.00, green: 0.84, blue: 0.44)
        case .diamond: return Color(red: 0.56, green: 0.84, blue: 1.00)
        case .emerald: return Color(red: 0.36, green: 0.90, blue: 0.56)
        }
    }

    /// How prominent the distant mosque is (0 hides it).
    var mosqueOpacity: Double {
        switch self {
        case .bronze: return 0.22
        case .silver: return 0.30
        case .gold: return 0.42
        case .diamond: return 0.46
        case .emerald: return 0.55
        }
    }

    /// Floating light particles (0 = none).
    var particleCount: Int {
        switch self {
        case .bronze, .silver: return 0
        case .gold: return 5
        case .diamond: return 9
        case .emerald: return 12
        }
    }
}
