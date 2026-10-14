//
//  NafsiBuddy.swift
//  scrolldeeds
//
//  The companion shown from Get Started through every tab.
//

import SwiftUI

enum NafsiBuddy {
    static func pose(forOnboardingImage name: String) -> String {
        switch name {
        case "OnboardingQScreenTime", "OnboardingQReminderNeed":
            return "NafsiPoseRead"
        case "OnboardingQLateNight", "OnboardingQBarrier", "OnboardingQFeeling":
            return "NafsiPoseSit"
        case "OnboardingQControl", "OnboardingQTriedStop", "OnboardingQDistraction":
            return "NafsiPoseCrouch"
        case "OnboardingQChances", "OnboardingQExtraMinutes":
            return "NafsiPoseRise"
        case "OnboardingQPrayers", "OnboardingFajrStep1", "OnboardingFajrStep2", "OnboardingFajrStep3":
            return "NafsiPoseWatch"
        case "OnboardingQIntention", "OnboardingQFajr":
            return "NafsiPoseOffer"
        default:
            return "NafsiPoseStand"
        }
    }
}

struct NafsiBuddyView: View {
    var pose: String = "NafsiPoseStand"
    var height: CGFloat = 112
    /// Slow breath and a small lift, so he feels present without bouncing.
    var breathes: Bool = true

    @State private var alive = false

    var body: some View {
        Image(pose)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .scaleEffect(breathes && alive ? 1.03 : 1)
            .offset(y: breathes && alive ? -4 : 0)
            .animation(
                breathes ? .easeInOut(duration: 2.8).repeatForever(autoreverses: true) : .default,
                value: alive
            )
            .onAppear { alive = breathes }
            .accessibilityHidden(true)
    }
}
