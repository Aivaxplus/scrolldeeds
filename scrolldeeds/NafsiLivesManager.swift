//
//  NafsiLivesManager.swift
//  scrolldeeds
//
//  Hearts are the only fuel for unlocked apps.
//  Difficulty decides how long one heart lasts: easy 15, medium 10, hard 5.
//  Coins buy one heart. When the last heart is gone, the apps lock.
//

import Foundation
import Combine

@MainActor
final class NafsiLivesManager: ObservableObject {
    static let shared = NafsiLivesManager()

    /// Tank size. Deeds do not change it; coins buy hearts one by one.
    static let fallbackCapacity = 5
    /// Coins needed to buy one heart.
    static let coinCostPerHeart = 40

    @Published private(set) var hearts: Int
    /// How many hearts a full tank holds.
    @Published private(set) var capacity: Int
    /// Real usage on the locked apps that one heart is worth, from the difficulty.
    @Published private(set) var minutesPerHeart: Int

    private let defaults = UserDefaults(suiteName: "group.com.scrolldeeds.app") ?? .standard
    private enum Keys {
        static let hearts = "nafsiHeartsRemaining"
        static let max = "nafsiHeartsMax"
        static let sessionStart = "nafsiHeartsSessionStart"
        static let perHeart = "nafsiMinutesPerHeart"
    }

    private init() {
        let previousPerHeart = defaults.integer(forKey: Keys.perHeart)
        let perHeart = Self.currentMinutesPerHeart()
        minutesPerHeart = perHeart
        defaults.set(perHeart, forKey: Keys.perHeart)
        // The tank is always 5. Deeds do not refill it; coins buy hearts one by one.
        capacity = Self.fallbackCapacity
        defaults.set(Self.fallbackCapacity, forKey: Keys.max)
        let stored = defaults.object(forKey: Keys.hearts) as? Int
        hearts = min(Self.fallbackCapacity, max(0, stored ?? 0))
        if previousPerHeart > 0, previousPerHeart != perHeart {
            realignBudget()
        }
    }

    /// Easy 15, medium 10, hard 5. Missing choice is medium.
    static func currentMinutesPerHeart() -> Int {
        let store = UserDefaults.standard
        let level = store.object(forKey: "onboardingDifficultyLevel") == nil
            ? 1
            : min(2, max(0, store.integer(forKey: "onboardingDifficultyLevel")))
        return UserDataManager.onboardingUnlockMinutes(forDifficultyLevel: level)
    }

    /// Minutes of app use still covered by the hearts you have.
    var minutesRemaining: Int { hearts * minutesPerHeart }

    var canBuyHeart: Bool {
        hearts < capacity && HeartJourneyManager.shared.coins >= Self.coinCostPerHeart
    }

    /// Hearts a minute budget covers at the current difficulty.
    static func heartCount(forMinutes minutes: Int) -> Int {
        let perHeart = max(5, currentMinutesPerHeart())
        let snapped = max(perHeart, (max(0, minutes) / perHeart) * perHeart)
        return max(1, snapped / perHeart)
    }

    /// Difficulty changed. Each heart you still have lasts the new length, from now.
    func applyDifficulty() {
        let perHeart = Self.currentMinutesPerHeart()
        minutesPerHeart = perHeart
        defaults.set(perHeart, forKey: Keys.perHeart)
        realignBudget()
    }

    /// Pull the latest value written by the DeviceActivity extension.
    func reloadFromDefaults() {
        let stored = defaults.object(forKey: Keys.hearts) as? Int
        let next = min(capacity, max(0, stored ?? hearts))
        if next < hearts {
            HapticManager.shared.light()
        }
        hearts = next
    }

    /// A good deed refills the tank and returns the usage budget (hearts × minutes per heart).
    @discardableResult
    func beginUnlock(forMinutes minutes: Int) -> Int {
        let count = Self.heartCount(forMinutes: minutes)
        let budget = count * minutesPerHeart
        if #available(iOS 16.0, *) {
            DeviceActivityManager.shared.prepareFreshBudget(minutes: budget)
        }
        capacity = count
        defaults.set(count, forKey: Keys.max)
        defaults.set(count, forKey: Keys.sessionStart)
        defaults.set(minutesPerHeart, forKey: Keys.perHeart)
        setHearts(count)
        return budget
    }

    /// A restarted session drains from the hearts still in the tank.
    func noteSessionHearts(_ count: Int) {
        defaults.set(max(0, count), forKey: Keys.sessionStart)
    }

    /// Call when the shield comes back on.
    func clearOnLock() {
        defaults.set(0, forKey: Keys.sessionStart)
        setHearts(0)
    }

    /// Drop one heart for every `minutesPerHeart` DeviceActivity has reported.
    /// Never refills, and never wipes hearts just because the shield flag flickered.
    func refreshFromUsage(isUnlocked: Bool) {
        guard isUnlocked else { return }
        if ShieldManager.shared.isInUnlockGracePeriod() { return }

        let start = defaults.integer(forKey: Keys.sessionStart)
        guard start > 0 else { return }

        let spent: Int
        if #available(iOS 16.0, *) {
            spent = DeviceActivityManager.shared.spentMinutes
        } else {
            return
        }

        let remaining = max(0, start - spent / minutesPerHeart)
        guard remaining < hearts else { return }
        setHearts(remaining)
        HapticManager.shared.light()
    }

    /// True once reported usage has used up every heart in this session.
    var usageHasEmptiedHearts: Bool {
        let start = defaults.integer(forKey: Keys.sessionStart)
        guard start > 0 else { return false }
        let spent: Int
        if #available(iOS 16.0, *) {
            spent = DeviceActivityManager.shared.spentMinutes
        } else {
            return hearts <= 0
        }
        return spent >= start * minutesPerHeart
    }

    /// Buy one heart with coins. Adds one heart's worth of minutes. Unlocks if the tank was empty.
    @discardableResult
    func buyHeart() -> Bool {
        guard hearts < capacity else { return false }
        guard HeartJourneyManager.shared.spendCoins(Self.coinCostPerHeart) else { return false }

        let wasEmpty = hearts == 0
        let next = hearts + 1
        minutesPerHeart = Self.currentMinutesPerHeart()
        let minutes = next * minutesPerHeart

        // Reset the usage counter before publishing hearts, so a refresh
        // cannot subtract the previous session's minutes from the new heart.
        if #available(iOS 16.0, *) {
            DeviceActivityManager.shared.prepareFreshBudget(minutes: minutes)
        }
        defaults.set(next, forKey: Keys.sessionStart)
        defaults.set(minutesPerHeart, forKey: Keys.perHeart)
        setHearts(next)

        if wasEmpty {
            _ = ShieldManager.shared.completeUnlockSession(minutesEarned: minutes)
        } else if #available(iOS 16.0, *) {
            DeviceActivityManager.shared.startUsageMonitoring(
                allowedMinutes: minutes,
                extendExistingBudget: false
            )
        }
        return true
    }

    /// Restart the live budget so remaining hearts use the current duration.
    private func realignBudget() {
        guard hearts > 0 else { return }
        let budget = hearts * minutesPerHeart
        defaults.set(hearts, forKey: Keys.sessionStart)
        defaults.set(minutesPerHeart, forKey: Keys.perHeart)
        if #available(iOS 16.0, *) {
            DeviceActivityManager.shared.prepareFreshBudget(minutes: budget)
            if ShieldManager.shared.hasActiveUnlockSession() {
                DeviceActivityManager.shared.startUsageMonitoring(
                    allowedMinutes: budget,
                    extendExistingBudget: false
                )
            }
        }
    }

    private func setHearts(_ value: Int) {
        let clamped = min(capacity, max(0, value))
        hearts = clamped
        defaults.set(clamped, forKey: Keys.hearts)
        defaults.set(capacity, forKey: Keys.max)
    }
}
