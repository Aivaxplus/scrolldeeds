//
//  LocalizationManager.swift
//  scrolldeeds
//
//  Centralized localization helper
//

import Foundation
import SwiftUI

// Bundle extension for real-time language switching
extension Bundle {
    static var localizedBundle: Bundle {
        let languageCode = LanguageManager.shared.currentLanguage
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        // Only seven languages ship; fall back to English if anything is inconsistent.
        if languageCode != "en",
           let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
    }
}

/// Looks up `key` in the in-app language first, then English.
/// Never returns the raw key when an English string exists — that is what made the paywall show `conv_paywall.…`.
private func localizedStringWithEnglishFallback(_ key: String, preferredDefault: String? = nil) -> String {
    let primary = Bundle.localizedBundle.localizedString(forKey: key, value: "", table: nil)
    if !primary.isEmpty, primary != key {
        return primary
    }

    let language = LanguageManager.shared.currentLanguage
    if language != "en",
       let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
       let enBundle = Bundle(path: enPath) {
        let english = enBundle.localizedString(forKey: key, value: "", table: nil)
        if !english.isEmpty, english != key {
            return english
        }
    }

    if let preferredDefault, !preferredDefault.isEmpty {
        return preferredDefault
    }
    return primary.isEmpty ? key : primary
}

// Helper for localized strings with real-time language switching
extension String {
    var localized: String {
        localizedStringWithEnglishFallback(self)
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: localizedStringWithEnglishFallback(self), arguments: arguments)
    }
}

// Custom NSLocalizedString function for real-time language switching
func NSLocalizedString(_ key: String, comment: String) -> String {
    localizedStringWithEnglishFallback(key)
}

// Overload with default value (e.g. task titles) — use app language bundle so in-app language switch works
func NSLocalizedString(_ key: String, value: String, comment: String) -> String {
    localizedStringWithEnglishFallback(key, preferredDefault: value)
}

// Localization Keys - All app strings
struct LocalizedKey {
    
    // MARK: - Onboarding
    struct Onboarding {
        static let title = "onboarding.title"
        static let subtitle = "onboarding.subtitle"
        static let benefitLockApps = "onboarding.benefit.lock_apps"
        static let benefitDhikr = "onboarding.benefit.dhikr"
        static let benefitTrack = "onboarding.benefit.track"
        static let benefitFocus = "onboarding.benefit.focus"
        static let ctaButton = "onboarding.cta_button"
        static let termsPrefix = "onboarding.terms_prefix"
        static let termsAnd = "onboarding.terms_and"
        static let termsLink = "onboarding.terms_link"
        static let privacyLink = "onboarding.privacy_link"
        static let appsLocked = "onboarding.phone.apps_locked"
        static let sayDhikr = "onboarding.phone.say_dhikr"
    }
    
    // MARK: - Paywall
    struct Paywall {
        static let title = "paywall.title"
        static let subtitle = "paywall.subtitle"
        static let usersCount = "paywall.users_count"
        static let rating = "paywall.rating"
        static let guarantee = "paywall.guarantee"
        static let yearlyTitle = "paywall.yearly.title"
        static let monthlyTitle = "paywall.monthly.title"
        static let mostPopular = "paywall.badge.most_popular"
        static let mostFlexible = "paywall.badge.most_flexible"
        static let freeTrial = "paywall.yearly.free_trial"
        static let cancelAnytime = "paywall.monthly.cancel_anytime"
        static let savePercent = "paywall.save_percent"
        static let ctaButtonTrial = "paywall.cta_button.trial"
        static let ctaButtonContinue = "paywall.cta_button.continue"
        static let freeTrialInfo = "paywall.free_trial_info"
        static let restore = "paywall.restore"
        static let terms = "paywall.terms"
        static let privacy = "paywall.privacy"
        static let perYear = "paywall.per_year"
        static let perMonth = "paywall.per_month"
    }
    
    // MARK: - Questionnaire
    struct Questionnaire {
        static let continueButton = "questionnaire.continue"
        static let backButton = "questionnaire.back"
        static let skipForNow = "questionnaire.skip_for_now"
        static let selectApps = "questionnaire.select_apps"
    }
    
    // MARK: - Dashboard
    struct Dashboard {
        static let welcome = "dashboard.welcome"
        static let tapToUnlock = "dashboard.tap_to_unlock"
        static let appsLocked = "dashboard.apps_locked"
        static let readyToLock = "dashboard.ready_to_lock"
        static let difficulty = "dashboard.difficulty"
        static let settings = "dashboard.settings"
        static let progress = "dashboard.progress"
        static let home = "dashboard.home"
    }
    
    // MARK: - Dhikr Types
    struct Dhikr {
        static let alhamdulillah = "dhikr.alhamdulillah"
        static let astaghfirullah = "dhikr.astaghfirullah"
        static let allahuAkbar = "dhikr.allahu_akbar"
        static let subhanallah = "dhikr.subhanallah"
        static let alhamdulillahDesc = "dhikr.alhamdulillah.desc"
        static let astaghfirullahDesc = "dhikr.astaghfirullah.desc"
        static let allahuAkbarDesc = "dhikr.allahu_akbar.desc"
        static let subhanallahDesc = "dhikr.subhanallah.desc"
    }
    
    // MARK: - Common
    struct Common {
        static let muslims = "common.muslims"
        static let users = "common.users"
        static let and = "common.and"
        static let or = "common.or"
        static let cancel = "common.cancel"
        static let ok = "common.ok"
        static let close = "common.close"
    }
    
    // MARK: - Error Messages
    struct Error {
        static let somethingWentWrong = "error.something_went_wrong"
        static let purchaseFailed = "error.purchase_failed"
        static let errorOccurred = "error.error_occurred"
        static let tryAgain = "error.try_again"
    }
    
    // MARK: - Paywall Benefits
    struct PaywallBenefits {
        static let unlockAppsWithDhikr = "paywall.benefit.unlock_apps"
        static let trackSpiritualProgress = "paywall.benefit.track_progress"
        static let smartReminders = "paywall.benefit.smart_reminders"
        static let unlimitedSessions = "paywall.benefit.unlimited_sessions"
        static let smartRemindersForConsistency = "paywall.benefit.reminders_consistency"
    }
    
    // MARK: - Paywall Social Proof
    struct PaywallSocial {
        static let usersCount = "paywall.social.users_count"
        static let rating = "paywall.social.rating"
        static let loved = "paywall.social.loved"
    }
    
    // MARK: - Paywall Trust Badges
    struct PaywallTrust {
        static let secure = "paywall.trust.secure"
        static let cancelAnytime = "paywall.trust.cancel_anytime"
        static let noAds = "paywall.trust.no_ads"
    }
    
    // MARK: - Paywall CTA
    struct PaywallCTA {
        static let startFreeTrial = "paywall.cta.start_free_trial"
        static let startPremiumNow = "paywall.cta.start_premium"
        static let tryFreeForMonth = "paywall.cta.try_free_month"
        static let startPremium = "paywall.cta.start_premium_short"
    }
    
    // MARK: - Paywall Plans
    struct PaywallPlans {
        static let yearly = "paywall.plan.yearly"
        static let monthly = "paywall.plan.monthly"
        static let bestValue = "paywall.plan.best_value"
        static let oneMonthFreeTrial = "paywall.plan.one_month_free"
        static let justPerMonth = "paywall.plan.just_per_month"
        static let oneMonthFreeThen = "paywall.plan.one_month_free_then"
    }
    
    // MARK: - Difficulty Info
    struct DifficultyInfo {
        static let whatThisMeans = "difficulty.info.what_this_means"
        static let howItWorks = "difficulty.info.how_it_works"
        static let howItWorksContent = "difficulty.info.how_it_works.content"
    }
    
    // MARK: - Notification
    struct Notification {
        static let appName = "notification.app_name"
        static let returnToApp = "notification.return_to_app"
    }
    
    // MARK: - Links
    struct Links {
        static let terms = "links.terms"
        static let privacy = "links.privacy"
    }
}
