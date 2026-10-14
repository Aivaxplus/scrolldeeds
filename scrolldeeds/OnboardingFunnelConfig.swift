//
//  OnboardingFunnelConfig.swift
//  scrolldeeds
//
//  CRO funnel switches. Hidden steps are NOT deleted — flip flags to restore.
//

import Foundation

enum OnboardingFunnelConfig {

    // MARK: - Master switch

    /// `true` = optimized CRO funnel. `false` = full legacy questionnaire order.
    static let useShortFunnel = true

    // MARK: - Post-questionnaire / paywall

    /// Skip optional referral-code screen; go Commitment → (first win) → HardPaywall.
    static let hideReferralCodeScreen = true

    /// Skip 4-page Quick Guide after purchase. Guide stays available in Settings.
    static let hideQuickGuide = true

    /// Paywall loading theater: ~2.5s instead of ~9.2s.
    static let shortenPaywallLoading = true

    /// Skip notifications / “Continue for FREE” step; planReady → pricing.
    static let hidePaywallReminderStep = true

    /// Do not show ATT on cold first launch; ask after onboarding completes.
    static let deferATTUntilAfterOnboarding = true

    /// Real PracticeSessionView once after commitment, before hard paywall (no Screen Time unlock).
    /// Hidden for now — life_change goes straight into paywall loading.
    static let showFirstDeedBeforePaywall = false

    /// Just Pray–style conversion paywall (promise → sales → yearly/weekly pricing).
    /// When `true`, mounts `ConversionPaywallView` instead of `HardPaywallView`.
    static let useConversionPaywall = true

    /// Skip hold-to-commit `CommitmentView`; promise+signature lives inside the conversion paywall.
    static let hideCommitmentBeforePaywall = true

    // MARK: - Narrative pacing

    /// Gap between copy beats on non-typewriter pages (name, cards, questions).
    static let narrativeDelayPerElement: Double = 0.85
    /// Fade-in for non-typewriter beats.
    static let narrativeFadeDuration: Double = 0.70
    /// Stagger on demo / allow-notifications (cards + copy must be readable).
    static let showcaseDelayPerElement: Double = 1.40
    /// Fade-in on demo / allow-notifications.
    static let showcaseFadeDuration: Double = 1.05
    /// Hold after a typewriter page finishes before auto-advance.
    static let autoAdvanceHoldSeconds: Double = 1.6
    /// Hold after life-change copy is fully revealed before auto-advance.
    static let lifeChangeAutoAdvanceSeconds: Double = 5.6

    // MARK: - Optimized conviction funnel (psychological arc)

    /// Order: hook → name/bond → hours+apps → impact → mood → hope → mechanism →
    /// notify → how it works → demo → widget desire → close → social proof.
    /// Commented IDs remain in the catalog (hidden, not deleted).
    /// Keep `not_alone` immediately after `feeling`.
    static let shortFunnelStepIDs: [String] = [
        // "welcome",
        "benefits_reflection",
        "sabri_intro",
        "name",
        "reflection",

        "intention",
        "screen_time",
        "apps_consume",
        // "consider_this",
        // "age",
        "impact_stats",

        "feeling",
        "not_alone",
        "control",
        "tried_stop",
        "chances",
        "barrier",
        "extra_minutes",
        "late_night",
        "fajr",
        "fajr_wake",
        "fajr_setup",
        "prayers",
        "been_there",
        "honest_thanks",
        "reminder_need",
        "allow_notifications",
        "daily_reminder_count",
        "patience_quote",

        // "plan_intro",
        "prayer_lock",
        "demo_notification",
        "interactive_demo",
        "streak_preview",
        "widget_distraction",
        "widget_desire",

        "join",
        // "guide_muslims",

        // After join: CommitmentView / life-change → paywall → Thank You →
        // lock apps → guide other Muslims (review) → difficulty
        // "life_change",

        // Post-paywall (Thank You → ForceAppSelection → difficulty), not onboarding:
        // "app_selection",
        // "difficulty",

        // Hidden (not deleted): spiritual / config questions after social proof
        // "not_lack_iman",
        // "acknowledge",
        // "brave",
        // "tried_before",
        // "transformation_after",
        // "committed_question",
        // "journey_commitment",
        // "did_it",
    ]

    static func resolveQuestionnaireSteps(
        _ catalog: [(id: String, step: OnboardingStepType)]
    ) -> [OnboardingStepType] {
        resolveQuestionnaire(catalog).map(\.step)
    }

    /// The catalog ids of the resolved funnel, in order. Analytics uses these as the
    /// `step_identifier` so reordering the funnel never breaks a PostHog insight.
    static func resolveQuestionnaireStepIDs(
        _ catalog: [(id: String, step: OnboardingStepType)]
    ) -> [String] {
        resolveQuestionnaire(catalog).map(\.id)
    }

    private static func resolveQuestionnaire(
        _ catalog: [(id: String, step: OnboardingStepType)]
    ) -> [(id: String, step: OnboardingStepType)] {
        if !useShortFunnel {
            return catalog
        }
        let map = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0.step) })
        return shortFunnelStepIDs.compactMap { id in
            guard let step = map[id] else {
                #if DEBUG
                print("⚠️ OnboardingFunnelConfig: missing step id '\(id)' in catalog")
                #endif
                return nil
            }
            return (id: id, step: step)
        }
    }
}
