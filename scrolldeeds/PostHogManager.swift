//
//  PostHogManager.swift
//  scrolldeeds
//
//  PostHog analytics – events naar je PostHog project.
//

import Foundation
import PostHog

class PostHogManager {
    static let shared = PostHogManager()
    
    private init() {}
    
    private func language() -> String {
        Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
    }
    
    /// `debug` in Xcode, `testflight` for sandbox receipts, otherwise `appstore`.
    /// Lets PostHog exclude our own devices without guessing at user ids.
    static let buildChannel: String = {
        #if DEBUG
        return "debug"
        #else
        guard let receipt = Bundle.main.appStoreReceiptURL else { return "appstore" }
        return receipt.lastPathComponent == "sandboxReceipt" ? "testflight" : "appstore"
        #endif
    }()

    static var isTestAccount: Bool { buildChannel != "appstore" }

    /// Stuur een custom event (event-namen altijd in het Engels voor consistente analytics).
    func track(_ event: String, properties: [String: Any]? = nil) {
        var props = properties ?? [:]
        props["language"] = language()
        props["user_id"] = UserDataManager.shared.userID
        props["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        props["app_build"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        props["build_channel"] = Self.buildChannel
        props["is_test_account"] = Self.isTestAccount
        if PaywallExperiment.shared.isAssigned {
            props["paywall_variant"] = PaywallExperiment.shared.arm.rawValue
            props["paywall_experiment"] = PaywallExperiment.flagKey
        }
        PostHogSDK.shared.capture(event, properties: props)
    }

    // MARK: - Screens

    private var lastScreenName: String?
    private var lastScreenAt: Date?
    private var screensThisSession: [String] = []

    /// Reports a readable `$screen_name`. SwiftUI fires `onAppear` more than once per
    /// appearance, so identical back-to-back reports are collapsed.
    func screen(_ name: String) {
        if let last = lastScreenName, last == name,
           let at = lastScreenAt, Date().timeIntervalSince(at) < 0.6 {
            return
        }
        lastScreenName = name
        lastScreenAt = Date()
        screensThisSession.append(name)

        PostHogSDK.shared.screen(name, properties: [
            "$screen_name": name,
            "language": language(),
            "user_id": UserDataManager.shared.userID,
            "build_channel": Self.buildChannel,
            "is_test_account": Self.isTestAccount
        ])
    }

    // MARK: - App session

    private var sessionStartTime: Date?

    /// Call when the app comes to the foreground.
    func beginSession() {
        guard sessionStartTime == nil else { return }
        sessionStartTime = Date()
        screensThisSession = []
        lastScreenName = nil
        lastScreenAt = nil
    }

    /// Call when the app goes to the background. Emits the duration the dashboard reads.
    func endSession() {
        guard let start = sessionStartTime else { return }
        sessionStartTime = nil

        let durationSeconds = Date().timeIntervalSince(start)
        guard durationSeconds > 0 else { return }

        track("Session Completed", properties: [
            "duration_seconds": durationSeconds,
            "duration_minutes": durationSeconds / 60.0,
            "screens_visited": screensThisSession.count,
            "screens": Array(Set(screensThisSession)).sorted(),
            "total_sessions": UserDataManager.shared.totalSessions
        ])
        screensThisSession = []
    }
    
    func identifyCurrentUser() {
        let userData = UserDataManager.shared
        var properties: [String: Any] = [
            "user_id": userData.userID,
            "language": language(),
            "total_sessions": userData.totalSessions,
            "total_minutes": userData.totalMinutes,
            "current_streak": userData.currentStreak,
            "onboarding_difficulty_level": userData.onboardingDifficultyLevel,
            "difficulty_level": AnalyticsAnswerLabel.difficulty(level: userData.onboardingDifficultyLevel),
            "unlock_minutes": userData.effectiveUnlockMinutesAfterDeed(),
            "build_channel": Self.buildChannel,
            "is_test_account": Self.isTestAccount
        ]
        
        if let age = userData.userAge { properties["age"] = age }
        if let name = userData.userName { properties["name"] = name }
        if let referralSource = userData.referralSource { properties["referral_source"] = referralSource }
        if PaywallExperiment.shared.isAssigned {
            properties["paywall_variant"] = PaywallExperiment.shared.arm.rawValue
            properties["paywall_experiment"] = PaywallExperiment.flagKey
        }
        
        PostHogSDK.shared.identify(userData.userID, userProperties: properties)
    }
    
    // MARK: - App
    func trackAppLaunch() {
        track("App Launched")
    }
    
    // MARK: - Onboarding (volledige funnel: Get Started → Questionnaire stappen → Paywall → Thank You)

    /// Eerste scherm: "Break Phone Addiction" / Start Your Journey
    func trackGetStartedViewed() {
        track("Get Started Viewed")
    }

    /// Gebruiker tikt op "Start Your Journey" → streak preview (daarna questionnaire)
    func trackGetStartedCTAClicked() {
        track("Get Started CTA Clicked")
    }

    func trackOnboardingStreakPreviewViewed() {
        track("Onboarding Streak Preview Viewed")
    }

    func trackOnboardingStreakContinueClicked() {
        track("Onboarding Streak Continue Clicked")
    }

    func trackOnboardingStarted() {
        track("Onboarding Started")
    }

    func trackOnboardingStep(
        step: Int,
        stepName: String,
        stepType: String,
        stepIdentifier: String,
        totalSteps: Int,
        timeOnPreviousStep: Double
    ) {
        track("Onboarding Step Viewed", properties: [
            "step_number": step,
            "step_name": stepName,
            "step_type": stepType,
            "step_identifier": stepIdentifier,
            "total_steps": totalSteps,
            "time_on_previous_step": timeOnPreviousStep
        ])
    }
    
    func trackOnboardingAnswer(
        step: Int,
        stepName: String,
        stepIdentifier: String,
        answerIndex: Int,
        answerText: String,
        timeToAnswerSeconds: Double,
        selectionSource: String = "manual"
    ) {
        track("Onboarding Answer Selected", properties: [
            "step_number": step,
            "step_name": stepName,
            "step_identifier": stepIdentifier,
            "answer_index": answerIndex,
            "answer_selected": answerText,
            "time_to_answer_seconds": timeToAnswerSeconds,
            "selection_source": selectionSource
        ])
    }

    func trackOnboardingCompleted(
        totalSteps: Int,
        totalTimeSeconds: Double,
        appsSelected: Int,
        difficultyLevel: String
    ) {
        track("Onboarding Completed", properties: [
            "total_steps": totalSteps,
            "total_time_seconds": totalTimeSeconds,
            "total_time_minutes": totalTimeSeconds / 60.0,
            "apps_selected": appsSelected,
            "difficulty_level": difficultyLevel
        ])
    }

    func trackOnboardingAbandoned(
        atStep: Int,
        stepName: String,
        stepIdentifier: String,
        totalSteps: Int,
        progressPercent: Double,
        totalTimeSeconds: Double
    ) {
        track("Onboarding Abandoned", properties: [
            "step_number": atStep,
            "step_name": stepName,
            "step_identifier": stepIdentifier,
            "total_steps": totalSteps,
            "progress_percent": progressPercent,
            "total_time_seconds": totalTimeSeconds
        ])
    }

    /// Paywall getoond (na questionnaire)
    func trackPaywallViewed(context: String = "onboarding", offeringIdentifier: String? = nil) {
        var props: [String: Any] = ["paywall_context": context]
        if let offeringIdentifier { props["offering_identifier"] = offeringIdentifier }
        track("Paywall Viewed", properties: props)
    }

    /// Bedankpagina na succesvolle aankoop
    func trackThankYouViewed() {
        track("Thank You Viewed")
    }
    
    // MARK: - Deed sessions
    /// A completed good deed that earned unlock time. Distinct from `Session Completed`,
    /// which measures how long the app itself was open.
    func trackDeedSessionCompleted(minutesEarned: Int, totalSessions: Int) {
        track("Deed Session Completed", properties: [
            "minutes_earned": minutesEarned,
            "total_sessions": totalSessions
        ])
    }
    
    func trackUnlockActivated(durationMinutes: Int) {
        track("Unlock Activated", properties: [
            "duration_minutes": Double(durationMinutes),
            "minutes_earned": durationMinutes
        ])
    }
    
    func trackGoodDeedCompleted(task: GoodDeedTask, totalSessions: Int? = nil) {
        var props: [String: Any] = [
            "deed_id": task.id,
            "deed_type": deedType(for: task),
            "deed_name": task.title,
            "deed_unlock_minutes": task.unlockMinutes,
            "required_taps": task.requiredTaps,
            "requires_input": task.requiresInput
        ]
        
        if let dhikrType = task.dhikrType { props["dhikr_type"] = dhikrType.rawValue }
        if let surahKey = task.surahKey { props["surah_key"] = surahKey }
        if let duaKey = task.duaKey { props["dua_key"] = duaKey }
        if let totalSessions { props["total_sessions"] = totalSessions }
        
        track("Good Deed Completed", properties: props)
    }

    func trackInAppFeedbackOpened(source: String) {
        track("In-App Feedback Opened", properties: [
            "source": source
        ])
    }

    func trackInAppFeedbackSubmitted(message: String, source: String) {
        track("In-App Feedback Submitted", properties: [
            "message": message,
            "source": source,
            "character_count": message.count
        ])
    }
    
    private func deedType(for task: GoodDeedTask) -> String {
        if task.isDhikr { return "dhikr" }
        if task.isSurahTask { return "surah" }
        if task.isDuaTask { return "dua" }
        if task.requiresInput { return "reflection" }
        return "deed"
    }
}
