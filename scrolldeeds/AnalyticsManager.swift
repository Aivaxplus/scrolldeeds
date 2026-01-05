//
//  AnalyticsManager.swift
//  scrolldeeds
//
//  Analytics tracking with TelemetryDeck for retention & funnel analysis
//

import Foundation
import TelemetryDeck

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
            
            // Send to TelemetryDeck (if configured)
            sendTelemetryDeckEvent(name: "week_retention", parameters: [
                "is_active": isActive ? "true" : "false",
                "days_since_launch": "7"
            ])
        }
    }
    
    // Track session completion
    func trackSessionCompleted() {
        sendTelemetryDeckEvent(name: "session_completed", parameters: [:])
    }
    
    // MARK: - Onboarding Funnel Tracking
    
    /// Call when onboarding starts
    func trackOnboardingStarted() {
        onboardingStartTime = Date()
        lastStepTime = Date()
        sendTelemetryDeckEvent(name: "onboarding_started", parameters: [:])
        debugPrint("📊 Onboarding: Started")
    }
    
    /// Call when user views a step
    func trackOnboardingStep(step: Int, stepName: String, stepType: String) {
        let now = Date()
        var timeOnPreviousStep: Double = 0
        
        if let lastTime = lastStepTime {
            timeOnPreviousStep = now.timeIntervalSince(lastTime)
        }
        lastStepTime = now
        
        sendTelemetryDeckEvent(name: "onboarding_step_viewed", parameters: [
            "step_number": "\(step)",
            "step_name": stepName,
            "step_type": stepType,
            "time_on_previous_step": "\(Int(timeOnPreviousStep))"
        ])
        debugPrint("📊 Onboarding: Step \(step) - \(stepName) (type: \(stepType))")
    }
    
    /// Call when user answers a question
    func trackOnboardingAnswer(step: Int, stepName: String, answerIndex: Int, answerText: String) {
        sendTelemetryDeckEvent(name: "onboarding_answer", parameters: [
            "step_number": "\(step)",
            "step_name": stepName,
            "answer_index": "\(answerIndex)",
            "answer_text": answerText
        ])
        debugPrint("📊 Onboarding: Answer at step \(step) - \(answerText)")
    }
    
    /// Call when user makes a commitment
    func trackOnboardingCommitment(step: Int, stepName: String, committed: Bool) {
        sendTelemetryDeckEvent(name: "onboarding_commitment", parameters: [
            "step_number": "\(step)",
            "step_name": stepName,
            "committed": committed ? "true" : "false"
        ])
        debugPrint("📊 Onboarding: Commitment at step \(step) - \(committed)")
    }
    
    /// Call when onboarding is completed
    func trackOnboardingCompleted(totalSteps: Int, appsSelected: Int, difficultyLevel: String) {
        var totalTime: Double = 0
        if let startTime = onboardingStartTime {
            totalTime = Date().timeIntervalSince(startTime)
        }
        
        sendTelemetryDeckEvent(name: "onboarding_completed", parameters: [
            "total_steps": "\(totalSteps)",
            "total_time_seconds": "\(Int(totalTime))",
            "apps_selected": "\(appsSelected)",
            "difficulty_level": difficultyLevel
        ])
        debugPrint("📊 Onboarding: Completed in \(Int(totalTime))s")
        
        // Reset
        onboardingStartTime = nil
        lastStepTime = nil
    }
    
    /// Call when user abandons onboarding (closes app)
    func trackOnboardingAbandoned(atStep: Int, stepName: String) {
        var totalTime: Double = 0
        if let startTime = onboardingStartTime {
            totalTime = Date().timeIntervalSince(startTime)
        }
        
        sendTelemetryDeckEvent(name: "onboarding_abandoned", parameters: [
            "abandoned_at_step": "\(atStep)",
            "step_name": stepName,
            "total_time_seconds": "\(Int(totalTime))"
        ])
        debugPrint("📊 Onboarding: Abandoned at step \(atStep) - \(stepName)")
    }
    
    // MARK: - Paywall Funnel Tracking
    
    /// Call when soft paywall is shown
    func trackSoftPaywallShown() {
        sendTelemetryDeckEvent(name: "soft_paywall_shown", parameters: [:])
    }
    
    /// Call when soft paywall is skipped
    func trackSoftPaywallSkipped() {
        sendTelemetryDeckEvent(name: "soft_paywall_skipped", parameters: [:])
    }
    
    /// Call when hard paywall is shown
    func trackHardPaywallShown() {
        sendTelemetryDeckEvent(name: "hard_paywall_shown", parameters: [:])
    }
    
    /// Call when purchase is attempted
    func trackPurchaseAttempted(productId: String, isYearly: Bool) {
        sendTelemetryDeckEvent(name: "purchase_attempted", parameters: [
            "product_id": productId,
            "is_yearly": isYearly ? "true" : "false"
        ])
    }
    
    /// Call when purchase succeeds
    func trackPurchaseCompleted(productId: String, isYearly: Bool) {
        sendTelemetryDeckEvent(name: "purchase_completed", parameters: [
            "product_id": productId,
            "is_yearly": isYearly ? "true" : "false"
        ])
    }
    
    /// Call when purchase fails
    func trackPurchaseFailed(productId: String, error: String) {
        sendTelemetryDeckEvent(name: "purchase_failed", parameters: [
            "product_id": productId,
            "error": error
        ])
    }
    
    // Send event to TelemetryDeck
    private func sendTelemetryDeckEvent(name: String, parameters: [String: String]) {
        // TelemetryDeck signal with parameters
        // Parameters are sent as a dictionary
        if parameters.isEmpty {
            TelemetryDeck.signal(name)
        } else {
            // Convert String:String dict to [String: String] for TelemetryDeck
            var signalParams: [String: String] = [:]
            for (key, value) in parameters {
                signalParams[key] = value
            }
            TelemetryDeck.signal(name, parameters: signalParams)
        }
        debugPrint("📊 TelemetryDeck: Event '\(name)' sent with params: \(parameters)")
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

