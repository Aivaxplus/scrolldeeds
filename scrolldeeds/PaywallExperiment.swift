//
//  PaywallExperiment.swift
//  scrolldeeds
//
//  Onboarding paywall A/B — layout + trial:
//  - `classic`: sales scroll + yearly/monthly sheet with a 3-day free trial
//  - `program_ready`: compact “your program is ready” screen with yearly + weekly, no trial
//
//  Assignment is sticky per install and 50/50.
//  PostHog multivariate flag `paywall-layout` wins when it returns a valid arm;
//  otherwise a local coin flip.
//

import Combine
import Foundation
import PostHog

enum PaywallExperimentArm: String {
    case classic = "classic"
    case programReady = "program_ready"
}

@MainActor
final class PaywallExperiment: ObservableObject {
    static let shared = PaywallExperiment()

    /// Multivariate feature flag in PostHog. Values must match `PaywallExperimentArm.rawValue`.
    static let flagKey = "paywall-layout"

    @Published private(set) var arm: PaywallExperimentArm = .classic
    @Published private(set) var isAssigned = false

    private let assignedKey = "paywall_layout_arm"
    private let assignedEventKey = "paywall_layout_assigned_tracked"
    private let assignedSourceKey = "paywall_layout_source"
    private let legacyAssignedKey = "paywall_experiment_arm"

    private init() {
        let source = UserDefaults.standard.string(forKey: assignedSourceKey)
        if source == "forced" {
            // Preview override must not stick — otherwise the live split is not 50/50.
            clearAssignment()
            return
        }

        if let stored = UserDefaults.standard.string(forKey: assignedKey),
           let existing = PaywallExperimentArm(rawValue: stored) {
            arm = existing
            isAssigned = true
            return
        }

        if let legacy = UserDefaults.standard.string(forKey: legacyAssignedKey) {
            let mapped: PaywallExperimentArm = legacy == "with_trial" ? .programReady : .classic
            persist(mapped, source: "migrated")
        }
    }

    /// Idempotent. Call after PostHog identify / flag reload, and again when the paywall appears.
    func resolve() {
        if isAssigned { return }

        if let flag = PostHogSDK.shared.getFeatureFlag(Self.flagKey) as? String,
           let remote = PaywallExperimentArm(rawValue: flag) {
            persist(remote, source: "posthog")
            return
        }

        persist(Self.coinFlipArm(), source: "local")
    }

    /// Exactly 50/50. `Bool.random()` is also fair, but an explicit 0/1 draw is clearer.
    private static func coinFlipArm() -> PaywallExperimentArm {
        Int.random(in: 0...1) == 0 ? .classic : .programReady
    }

    private func clearAssignment() {
        arm = .classic
        isAssigned = false
        UserDefaults.standard.removeObject(forKey: assignedKey)
        UserDefaults.standard.removeObject(forKey: assignedSourceKey)
        UserDefaults.standard.removeObject(forKey: assignedEventKey)
    }

    private func persist(_ assigned: PaywallExperimentArm, source: String) {
        arm = assigned
        isAssigned = true
        UserDefaults.standard.set(assigned.rawValue, forKey: assignedKey)
        UserDefaults.standard.set(source, forKey: assignedSourceKey)

        PostHogSDK.shared.identify(
            UserDataManager.shared.userID,
            userProperties: [
                "paywall_variant": assigned.rawValue,
                "paywall_experiment": Self.flagKey
            ]
        )

        guard !UserDefaults.standard.bool(forKey: assignedEventKey) else { return }
        UserDefaults.standard.set(true, forKey: assignedEventKey)
        PostHogManager.shared.track("Paywall Experiment Assigned", properties: [
            "paywall_variant": assigned.rawValue,
            "assignment_source": source,
            "experiment": Self.flagKey
        ])
        debugPrint("🧪 Paywall experiment: \(assigned.rawValue) via \(source)")
    }
}

#if DEBUG
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#else
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
}
#endif
