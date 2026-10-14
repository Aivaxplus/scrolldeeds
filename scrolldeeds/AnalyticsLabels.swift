//
//  AnalyticsLabels.swift
//  scrolldeeds
//
//  Canonical analytics vocabulary. PostHog must receive the same English strings
//  regardless of the language the user sees on screen, otherwise every insight
//  breaks the moment a translation changes.
//

import SwiftUI

/// Readable `$screen_name` values. Without these PostHog reports iOS class names
/// like `UIHostingController<ModifiedContent<AnyView, RootModifier>>`.
enum AnalyticsScreen {
    static let getStarted = "Get Started"
    static let streakPreview = "Streak Preview"
    static let onboarding = "Onboarding"
    static let commitment = "Commitment"
    static let paywall = "Paywall"
    static let paywallPostTrial = "Paywall Post Trial"
    static let thankYou = "Thank You"
    static let appSelection = "App Selection"
    static let difficultySelection = "Difficulty Selection"
    static let quickGuide = "Quick Guide"
    static let home = "Home"
    static let dashboard = "Dashboard"
    static let lock = "Lock"
    static let goodDeeds = "Good Deeds"
    static let stats = "Stats"
    static let settings = "Settings"
    static let alarm = "Alarm"
    static let referralCode = "Referral Code"
    static let rememberVault = "Remember Vault"
    static let deleteIntervention = "Delete Intervention"
    static let customerCenter = "Customer Center"
    static let languageSettings = "Language Settings"
    static let reminderSettings = "Reminder Settings"
    static let difficultySettings = "Difficulty Settings"
    static let inAppFeedback = "In-App Feedback"
    static let knowledgeFeed = "Knowledge Feed"
}

/// English labels for the answers a user picked, matching the text shown on screen.
enum AnalyticsAnswerLabel {
    /// The English wording behind a localization key. A Dutch user tapping "Ja" and an
    /// English user tapping "Yes" must land on the same value in PostHog.
    static func english(key: String, fallback: String) -> String {
        guard let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return fallback
        }
        let value = bundle.localizedString(forKey: key, value: "", table: nil)
        return value.isEmpty ? fallback : value
    }

    /// Onboarding Easy / Medium / Hard, keyed by the stored 0–2 level.
    static func difficulty(level: Int) -> String {
        switch min(2, max(0, level)) {
        case 0: return "Easy"
        case 2: return "Hard"
        default: return "Medium"
        }
    }

    /// 1–5 mood scale, matching the captions printed under the slider.
    static func mood(value: Int) -> String {
        switch min(5, max(1, value)) {
        case 1: return "Guilty"
        case 2: return "Low"
        case 3: return "Okay"
        case 4: return "Good"
        default: return "Super happy"
        }
    }
}

extension View {
    /// Reports a readable screen name to PostHog every time this screen appears.
    func trackScreen(_ name: String) -> some View {
        onAppear { PostHogManager.shared.screen(name) }
    }
}
