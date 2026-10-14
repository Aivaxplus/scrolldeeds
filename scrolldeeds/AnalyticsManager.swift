//
//  AnalyticsManager.swift
//  scrolldeeds
//
//  Analytics tracking for retention & funnel analysis
//

import Foundation

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private let defaults = UserDefaults.standard
    private let firstLaunchKey = "analytics_first_launch"
    private let lastActiveKey = "analytics_last_active"
    private let weekCheckKey = "analytics_week_check"
    private let isActiveAfterWeekKey = "analytics_active_after_week"
    
    // Onboarding tracking
    private var onboardingStartTime: Date?
    private var lastStepTime: Date?
    
    private init() {}
    
    // Track app launch
    func trackAppLaunch() {
        let now = Date()
        
        // Set first launch if not set
        if defaults.object(forKey: firstLaunchKey) == nil {
            defaults.set(now, forKey: firstLaunchKey)
            debugPrint("📊 Analytics: First launch tracked")
        }
        
        // Update last active
        defaults.set(now, forKey: lastActiveKey)
        
        // Check if 1 week has passed since first launch
        checkWeekRetention()
    }
    
    // Check if user is still active after 1 week
    private func checkWeekRetention() {
        guard let firstLaunch = defaults.object(forKey: firstLaunchKey) as? Date else {
            return
        }
        
        // Check if we already did the week check
        if defaults.bool(forKey: weekCheckKey) {
            return
        }
        
        let oneWeekLater = firstLaunch.addingTimeInterval(7 * 24 * 60 * 60) // 7 days
        let now = Date()
        
        // If 1 week has passed
        if now >= oneWeekLater {
            // Check if user is still active (opened app within last 3 days)
            let threeDaysAgo = now.addingTimeInterval(-3 * 24 * 60 * 60)
            let lastActive = defaults.object(forKey: lastActiveKey) as? Date ?? firstLaunch
            
            let isActive = lastActive >= threeDaysAgo
            defaults.set(isActive, forKey: isActiveAfterWeekKey)
            defaults.set(true, forKey: weekCheckKey)
            
            debugPrint("📊 Analytics: Week retention check - Active: \(isActive)")
        }
    }
    
    // Track session completion
    func trackSessionCompleted() {
        // Analytics: implement when you add a provider (e.g. PostHog)
    }
    
    // MARK: - Trial Tracking
    
    func trackFreeTrialStarted() {
        debugPrint("📊 Analytics: Free trial started")
    }
    
    // MARK: - Onboarding Funnel Tracking
    
    private var stepStartTimes: [Int: Date] = [:]
    private var totalSteps: Int = 0
    /// Guards against the same step firing twice on re-render.
    private var trackedStepIdentifiers: Set<String> = []
    private var hasTrackedOnboardingCompleted = false
    
    /// Call when onboarding starts. Fires at most once per questionnaire run, because
    /// SwiftUI can re-run `onAppear` on the same view.
    func trackOnboardingStarted() {
        guard onboardingStartTime == nil else {
            debugPrint("📊 Onboarding: Started already tracked, skipping duplicate")
            return
        }
        onboardingStartTime = Date()
        lastStepTime = Date()
        stepStartTimes = [:]
        stepStartTimes[0] = Date()
        trackedStepIdentifiers = []
        debugPrint("📊 Onboarding: Started")
        PostHogManager.shared.trackOnboardingStarted()
    }
    
    /// Call when user views a step
    func trackOnboardingStep(step: Int, stepName: String, stepType: String, totalSteps: Int, stepIdentifier: String) {
        // A step can be re-rendered (auto-advance timers, animations) without being a new view.
        guard !trackedStepIdentifiers.contains(stepIdentifier) else {
            debugPrint("📊 Onboarding: Step \(stepIdentifier) already tracked, skipping duplicate")
            return
        }
        trackedStepIdentifiers.insert(stepIdentifier)

        let now = Date()
        self.totalSteps = totalSteps
        
        // Calculate time on previous step
        var timeOnPreviousStep: Double = 0
        if step > 0, let previousStepStart = stepStartTimes[step - 1] {
            timeOnPreviousStep = now.timeIntervalSince(previousStepStart)
        }
        
        // Store start time for this step
        stepStartTimes[step] = now
        lastStepTime = now
        
        debugPrint("📊 Onboarding: Step \(step)/\(totalSteps) - \(stepName) (type: \(stepType), prev: \(Int(timeOnPreviousStep))s, identifier: \(stepIdentifier))")
        PostHogManager.shared.trackOnboardingStep(
            step: step,
            stepName: stepName,
            stepType: stepType,
            stepIdentifier: stepIdentifier,
            totalSteps: totalSteps,
            timeOnPreviousStep: timeOnPreviousStep
        )
    }
    
    /// Call when user goes back to previous step
    func trackOnboardingBackPressed(fromStep: Int, stepName: String) {
        let timeOnStep: Double
        if let stepStart = stepStartTimes[fromStep] {
            timeOnStep = Date().timeIntervalSince(stepStart)
            debugPrint("📊 Onboarding: Back pressed from step \(fromStep) - \(stepName) (time on step: \(Int(timeOnStep))s)")
        } else {
            debugPrint("📊 Onboarding: Back pressed from step \(fromStep) - \(stepName)")
        }
    }
    
    /// Call when user answers a question.
    /// - Parameter answerText: must be the English label the user saw, never a raw enum key.
    func trackOnboardingAnswer(
        step: Int,
        stepName: String,
        stepIdentifier: String,
        answerIndex: Int,
        answerText: String,
        selectionSource: String = "manual"
    ) {
        var timeToAnswer: Double = 0
        if let stepStart = stepStartTimes[step] {
            timeToAnswer = Date().timeIntervalSince(stepStart)
        }
        
        debugPrint("📊 Onboarding: Answer at step \(step) [\(stepIdentifier)] - \(answerText) (took \(Int(timeToAnswer))s)")
        PostHogManager.shared.trackOnboardingAnswer(
            step: step,
            stepName: stepName,
            stepIdentifier: stepIdentifier,
            answerIndex: answerIndex,
            answerText: answerText,
            timeToAnswerSeconds: timeToAnswer,
            selectionSource: selectionSource
        )
    }
    
    /// Call when user makes a commitment
    func trackOnboardingCommitment(step: Int, stepName: String, stepIdentifier: String, committed: Bool) {
        var timeToCommit: Double = 0
        if let stepStart = stepStartTimes[step] {
            timeToCommit = Date().timeIntervalSince(stepStart)
        }
        
        debugPrint("📊 Onboarding: Commitment at step \(step) - \(committed) (took \(Int(timeToCommit))s)")
        PostHogManager.shared.track("Onboarding Commitment Selected", properties: [
            "step_number": step,
            "step_name": stepName,
            "step_identifier": stepIdentifier,
            "answer_selected": committed ? "Accepted" : "Not accepted",
            "committed": committed,
            "time_to_answer_seconds": timeToCommit
        ])
    }
    
    /// Call when user selects apps to lock
    func trackOnboardingAppsSelected(count: Int, skipped: Bool) {
        debugPrint("📊 Onboarding: Apps selected - \(count) (skipped: \(skipped))")
        PostHogManager.shared.track("Onboarding Apps Selected", properties: [
            "apps_selected": count,
            "skipped": skipped,
            "answer_selected": skipped ? "Skipped" : "\(count) apps"
        ])
    }
    
    /// Call when user selects difficulty level.
    /// - Parameters:
    ///   - level: canonical English label from `AnalyticsAnswerLabel.difficulty`.
    ///   - source: where the choice was made — `onboarding`, `post_subscribe` or `settings`.
    func trackOnboardingDifficultySelected(level: String, unlockMinutes: Int, source: String) {
        debugPrint("📊 Difficulty selected - \(level) (\(unlockMinutes) min, source: \(source))")
        PostHogManager.shared.track("Onboarding Difficulty Selected", properties: [
            "difficulty_level": level,
            "unlock_duration": "\(unlockMinutes) min",
            "unlock_minutes": unlockMinutes,
            "answer_selected": level,
            "source": source
        ])
    }
    
    /// Call when permission is requested
    func trackOnboardingPermissionRequested(type: String, granted: Bool) {
        debugPrint("📊 Onboarding: Permission \(type) - \(granted ? "granted" : "denied")")
        PostHogManager.shared.track("Onboarding Permission Requested", properties: [
            "permission_type": type,
            "granted": granted
        ])
    }
    
    /// Call when onboarding is completed. Fires at most once per run.
    func trackOnboardingCompleted(totalSteps: Int, appsSelected: Int) {
        guard !hasTrackedOnboardingCompleted else {
            debugPrint("📊 Onboarding: Completed already tracked, skipping duplicate")
            return
        }
        hasTrackedOnboardingCompleted = true

        var totalTime: Double = 0
        if let startTime = onboardingStartTime {
            totalTime = Date().timeIntervalSince(startTime)
        }
        let difficulty = AnalyticsAnswerLabel.difficulty(level: UserDataManager.shared.onboardingDifficultyLevel)
        debugPrint("📊 Onboarding: Completed in \(Int(totalTime))s, difficulty \(difficulty)")
        PostHogManager.shared.trackOnboardingCompleted(
            totalSteps: totalSteps,
            totalTimeSeconds: totalTime,
            appsSelected: appsSelected,
            difficultyLevel: difficulty
        )
        MetaEventsManager.shared.trackOnboardingCompleted()
        onboardingStartTime = nil
        lastStepTime = nil
        stepStartTimes = [:]
        trackedStepIdentifiers = []
    }
    
    /// Call when user abandons onboarding (closes app or leaves flow).
    func trackOnboardingAbandoned(atStep: Int, stepName: String, stepIdentifier: String, totalSteps: Int) {
        // Leaving the questionnaire after finishing it is not abandonment.
        guard !hasTrackedOnboardingCompleted else { return }

        let totalTime: Double
        if let startTime = onboardingStartTime {
            totalTime = Date().timeIntervalSince(startTime)
        } else {
            totalTime = 0
        }
        
        let progressPercent = totalSteps > 0 ? (Double(atStep) / Double(totalSteps)) * 100 : 0
        debugPrint("📊 Onboarding: Abandoned at step \(atStep) - \(stepName) (\(Int(progressPercent))% complete, \(Int(totalTime))s total)")
        PostHogManager.shared.trackOnboardingAbandoned(
            atStep: atStep,
            stepName: stepName,
            stepIdentifier: stepIdentifier,
            totalSteps: totalSteps,
            progressPercent: progressPercent,
            totalTimeSeconds: totalTime
        )
    }
    
    // MARK: - Paywall Funnel Tracking
    
    /// Call when soft paywall is shown
    func trackSoftPaywallShown() {
        // Analytics: implement when you add a provider
    }
    
    /// Call when soft paywall is skipped
    func trackSoftPaywallSkipped() {
        // Analytics: implement when you add a provider
    }
    
    /// Call when hard paywall is shown
    func trackHardPaywallShown() {
        MetaEventsManager.shared.trackPaywallViewed()
    }
    
    /// Call when purchase is attempted
    func trackPurchaseAttempted(productId: String, isYearly: Bool) {
        let plan: String
        if productId.lowercased().contains("weekly") {
            plan = "weekly"
        } else if isYearly {
            plan = "yearly"
        } else {
            plan = "monthly"
        }
        MetaEventsManager.shared.trackInitiatedCheckout(productId: productId, plan: plan)
    }
    
    /// Call when purchase succeeds
    func trackPurchaseCompleted(productId: String, isYearly: Bool) {
        // Analytics: implement when you add a provider
    }
    
    /// Call when purchase fails
    func trackPurchaseFailed(productId: String, error: String) {
        // Analytics: implement when you add a provider
    }
    
    // Get retention status (for debugging/admin)
    func getRetentionStatus() -> (isActive: Bool?, daysSinceFirstLaunch: Int) {
        guard let firstLaunch = defaults.object(forKey: firstLaunchKey) as? Date else {
            return (nil, 0)
        }
        
        let daysSince = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        let isActive = defaults.bool(forKey: isActiveAfterWeekKey)
        
        return (defaults.bool(forKey: weekCheckKey) ? isActive : nil, daysSince)
    }
}

#if DEBUG
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#else
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // No-op in production
}
#endif

