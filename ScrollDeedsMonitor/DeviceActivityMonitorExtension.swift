//
//  DeviceActivityMonitorExtension.swift
//  ScrollDeedsMonitor
//
//  Runs in a SEPARATE extension process managed by iOS.
//  iOS calls `eventDidReachThreshold` when the user has spent the earned
//  usage budget on the selected apps. The extension applies the ManagedSettings
//  shield AUTOMATICALLY — even when the main app is closed or the phone is locked.
//
//  Flow:
//  1. User completes a deed → main app calls DeviceActivityCenter.startMonitoring()
//     with a usage threshold (e.g. 60 minutes on selected apps).
//  2. iOS tracks actual screen time on those apps in the background.
//  3. When threshold is reached, iOS wakes this extension and calls
//     eventDidReachThreshold(_:activity:).
//  4. We apply the ManagedSettingsStore shield here → apps lock immediately,
//     without the user needing to open ScrollDeeds.
//

import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls
import UserNotifications

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let appGroupID = "group.com.scrolldeeds.app"

    // MARK: - Schedule callbacks

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        debugPrint("📱 DeviceActivityMonitor: Interval started for \(activity.rawValue)")
    }

    /// Called at the end of the daily schedule window (midnight).
    /// Do NOT lock here solely because `unlockEndTime` exists — that key is the 24h safety cap,
    /// not session expiry. Real enforcement is usage threshold in `eventDidReachThreshold`.
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        let defaults = UserDefaults(suiteName: appGroupID)
        let hasUsageBudget = (defaults?.integer(forKey: "deviceActivityAllowedMinutes") ?? 0) > 0
        let unlockCapStillValid: Bool = {
            guard let cap = defaults?.object(forKey: "unlockEndTime") as? Date else { return false }
            return cap > Date()
        }()
        if hasUsageBudget && unlockCapStillValid {
            debugPrint("📱 DeviceActivityMonitor: Day ended but unlock session still valid — skipping midnight lock")
            return
        }
        debugPrint("📱 DeviceActivityMonitor: Day ended — usage threshold handles locking; not locking at midnight")
    }

    // MARK: - Usage threshold

    /// Called by iOS when a monitored usage milestone is reached.
    /// Progress events only record spent minutes for the heart; the final
    /// threshold event locks apps (unchanged behaviour).
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        let raw = event.rawValue
        let progressPrefix = "scrolldeeds.usage.progress."
        if raw.hasPrefix(progressPrefix),
           let minutes = Int(raw.dropFirst(progressPrefix.count)),
           minutes > 0 {
            // Ignore spikes during the short post-deed grace window.
            // The shortest heart is 5 minutes, and the grace window is shorter than that.
            let defaults = UserDefaults(suiteName: appGroupID)
            if let graceEnd = defaults?.object(forKey: "unlockGracePeriodUntil") as? Date, graceEnd > Date() {
                debugPrint("⏳ DeviceActivityMonitor: Grace period — ignoring \(minutes) min progress")
                return
            }
            recordUsageProgress(minutes)
            return
        }

        debugPrint("🔒🔒🔒 DeviceActivityMonitor: Usage threshold REACHED — AUTO-LOCKING NOW!")
        applyShieldAndLock()
    }

    /// Persist real monitored usage so the main app can darken the heart on next open.
    private func recordUsageProgress(_ minutes: Int) {
        let defaults = UserDefaults(suiteName: appGroupID)
        let previous = defaults?.integer(forKey: "deviceActivitySpentMinutes") ?? 0
        let next = max(previous, minutes)
        defaults?.set(next, forKey: "deviceActivitySpentMinutes")
        syncHeartsRemaining(spent: next, defaults: defaults)
        debugPrint("💚 DeviceActivityMonitor: Usage progress — \(next) min spent on selected apps")
    }

    /// One heart per difficulty length (5, 10, or 15). The session started with `nafsiHeartsSessionStart` hearts.
    private func syncHeartsRemaining(spent: Int, defaults: UserDefaults?) {
        let stored = defaults?.integer(forKey: "nafsiMinutesPerHeart") ?? 0
        let perHeart = [5, 10, 15].contains(stored) ? stored : 10
        var start = defaults?.integer(forKey: "nafsiHeartsSessionStart") ?? 0
        if start <= 0 {
            let allowed = defaults?.integer(forKey: "deviceActivityAllowedMinutes") ?? 0
            start = max(1, allowed / perHeart)
        }
        let expected = max(0, start - spent / perHeart)
        let current = defaults?.integer(forKey: "nafsiHeartsRemaining") ?? start
        if expected < current {
            defaults?.set(expected, forKey: "nafsiHeartsRemaining")
        }
    }

    // MARK: - Shield application

    private func applyShieldAndLock() {
        let defaults = UserDefaults(suiteName: appGroupID)

        // Never auto-lock during the post-deed grace window (guards against false thresholds on iOS 16).
        if let graceEnd = defaults?.object(forKey: "unlockGracePeriodUntil") as? Date, graceEnd > Date() {
            debugPrint("⏳ DeviceActivityMonitor: Grace period active — skipping auto-lock, will restart monitoring later")
            defaults?.set(true, forKey: "deviceActivityNeedsRestart")
            return
        }

        guard let data = defaults?.data(forKey: "familyActivitySelection") else {
            debugPrint("⚠️ DeviceActivityMonitor: No saved app selection found")
            return
        }

        do {
            let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)

            guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
                debugPrint("⚠️ DeviceActivityMonitor: Selection has no app or category tokens")
                return
            }

            // Apply the shield using the same named store as the main app
            let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("scrolldeeds.shield"))
            store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
            store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
            store.shield.webDomains = nil

            // Persist real scroll minutes for heart health BEFORE clearing session keys.
            // Threshold lock means the full budget was used (last progress event may be slightly under).
            commitHeartScrollMinutes(defaults: defaults)

            // Sync state to shared defaults so the main app UI updates on next launch
            defaults?.removeObject(forKey: "unlockEndTime")
            defaults?.removeObject(forKey: "unlockGracePeriodUntil")
            defaults?.removeObject(forKey: "lastUnlockCompletedAt")
            defaults?.removeObject(forKey: "deviceActivityAllowedMinutes")
            defaults?.removeObject(forKey: "deviceActivitySessionStart")
            defaults?.removeObject(forKey: "deviceActivityNeedsRestart")
            defaults?.removeObject(forKey: "deviceActivitySpentMinutes")
            defaults?.set(0, forKey: "nafsiHeartsRemaining")
            defaults?.set(0, forKey: "nafsiHeartsSessionStart")
            defaults?.set(true, forKey: "isShieldActive")

            debugPrint("✅ DeviceActivityMonitor: Shield applied — \(selection.applicationTokens.count) app token(s), \(selection.categoryTokens.count) categor(y/ies) — auto-lock complete!")
            debugPrint("✅ Apps are now locked. User does not need to open ScrollDeeds.")

            sendAutoLockNotification()

        } catch {
            debugPrint("❌ DeviceActivityMonitor: Failed to decode selection or apply shield: \(error)")
        }
    }

    // MARK: - Heart scroll ledger (App Group — mirrors main app UserDataManager)

    private func commitHeartScrollMinutes(defaults: UserDefaults?) {
        guard let defaults else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayKey = "heartScrollDayStart"
        let minutesKey = "heartTodayScrollMinutes"
        let committedKey = "heartCommittedSessionStart"

        if let stored = defaults.object(forKey: dayKey) as? Date,
           !calendar.isDate(stored, inSameDayAs: today) {
            defaults.set(today, forKey: dayKey)
            defaults.set(0, forKey: minutesKey)
        } else if defaults.object(forKey: dayKey) == nil {
            defaults.set(today, forKey: dayKey)
        }

        let sessionStart = defaults.object(forKey: "deviceActivitySessionStart") as? Date
        let startInterval = sessionStart?.timeIntervalSince1970 ?? 0
        if startInterval > 0, defaults.double(forKey: committedKey) == startInterval {
            return
        }

        let spent = max(0, defaults.integer(forKey: "deviceActivitySpentMinutes"))
        let allowed = max(0, defaults.integer(forKey: "deviceActivityAllowedMinutes"))
        let minutes = max(spent, allowed)
        if minutes > 0 {
            let current = max(0, defaults.integer(forKey: minutesKey))
            defaults.set(current + minutes, forKey: minutesKey)
            debugPrint("💚 DeviceActivityMonitor: Committed \(minutes) scroll min → heart total \(current + minutes)")
        }
        if startInterval > 0 {
            defaults.set(startInterval, forKey: committedKey)
        }
    }

    // MARK: - Auto-lock notification

    /// Sends a local notification immediately after the shield is applied by the extension.
    /// This replaces the old wall-clock "unlock expiry" notifications.
    private func sendAutoLockNotification() {
        let center = UNUserNotificationCenter.current()

        // Cancel any pending "locked app reminder" and old expiry notifications to avoid duplicates.
        center.getPendingNotificationRequests { requests in
            let toRemove = requests
                .filter { $0.identifier.starts(with: "locked_app_reminder_") || $0.identifier.starts(with: "unlock_expired_") }
                .map { $0.identifier }
            if !toRemove.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: toRemove)
            }
        }

        let content = UNMutableNotificationContent()
        content.title = "Nafsi"
        content.body = localizedString("notification.autolock.body")
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "DHIKR_REMINDER"
        content.userInfo = ["auto_locked": true]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "auto_lock_notification",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                debugPrint("❌ DeviceActivityMonitor: Failed to send auto-lock notification: \(error)")
            } else {
                debugPrint("✅ DeviceActivityMonitor: Auto-lock notification sent")
            }
        }

        // Immediate auto-lock + 2 follow-ups = max 3 per session (onboarding promise)
        let followUpIntervals: [Double] = [30 * 60, 2 * 3600]
        let followUpKeys = [
            "notification.autolock.followup1.body",
            "notification.autolock.followup2.body"
        ]

        for (i, interval) in followUpIntervals.enumerated() {
            let followContent = UNMutableNotificationContent()
            followContent.title = "Nafsi"
            followContent.body = localizedString(followUpKeys[i])
            followContent.sound = .default
            followContent.badge = 1
            followContent.categoryIdentifier = "DHIKR_REMINDER"
            followContent.userInfo = ["auto_locked": true, "followup": i + 1]

            let followTrigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let followRequest = UNNotificationRequest(
                identifier: "auto_lock_followup_\(i + 1)",
                content: followContent,
                trigger: followTrigger
            )
            center.add(followRequest) { _ in }
        }
    }

    /// Follows the in-app language stored in the App Group (not the iPhone system language).
    private func localizedString(_ key: String) -> String {
        let raw = UserDefaults(suiteName: appGroupID)?.string(forKey: "AppLanguage")
        let code: String
        if let raw, ["en", "nl", "es", "de", "fr", "ru", "ar"].contains(raw) {
            code = raw
        } else {
            code = Locale.current.language.languageCode?.identifier ?? "en"
            if !["en", "nl", "es", "de", "fr", "ru", "ar"].contains(code) {
                return bundleString(key, language: "en")
            }
        }
        let value = bundleString(key, language: code)
        if value != key, !value.isEmpty { return value }
        return bundleString(key, language: "en")
    }

    private func bundleString(_ key: String, language: String) -> String {
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        return NSLocalizedString(key, bundle: Bundle.main, comment: "")
    }
}

// MARK: - Debug helper
#if DEBUG
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#else
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#endif
