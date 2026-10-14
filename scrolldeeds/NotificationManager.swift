//
//  NotificationManager.swift
//  scrolldeeds
//
//  Manages push notifications for dhikr reminders and unlock timer
//

import SwiftUI
import UIKit
import UserNotifications
import Combine

// MARK: - Debug Helper
#if DEBUG
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#else
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // No-op in production
}
#endif

enum SpiritualContentFilter: String, CaseIterable, Identifiable {
    case all
    case quran
    case sunnah
    case reminder

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .all: return "questionnaire.daily_reminder_type.all"
        case .quran: return "questionnaire.daily_reminder_type.quran"
        case .sunnah: return "questionnaire.daily_reminder_type.sunnah"
        case .reminder: return "questionnaire.daily_reminder_type.reminder"
        }
    }

    var title: String {
        NSLocalizedString(titleKey, comment: "")
    }
}

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isAuthorized: Bool = false
    @Published var notificationsEnabled: Bool = true
    /// Quran / sunnah / reminder nudges spread across the day.
    @Published var dailySpiritualCount: Int = 4
    @Published var dailySpiritualFilter: SpiritualContentFilter = .all

    static let shared = NotificationManager()

    /// Hard cap matching onboarding (“up to three times per session”).
    static let maxRemindersPerLockSession = 3
    static let minDailySpiritualCount = 1
    static let maxDailySpiritualCount = 10

    private let notificationsEnabledKey = "notifications_enabled"
    private let dailySpiritualCountKey = "daily_spiritual_notification_count"
    private let dailySpiritualFilterKey = "daily_spiritual_notification_filter"
    private var becomeActiveCancelWork: DispatchWorkItem?
    private var lastLockRelatedCancelAt: Date?
    private var lastBackgroundHandleAt: Date?
    /// True after we silenced conversion + lock nudges for an active unlock session.
    /// Prevents the 1s shield timer from repeatedly hitting the notification center.
    private var notificationsAdaptedToUnlock = false

    private override init() {
        super.init()
        if UserDefaults.standard.object(forKey: notificationsEnabledKey) != nil {
            notificationsEnabled = UserDefaults.standard.bool(forKey: notificationsEnabledKey)
        }
        let storedCount = UserDefaults.standard.integer(forKey: dailySpiritualCountKey)
        if storedCount >= Self.minDailySpiritualCount {
            dailySpiritualCount = min(storedCount, Self.maxDailySpiritualCount)
        }
        if let raw = UserDefaults.standard.string(forKey: dailySpiritualFilterKey),
           let filter = SpiritualContentFilter(rawValue: raw) {
            dailySpiritualFilter = filter
        }
        checkAuthorizationStatus()
        // Set this instance as the delegate to handle notifications
        UNUserNotificationCenter.current().delegate = self
    }

    /// In-app master switch for ScrollDeeds notifications (separate from iOS permission).
    func setNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: notificationsEnabledKey)
        if !enabled {
            clearAllNotifications()
        } else {
            scheduleDailySpiritualReminders()
        }
    }

    func setDailySpiritualCount(_ count: Int) {
        let clamped = min(max(count, Self.minDailySpiritualCount), Self.maxDailySpiritualCount)
        dailySpiritualCount = clamped
        UserDefaults.standard.set(clamped, forKey: dailySpiritualCountKey)
        let widget = NafsiWidgetSettings.shared
        widget.reminderCadenceMinutes = 0
        widget.reminderMinutes = NafsiWidgetSettings.spreadMinutes(count: clamped)
        widget.save()
    }

    func setDailySpiritualFilter(_ filter: SpiritualContentFilter) {
        dailySpiritualFilter = filter
        UserDefaults.standard.set(filter.rawValue, forKey: dailySpiritualFilterKey)
        scheduleDailySpiritualReminders()
    }

    func previewSpiritualNotification() -> (title: String, body: String) {
        if let quote = notificationPool().first {
            let body = quote.text + (quote.reference.isEmpty ? "" : " — " + quote.reference)
            return (quote.reference, body)
        }
        return (
            LanguageManager.shared.localizedString("widget.kind.quran"),
            LanguageManager.shared.localizedString("questionnaire.widget_desire.fallback_verse")
        )
    }

    private func guardSchedulingEnabled() -> Bool {
        guard notificationsEnabled else {
            debugPrint("🔕 Notifications disabled in app settings — skipping schedule")
            return false
        }
        return true
    }

    fileprivate func debugLogPendingNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            debugPrint("🔔 Notification permission: \(settings.authorizationStatus.rawValue) (2=authorized, 3=provisional, 1=denied, 0=notDetermined)")
        }
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).sorted()
            debugPrint("🔔 Pending notifications (\(ids.count)): \(ids)")
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.registerCategories()
                }
            }
        }
    }
    
    /// Request permission with completion handler
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.registerCategories()
                    if !ShieldManager.shared.hasActiveUnlockSession() {
                        self.ensureReengagementScheduled(includeImmediateKickoff: false)
                    }
                    self.scheduleDailySpiritualReminders()
                    self.debugLogPendingNotifications()
                }
                completion(granted)
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                if self.isAuthorized {
                    self.registerCategories()
                    if self.notificationsEnabled {
                        self.scheduleDailySpiritualReminders()
                    }
                }
            }
        }
    }

    // MARK: - Trial reminders (local 3-day trial)

    func scheduleTrialEndingReminder(on date: Date, hoursBefore: Int) {
        guard guardSchedulingEnabled() else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["trial_ending_reminder"])

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.trial_ending.title", comment: "Trial Ending Soon")
        content.body = String(format: NSLocalizedString("notification.trial_ending.body.hours", comment: ""), hoursBefore)
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TRIAL_REMINDER"
        content.userInfo = ["trial_reminder": true, "hours_before": hoursBefore]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "trial_ending_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Failed to schedule trial ending reminder: \(error)")
            } else {
                debugPrint("✅ Trial ending reminder scheduled for \(date) (\(hoursBefore)h before end)")
            }
        }
    }

    func cancelTrialEndingReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["trial_ending_reminder"])
    }

    func scheduleTrialExpiryNotification(expiresAt: Date) {
        guard guardSchedulingEnabled() else { return }
        cancelTrialExpiryNotification()

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.trial_expired.title", comment: "Free Trial Ended")
        content.body = NSLocalizedString("notification.trial_expired.body", comment: "")
        content.sound = .default
        content.badge = 1

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: expiresAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "trial_expired",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Failed to schedule trial expiry notification: \(error)")
            } else {
                debugPrint("✅ Trial expiry notification scheduled for: \(expiresAt)")
            }
        }
    }

    func cancelTrialExpiryNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["trial_expired"])
    }

    // MARK: - App Store intro-offer trial (yearly plan)

    private static let storeTrialDayBeforeIdentifier = "store_trial_day_before"
    private static let storeTrialLastHoursIdentifier = "store_trial_last_hours"

    /// Two reminders before an App Store trial lapses: one day out and a few hours out.
    /// Only call this for users whose auto-renew is already off — they are the ones who churn.
    func scheduleStoreTrialEndingReminders(expiresAt: Date) {
        guard guardSchedulingEnabled() else { return }
        cancelStoreTrialReminders()

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self else { return }
            let authorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            guard authorized else {
                debugPrint("🔕 Store trial reminders: notifications not authorized, skipping")
                return
            }

            DispatchQueue.main.async {
                self.scheduleStoreTrialReminder(
                    identifier: Self.storeTrialDayBeforeIdentifier,
                    fireAt: expiresAt.addingTimeInterval(-24 * 60 * 60),
                    title: NSLocalizedString("notification.trial_last_day.title", comment: "Your access ends tomorrow"),
                    body: NSLocalizedString("notification.trial_last_day.body", comment: "")
                )
                self.scheduleStoreTrialReminder(
                    identifier: Self.storeTrialLastHoursIdentifier,
                    fireAt: expiresAt.addingTimeInterval(-3 * 60 * 60),
                    title: NSLocalizedString("notification.trial_last_hours.title", comment: "A few hours left"),
                    body: NSLocalizedString("notification.trial_last_hours.body", comment: "")
                )
            }
        }
    }

    private func scheduleStoreTrialReminder(identifier: String, fireAt: Date, title: String, body: String) {
        guard fireAt > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TRIAL_REMINDER"
        content.threadIdentifier = "scrolldeeds_conversion"
        content.userInfo = ["store_trial_reminder": true]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Store trial reminder \(identifier) failed: \(error.localizedDescription)")
            } else {
                debugPrint("✅ Store trial reminder \(identifier) scheduled for \(fireAt)")
            }
        }
    }

    func cancelStoreTrialReminders() {
        let ids = [Self.storeTrialDayBeforeIdentifier, Self.storeTrialLastHoursIdentifier]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Win-back after a subscription lapsed

    /// Separate from the re-engagement series: these people already know the product,
    /// so the copy is about what they just lost instead of what they might gain.
    private static let subscriptionWinbackOffsets: [TimeInterval] = [
        1 * 60 * 60,
        24 * 60 * 60,
        72 * 60 * 60,
        168 * 60 * 60
    ]

    /// - Parameter anchor: the moment access ends (entitlement expiry), so the series can be
    ///   scheduled while the subscription is still active and stays stable across app launches.
    func scheduleSubscriptionWinbackSeries(anchor: Date) {
        guard guardSchedulingEnabled() else { return }
        cancelSubscriptionWinbackSeries()

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            guard authorized else {
                debugPrint("🔕 Win-back series: notifications not authorized, skipping")
                return
            }

            DispatchQueue.main.async {
                for (index, offset) in Self.subscriptionWinbackOffsets.enumerated() {
                    let fireAt = anchor.addingTimeInterval(offset)
                    guard fireAt > Date() else { continue }

                    let content = UNMutableNotificationContent()
                    content.title = NSLocalizedString("notification.winback.\(index + 1).title", comment: "")
                    content.body = NSLocalizedString("notification.winback.\(index + 1).body", comment: "")
                    content.sound = .default
                    content.badge = 1
                    content.categoryIdentifier = "REENGAGEMENT"
                    content.threadIdentifier = "scrolldeeds_conversion"
                    content.userInfo = ["subscription_winback": true, "notification_index": index]

                    let components = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: fireAt
                    )
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "subscription_winback_\(index)",
                        content: content,
                        trigger: trigger
                    )

                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            debugPrint("❌ Win-back \(index) failed: \(error.localizedDescription)")
                        } else {
                            debugPrint("✅ Win-back \(index) scheduled for \(fireAt)")
                        }
                    }
                }
            }
        }
    }

    func cancelSubscriptionWinbackSeries() {
        let ids = Self.subscriptionWinbackOffsets.indices.map { "subscription_winback_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
    }

    private func registerCategories() {
        // Actions for notifications
        let unlockAction = UNNotificationAction(
            identifier: "UNLOCK_ACTION",
            title: NSLocalizedString("notification.unlock_now", comment: "Unlock Now"),
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: NSLocalizedString("notification.remind_later", comment: "Remind Me Later"),
            options: []
        )
        
        // Category for unlock timer expiry
        let unlockCategory = UNNotificationCategory(
            identifier: "UNLOCK_EXPIRED",
            actions: [unlockAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Category for dhikr reminders
        let reminderCategory = UNNotificationCategory(
            identifier: "DHIKR_REMINDER",
            actions: [unlockAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Category for blocked app access attempt
        let blockedAppCategory = UNNotificationCategory(
            identifier: "BLOCKED_APP_ATTEMPT",
            actions: [unlockAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let fajrPhotoAction = UNNotificationAction(
            identifier: "FAJR_PHOTO",
            title: NSLocalizedString("fajr.alarmkit.open", comment: "Take photo"),
            options: .foreground
        )
        let fajrSnoozeAction = UNNotificationAction(
            identifier: "FAJR_SNOOZE",
            title: NSLocalizedString("fajr.ring.snooze", comment: "Snooze 5 minutes"),
            options: []
        )
        let fajrCategory = UNNotificationCategory(
            identifier: "FAJR_ALARM",
            actions: [fajrPhotoAction, fajrSnoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let spiritualCategory = UNNotificationCategory(
            identifier: "SPIRITUAL_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            unlockCategory, reminderCategory, blockedAppCategory, fajrCategory, spiritualCategory
        ])
    }

    /// Rewrite pending local notifications in the current in-app language, keeping fire times.
    /// iOS stores title/body as plain strings at schedule time — they do not follow Settings → Language.
    func refreshPendingNotificationsForCurrentLanguage() {
        registerCategories()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            for request in requests {
                guard let content = self.relocalizedContent(for: request) else { continue }
                let trigger = self.preservedTrigger(request.trigger)
                let updated = UNNotificationRequest(
                    identifier: request.identifier,
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(updated) { error in
                    if let error {
                        debugPrint("❌ Failed to relocalize \(request.identifier): \(error.localizedDescription)")
                    }
                }
            }
            debugPrint("🌐 Relocalized \(requests.count) pending notifications")
        }
    }

    private func preservedTrigger(_ trigger: UNNotificationTrigger?) -> UNNotificationTrigger? {
        if let calendar = trigger as? UNCalendarNotificationTrigger {
            return UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents, repeats: calendar.repeats)
        }
        if let interval = trigger as? UNTimeIntervalNotificationTrigger,
           let next = interval.nextTriggerDate() {
            let remaining = next.timeIntervalSinceNow
            if remaining > 1 {
                return UNTimeIntervalNotificationTrigger(timeInterval: remaining, repeats: interval.repeats)
            }
        }
        return trigger
    }

    private func relocalizedContent(for request: UNNotificationRequest) -> UNMutableNotificationContent? {
        let id = request.identifier
        let info = request.content.userInfo
        var title = request.content.title
        var body = request.content.body
        let savedName = UserDefaults.standard.string(forKey: "userName")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let name = (savedName?.isEmpty == false) ? savedName : nil

        if id == "trial_ending_reminder" {
            let hours = info["hours_before"] as? Int ?? 24
            title = NSLocalizedString("notification.trial_ending.title", comment: "")
            body = String(format: NSLocalizedString("notification.trial_ending.body.hours", comment: ""), hours)
        } else if id == "trial_expired" {
            title = NSLocalizedString("notification.trial_expired.title", comment: "")
            body = NSLocalizedString("notification.trial_expired.body", comment: "")
        } else if id == "store_trial_day_before" {
            title = NSLocalizedString("notification.trial_last_day.title", comment: "")
            body = NSLocalizedString("notification.trial_last_day.body", comment: "")
        } else if id == "store_trial_last_hours" {
            title = NSLocalizedString("notification.trial_last_hours.title", comment: "")
            body = NSLocalizedString("notification.trial_last_hours.body", comment: "")
        } else if id.hasPrefix("subscription_winback_"),
                  let index = Int(id.replacingOccurrences(of: "subscription_winback_", with: "")) {
            title = NSLocalizedString("notification.winback.\(index + 1).title", comment: "")
            body = NSLocalizedString("notification.winback.\(index + 1).body", comment: "")
        } else if id == FajrAlarmManager.notificationId || id == FajrAlarmManager.snoozeNotificationId {
            title = NSLocalizedString("fajr.notification.title", comment: "")
            body = String(
                format: NSLocalizedString("fajr.notification.body", comment: ""),
                FajrAlarmManager.shared.objectName
            )
        } else if id == "unlock_expired_initial" {
            title = NSLocalizedString("notification.session_complete.title", comment: "")
            body = NSLocalizedString("notification.session_complete.body", comment: "")
        } else if id.hasPrefix("unlock_expired_alarm_") || id.hasPrefix("daily_recurring_alarm_") {
            body = NSLocalizedString("notification.alarm.1", comment: "")
            title = NSLocalizedString("notification.app_name", comment: "ScrollDeeds")
        } else if id.hasPrefix("locked_app_reminder_after_tap_") {
            let n = Int(id.replacingOccurrences(of: "locked_app_reminder_after_tap_", with: "")) ?? 1
            let keys = ["notification.locked_app.1", "notification.locked_app.2", "notification.locked_app.3"]
            title = NSLocalizedString("notification.app_name", comment: "ScrollDeeds")
            body = NSLocalizedString(keys[(n - 1) % keys.count], comment: "")
        } else if id.hasPrefix("locked_app_reminder_") {
            let n = Int(id.replacingOccurrences(of: "locked_app_reminder_", with: "")) ?? 1
            let keys = ["notification.locked_app.1", "notification.locked_app.2", "notification.locked_app.9"]
            title = NSLocalizedString("notification.app_name", comment: "ScrollDeeds")
            body = NSLocalizedString(keys[(n - 1) % keys.count], comment: "")
        } else if id.hasPrefix("spiritual_"),
                  let quoteId = info["quoteId"] as? String,
                  let quote = NafsiQuoteCatalog.quotes(language: LanguageManager.shared.currentLanguage)
                    .first(where: { $0.id == quoteId }) {
            title = quote.reference
            body = quote.text
        } else if id.hasPrefix("spiritual_weekly_") || id.hasPrefix("spiritual_daily_") || id.hasPrefix("spiritual_wd_"),
                  let titleKey = info["titleKey"] as? String,
                  let bodyKey = info["bodyKey"] as? String {
            title = LanguageManager.shared.localizedString(titleKey)
            body = LanguageManager.shared.localizedString(bodyKey)
        } else if id.hasPrefix("daily_reminder_") {
            title = NSLocalizedString("notification.daily_reminder.title", comment: "")
            body = NSLocalizedString("notification.daily_reminder.body", comment: "")
        } else if id == "streak_reminder" {
            let streak = UserDefaults.standard.integer(forKey: "currentStreak")
            title = NSLocalizedString("notification.streak.title", comment: "")
            body = String(format: NSLocalizedString("notification.streak.body", comment: ""), streak)
        } else if id.contains("almost_daily_goal") {
            let completed = info["sessions_completed"] as? Int ?? 0
            let remaining = info["sessions_remaining"] as? Int ?? 0
            title = NSLocalizedString("notification.daily_goal_almost.title", comment: "")
            body = String(format: NSLocalizedString("notification.daily_goal_almost.body", comment: ""), completed, remaining)
        } else if id.hasPrefix("blocked_app_") {
            title = NSLocalizedString("notification.app_locked.title", comment: "")
            body = NSLocalizedString("notification.app_locked.body", comment: "")
        } else if id.hasPrefix("recurring_lock_reminder_") {
            title = NSLocalizedString("notification.next_session.title", comment: "")
            body = NSLocalizedString("notification.next_session.body", comment: "")
        } else if id == "five_minute_warning" {
            title = NSLocalizedString("notification.five_minutes.title", comment: "")
            body = NSLocalizedString("notification.five_minutes.body", comment: "")
        } else if id == "auto_lock_notification" {
            title = NSLocalizedString("notification.app_name", comment: "ScrollDeeds")
            body = NSLocalizedString("notification.autolock.body", comment: "")
        } else if id == "auto_lock_followup_1" {
            title = NSLocalizedString("notification.app_name", comment: "ScrollDeeds")
            body = NSLocalizedString("notification.autolock.followup1.body", comment: "")
        } else if id == "auto_lock_followup_2" {
            title = NSLocalizedString("notification.app_name", comment: "ScrollDeeds")
            body = NSLocalizedString("notification.autolock.followup2.body", comment: "")
        } else if id == "reengagement_series_kickoff" {
            if let name {
                title = String(format: NSLocalizedString("notification.reengagement.series_kickoff.title_named", comment: ""), name)
            } else {
                title = NSLocalizedString("notification.reengagement.series_kickoff.title", comment: "")
            }
            body = NSLocalizedString("notification.reengagement.series_kickoff.body", comment: "")
        } else if id == "reengagement_app_opened" {
            title = NSLocalizedString("notification.bonus.title", comment: "")
            body = NSLocalizedString("notification.bonus.body", comment: "")
        } else if id.hasPrefix("reengagement_"),
                  let index = Int(id.replacingOccurrences(of: "reengagement_", with: "")) {
            var localizedTitle = NSLocalizedString("notification.reengagement.\(index + 1).title", comment: "")
            if let name, [0, 5, 9].contains(index) {
                localizedTitle = index == 9 ? "\(name). \(localizedTitle)" : "\(name), \(localizedTitle)"
            }
            title = localizedTitle
            body = NSLocalizedString("notification.reengagement.\(index + 1).body", comment: "")
        } else if id.hasPrefix("welcome_"), id != "welcome_back_10min",
                  let index = Int(id.replacingOccurrences(of: "welcome_", with: "")) {
            title = NSLocalizedString("notification.welcome.\(index + 1).title", comment: "")
            body = NSLocalizedString("notification.welcome.\(index + 1).body", comment: "")
        } else if id == "welcome_back_10min" {
            title = NSLocalizedString("notification.welcome_back_10min.title", comment: "")
            body = NSLocalizedString("notification.welcome_back_10min.body", comment: "")
        } else if id == Self.leaveAppWinbackIdentifier {
            title = NSLocalizedString("notification.leave_app_winback.1.title", comment: "")
            body = NSLocalizedString("notification.leave_app_winback.1.body", comment: "")
        } else if id == "daily_recurring_trigger" {
            title = NSLocalizedString("notification.app_name", comment: "ScrollDeeds")
            body = NSLocalizedString("notification.return_practice", comment: "")
        } else {
            return nil
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = request.content.sound ?? .default
        content.badge = request.content.badge
        content.categoryIdentifier = request.content.categoryIdentifier
        content.userInfo = request.content.userInfo
        content.threadIdentifier = request.content.threadIdentifier
        return content
    }
    
    // MARK: - Unlock Timer Notification
    
    func scheduleUnlockExpiryNotification(expiresAt: Date) {
        guard guardSchedulingEnabled() else { return }
        // Cancel any existing notifications first
        cancelUnlockExpiryNotification()
        cancelRecurringTimeExpiredNotifications()
        
        let timeInterval = expiresAt.timeIntervalSinceNow
        guard timeInterval > 0 else {
            debugPrint("⚠️ Cannot schedule notification: timeInterval is \(timeInterval) (already expired or invalid)")
            return
        }
        
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        debugPrint("📅 Scheduling unlock expiry notification for \(expiresAt) (in \(minutes)m \(seconds)s)")
        
        // First notification: when 15 minutes expire
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.session_complete.title", comment: "Session Complete")
        content.body = NSLocalizedString("notification.session_complete.body", comment: "Your mindful break has ended. Return to ScrollDeeds to continue your practice.")
        content.sound = .default
        content.categoryIdentifier = "UNLOCK_EXPIRED"
        content.badge = 1
        content.userInfo = ["unlock_expired": true, "requires_app_open": true]
        content.threadIdentifier = "shield_expiry"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "unlock_expired_initial", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Failed to schedule initial notification: \(error.localizedDescription)")
            } else {
                debugPrint("✅ Initial notification scheduled for \(expiresAt) (in \(minutes)m \(seconds)s)")
                
                // Verify it was actually scheduled
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    let hasNotification = requests.contains { $0.identifier == "unlock_expired_initial" }
                    if hasNotification {
                        debugPrint("✅ Verified: Initial notification is in pending requests")
                    } else {
                        debugPrint("⚠️ WARNING: Initial notification was NOT found in pending requests!")
                    }
                }
            }
        }
        
        // Up to 2 follow-ups after the initial expiry ping → 3 total per session (onboarding promise)
        scheduleRecurringAlarmNotifications(startingAt: expiresAt)

        let calendar = Calendar.current
        let expiryComponents = calendar.dateComponents([.hour, .minute], from: expiresAt)
        UserDefaults.standard.set(expiryComponents.hour, forKey: "unlock_expiry_hour")
        UserDefaults.standard.set(expiryComponents.minute, forKey: "unlock_expiry_minute")
    }
    
    // Return reminders after unlock timer expires.
    // Initial expiry notification + these follow-ups = maxRemindersPerLockSession total.
    // Schedule (minutes after expiry): +30 → +2h
    private func scheduleRecurringAlarmNotifications(startingAt: Date) {
        cancelRecurringTimeExpiredNotifications()

        let followUpCount = Self.maxRemindersPerLockSession - 1 // initial already scheduled
        // Gaps since previous: first at +30m, then +90m more (= +2h cumulative)
        let intervalMinutes = Array([30, 90].prefix(max(0, followUpCount)))

        let alarmMessages = [
            NSLocalizedString("notification.alarm.1",  comment: "Return to ScrollDeeds to continue your mindful practice."),
            NSLocalizedString("notification.alarm.2",  comment: "Your session has ended. Open ScrollDeeds to stay accountable."),
            NSLocalizedString("notification.alarm.3",  comment: "Time to return. ScrollDeeds is waiting for you.")
        ]

        let calendar = Calendar.current
        var scheduledCount = 0
        var cumulativeSeconds: Double = 0

        for (i, gap) in intervalMinutes.enumerated() {
            cumulativeSeconds += Double(gap) * 60.0

            let notificationTime = startingAt.addingTimeInterval(cumulativeSeconds)
            guard notificationTime.timeIntervalSinceNow > 0 else { continue }

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)

            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification.app_name", comment: "ScrollDeeds")
            content.body  = alarmMessages[i % alarmMessages.count]
            content.sound = .default
            content.categoryIdentifier = "UNLOCK_EXPIRED"
            content.badge = NSNumber(value: i + 2)
            content.userInfo = [
                "unlock_expired":    true,
                "requires_app_open": true,
                "alarm_number":      i + 1
            ]
            content.threadIdentifier = "shield_expiry"

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "unlock_expired_alarm_1_\(i + 1)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    debugPrint("❌ Failed to schedule alarm \(i + 1): \(error.localizedDescription)")
                } else {
                    scheduledCount += 1
                }
            }
        }

        debugPrint("✅ Scheduled \(scheduledCount) return reminders (max \(Self.maxRemindersPerLockSession) per lock session incl. initial)")
    }
    
    // Schedule daily recurring notifications at the same hour if user hasn't opened app
    // This schedules a single notification that will trigger the next day to reschedule the series
    private func scheduleDailyRecurringNotifications(expiryHour: Int, expiryMinute: Int) {
        // Cancel any existing daily recurring notifications
        cancelDailyRecurringNotifications()
        
        let calendar = Calendar.current
        let now = Date()
        
        // Start from tomorrow at the expiry hour
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return }
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        dateComponents.hour = expiryHour
        dateComponents.minute = expiryMinute
        dateComponents.second = 0
        
        guard calendar.date(from: dateComponents) != nil else { return }
        
        // Schedule a single notification that will trigger tomorrow to reschedule the series
        // This notification will check if user opened app, and if not, reschedule 60 notifications
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.app_name", comment: "ScrollDeeds")
        content.body = NSLocalizedString("notification.return_practice", comment: "Return to ScrollDeeds to continue your mindful practice.")
        content.sound = .default
        content.categoryIdentifier = "UNLOCK_EXPIRED"
        content.badge = 1
        content.userInfo = [
            "unlock_expired": true,
            "requires_app_open": true,
            "daily_recurring_trigger": true,
            "expiry_hour": expiryHour,
            "expiry_minute": expiryMinute
        ]
        content.threadIdentifier = "shield_expiry_daily"
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_recurring_trigger",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Failed to schedule daily recurring trigger: \(error.localizedDescription)")
            } else {
                debugPrint("✅ Scheduled daily recurring trigger (tomorrow at \(expiryHour):\(String(format: "%02d", expiryMinute)))")
            }
        }
    }
    
    // Reschedule a small set of daily nudges (capped at maxRemindersPerLockSession).
    func rescheduleDailyNotificationSeries(expiryHour: Int, expiryMinute: Int) {
        guard guardSchedulingEnabled() else { return }
        let calendar = Calendar.current
        let now = Date()
        let maxCount = Self.maxRemindersPerLockSession
        // Spread: 0, +30m, +2h from the expiry clock time
        let offsetsMinutes = [0, 30, 120].prefix(maxCount)
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = expiryHour
        dateComponents.minute = expiryMinute
        dateComponents.second = 0
        
        guard let firstNotificationDate = calendar.date(from: dateComponents) else { return }
        
        let targetDate = firstNotificationDate < now ? calendar.date(byAdding: .day, value: 1, to: firstNotificationDate)! : firstNotificationDate
        
        let alarmMessages = [
            NSLocalizedString("notification.alarm.1", comment: "Return to ScrollDeeds to continue your mindful practice."),
            NSLocalizedString("notification.alarm.2", comment: "Your session has ended. Open ScrollDeeds to stay accountable."),
            NSLocalizedString("notification.alarm.3", comment: "Time to return. ScrollDeeds is waiting for you.")
        ]
        
        var scheduledCount = 0
        
        for (index, offset) in offsetsMinutes.enumerated() {
            let i = index + 1
            guard let notificationTime = calendar.date(byAdding: .minute, value: offset, to: targetDate) else { continue }
            guard notificationTime.timeIntervalSinceNow > 0 else { continue }
            let notificationComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
            
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification.app_name", comment: "ScrollDeeds")
            content.body = alarmMessages[index % alarmMessages.count]
            content.sound = .default
            content.categoryIdentifier = "UNLOCK_EXPIRED"
            content.badge = NSNumber(value: i)
            content.userInfo = ["unlock_expired": true, "requires_app_open": true, "daily_recurring": true]
            content.threadIdentifier = "shield_expiry_daily"
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: notificationComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "daily_recurring_alarm_\(i)_\(Int(targetDate.timeIntervalSince1970))",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    debugPrint("❌ Failed to schedule daily recurring notification \(i): \(error.localizedDescription)")
                } else {
                    scheduledCount += 1
                }
            }
        }
        
        debugPrint("✅ Rescheduled \(scheduledCount) daily recurring notifications (max \(maxCount) per session)")
    }
    
    func cancelDailyRecurringNotifications() {
        // Cancel the trigger notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_recurring_trigger"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["daily_recurring_trigger"])
        
        // Cancel all daily recurring alarm notifications (they have dynamic identifiers)
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let dailyIdentifiers = requests.filter { $0.identifier.contains("daily_recurring_alarm_") }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: dailyIdentifiers)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: dailyIdentifiers)
        }
        
        debugPrint("🗑️ Cancelled all daily recurring notifications")
    }
    
    // Schedule up to maxRemindersPerLockSession when user taps a lock notification
    func scheduleLockedAppRemindersAfterTap() {
        guard guardSchedulingEnabled() else { return }
        guard !ShieldManager.shared.hasActiveUnlockSession() else {
            debugPrint("⏳ Skipping after-tap reminders — user still unlocked")
            return
        }
        guard ShieldManager.shared.isShieldActive else {
            debugPrint("⏳ Skipping after-tap reminders — shield not active")
            return
        }
        // Replace any pending lock reminders so the session never exceeds the cap
        cancelLockedAppReminders()
        cancelLockedAppRemindersAfterTap()
        cancelAutoLockNotifications()
        cancelUnlockExpiryNotification()
        cancelRecurringTimeExpiredNotifications()
        
        let calendar = Calendar.current
        let now = Date()
        let maxCount = Self.maxRemindersPerLockSession
        // First ping soon after lock, then +30m and +2h
        let offsetsMinutes = [2, 30, 120].prefix(maxCount)
        
        let reminderMessages = [
            NSLocalizedString("notification.locked_app.1", comment: "Your apps are locked. Complete dhikr in ScrollDeeds to unlock them."),
            NSLocalizedString("notification.locked_app.2", comment: "Take a mindful moment. Return to ScrollDeeds to unlock your apps."),
            NSLocalizedString("notification.locked_app.3", comment: "Time for reflection. Open ScrollDeeds and complete your practice.")
        ]
        
        var scheduledCount = 0
        
        for (index, offset) in offsetsMinutes.enumerated() {
            let i = index + 1
            guard let reminderTime = calendar.date(byAdding: .minute, value: offset, to: now) else { continue }
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
            
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification.reminder.title", comment: "ScrollDeeds Reminder")
            content.body = reminderMessages[index % reminderMessages.count]
            content.sound = .default
            content.categoryIdentifier = "DHIKR_REMINDER"
            content.badge = NSNumber(value: i)
            content.userInfo = ["locked_app_reminder_after_tap": true, "reminder_number": i]
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "locked_app_reminder_after_tap_\(i)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    debugPrint("❌ Failed to schedule locked app reminder after tap \(i): \(error)")
                } else {
                    scheduledCount += 1
                }
            }
        }
        
        debugPrint("✅ Scheduled \(scheduledCount) locked app reminders after tap (max \(maxCount) per session)")
    }
    
    func cancelLockedAppRemindersAfterTap() {
        let reminderIdentifiers = (1...Self.maxRemindersPerLockSession).map { "locked_app_reminder_after_tap_\($0)" }
        // Also clear any legacy identifiers from when we scheduled up to 8
        let legacyIdentifiers = (1...8).map { "locked_app_reminder_after_tap_\($0)" }
        let all = Array(Set(reminderIdentifiers + legacyIdentifiers))
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: all)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: all)
        debugPrint("🗑️ Cancelled all locked app reminders after tap")
    }
    
    func cancelUnlockExpiryNotification() {
        // Cancel initial notification
        let initialIdentifier = ["unlock_expired_initial"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: initialIdentifier)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: initialIdentifier)
        
        // Cancel all alarm notifications (all cycles, 1-60 each)
        // Get all pending requests and filter for alarm notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let alarmIdentifiers = requests.filter { $0.identifier.starts(with: "unlock_expired_alarm_") }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: alarmIdentifiers)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: alarmIdentifiers)
        }
        
        // Cancel all cycle trigger notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let cycleTriggerIdentifiers = requests.filter { $0.identifier.starts(with: "unlock_expired_cycle_trigger_") }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: cycleTriggerIdentifiers)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: cycleTriggerIdentifiers)
        }
        
        // Cancel recurring reminder notifications as well
        let reminderIdentifiers = (1...6).map { "recurring_lock_reminder_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: reminderIdentifiers)
        
        // Cancel daily recurring notifications when user unlocks
        cancelDailyRecurringNotifications()
        
        debugPrint("🔕 Cancelled all unlock expiry notifications and alarms (pending + delivered)")
    }
    
    // MARK: - 5 Minute Warning
    
    func scheduleFiveMinuteWarning(expiresAt: Date) {
        guard guardSchedulingEnabled() else { return }
        let fiveMinutesBefore = expiresAt.addingTimeInterval(-5 * 60)
        let timeInterval = fiveMinutesBefore.timeIntervalSinceNow
        
        guard timeInterval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.five_minutes.title", comment: "5 Minutes Remaining")
        content.body = NSLocalizedString("notification.five_minutes.body", comment: "Your mindful break ends soon. Use this time intentionally and prepare to return to ScrollDeeds.")
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "five_minute_warning", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelFiveMinuteWarning() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["five_minute_warning"])
    }
    
    // MARK: - Daily Dhikr Reminders
    
    func scheduleDailyReminders(times: [DateComponents]) {
        guard guardSchedulingEnabled() else { return }
        cancelDailyReminders()
        
        for (index, time) in times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification.daily_reminder.title", comment: "Time for Your Practice")
            content.body = NSLocalizedString("notification.daily_reminder.body", comment: "Take a mindful moment. Complete your dhikr in ScrollDeeds to unlock your apps.")
            content.sound = .default
            content.categoryIdentifier = "DHIKR_REMINDER"
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
            let request = UNNotificationRequest(
                identifier: "daily_reminder_\(index)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func cancelDailyReminders() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let reminderIds = requests.filter { $0.identifier.starts(with: "daily_reminder_") }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIds)
        }
    }

    // MARK: - Daily Quran / sunnah / reminder nudges

    private static let spiritualHorizonDays = 10
    private static let spiritualPendingCap = 40

    private static let spiritualDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    /// Unique one-shot notifications for the next 10 days, rotating the catalog.
    /// Repeating calendar triggers freeze the same verse forever — that is why they felt broken.
    func scheduleDailySpiritualReminders() {
        let widget = NafsiWidgetSettings.shared
        guard guardSchedulingEnabled(), widget.quranRemindersEnabled else {
            cancelDailySpiritualReminders()
            return
        }

        let slots = widget.reminderSlots
        let pool = notificationPool()
        let weekdays = widget.reminderWeekdays
        guard !slots.isEmpty, !pool.isEmpty else {
            cancelDailySpiritualReminders()
            return
        }

        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let stale = requests.map(\.identifier).filter { $0.hasPrefix("spiritual_") }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: stale)

            let cal = Calendar.current
            let now = Date()
            var scheduled = 0

            for dayOffset in 0..<Self.spiritualHorizonDays {
                guard scheduled < Self.spiritualPendingCap else { break }
                guard let dayStart = cal.date(byAdding: .day, value: dayOffset, to: cal.startOfDay(for: now)) else { continue }
                let weekday = cal.component(.weekday, from: dayStart)
                guard weekdays.contains(weekday) else { continue }

                let ymd = Self.spiritualDayFormatter.string(from: dayStart)
                for (slotIndex, slot) in slots.enumerated() {
                    guard scheduled < Self.spiritualPendingCap else { break }
                    var comps = cal.dateComponents([.year, .month, .day], from: dayStart)
                    comps.hour = slot.hour
                    comps.minute = slot.minute
                    comps.second = 0
                    guard let fire = cal.date(from: comps), fire.timeIntervalSinceNow > 20 else { continue }

                    let quote = NafsiQuoteCatalog.quoteForSlot(
                        from: pool,
                        at: fire,
                        dayKey: ymd,
                        slot: slotIndex
                    ) ?? pool[self.stableQuoteIndex(day: ymd, slot: slotIndex, count: pool.count)]
                    let request = UNNotificationRequest(
                        identifier: "spiritual_at_\(ymd)_\(slotIndex)",
                        content: self.spiritualContent(for: quote),
                        trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                    )
                    UNUserNotificationCenter.current().add(request)
                    scheduled += 1
                }
            }
            debugPrint("✅ Scheduled \(scheduled) spiritual reminders from catalog of \(pool.count)")
        }
    }

    func cancelDailySpiritualReminders() {
        var ids: [String] = []
        for weekday in 1...7 {
            for slot in 0..<12 {
                ids.append("spiritual_weekly_\(weekday)_\(slot)")
                ids.append("spiritual_wd_\(weekday)_\(slot)")
            }
        }
        for slot in 0..<12 {
            ids.append("spiritual_daily_\(slot)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let extra = requests.map(\.identifier).filter { $0.hasPrefix("spiritual_") }
            if !extra.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: extra)
            }
        }
    }

    private func notificationKindFilter() -> Set<String> {
        switch dailySpiritualFilter {
        case .all: return ["quran", "hadith", "dua"]
        case .quran: return ["quran"]
        case .sunnah: return ["hadith"]
        case .reminder: return ["dua"]
        }
    }

    private func notificationPool() -> [NafsiWidgetQuote] {
        NafsiQuoteCatalog.notificationQuotes(
            language: LanguageManager.shared.currentLanguage,
            kinds: notificationKindFilter()
        )
    }

    private func spiritualContent(for quote: NafsiWidgetQuote) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        // Always show the full source as the title (Qur'an 2:152, Sahih Muslim 223, …).
        content.title = quote.reference
        let showReflection = NafsiWidgetSettings.shared.reminderShowReflection
        var body = quote.text
        if showReflection,
           !quote.reflection.isEmpty,
           quote.text.count + 1 + quote.reflection.count <= NafsiQuoteCatalog.notificationBodyLimit {
            body = quote.text + " " + quote.reflection
        }
        // Keep the full source visible in the body too (expanded banner / lock screen).
        if !quote.reference.isEmpty, !body.contains(quote.reference) {
            body += " — " + quote.reference
        }
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "SPIRITUAL_REMINDER"
        content.threadIdentifier = "spiritual"
        content.userInfo = [
            "spiritual": true,
            "kind": quote.kind,
            "quoteId": quote.id
        ]
        return content
    }

    private func stableQuoteIndex(day: String, slot: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        var mixed = slot &* 17
        mixed = mixed &+ dailySpiritualFilter.rawValue.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        mixed = mixed &+ day.utf8.reduce(0) { ($0 &* 31) &+ Int($1) }
        return abs(mixed) % count
    }
    
    // MARK: - Streak Notification
    
    func scheduleStreakReminder() {
        guard guardSchedulingEnabled() else { return }
        let streak = UserDefaults.standard.integer(forKey: "currentStreak")
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.streak.title", comment: "Maintain Your Streak")
        content.body = String(format: NSLocalizedString("notification.streak.body", comment: "You're on a %d-day streak. Complete a session today to keep it going."), streak)
        content.sound = .default
        
        // 8 PM today, or 8 PM tomorrow if that time already passed.
        var fireDate = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        if fireDate <= Date() {
            fireDate = Calendar.current.date(byAdding: .day, value: 1, to: fireDate) ?? fireDate
        }
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelStreakReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])
    }
    
    // MARK: - Daily Goal Progress Notification
    
    /// Schedule a notification when user is close to completing daily goal (3 or 4 sessions)
    func scheduleAlmostDailyGoalNotification(sessionsCompleted: Int, sessionsRemaining: Int) {
        guard guardSchedulingEnabled() else { return }
        // Only schedule if we haven't sent one today already
        let lastNotificationKey = "last_daily_goal_notification_date"
        let lastNotificationDate = UserDefaults.standard.object(forKey: lastNotificationKey) as? Date
        let calendar = Calendar.current
        
        // Check if we already sent a notification today
        if let lastDate = lastNotificationDate, calendar.isDateInToday(lastDate) {
            debugPrint("📱 Daily goal notification already sent today, skipping")
            return
        }
        
        // Only send for 3 or 4 sessions (close to goal)
        guard sessionsCompleted >= 3 && sessionsCompleted < 5 else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.daily_goal_almost.title", comment: "Almost There!")
        content.body = String(format: NSLocalizedString("notification.daily_goal_almost.body", comment: "You've completed %d sessions today! Just %d more to complete your daily goal and maintain your streak! 🔥"), sessionsCompleted, sessionsRemaining)
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "DAILY_GOAL_PROGRESS"
        content.userInfo = [
            "daily_goal_progress": true,
            "sessions_completed": sessionsCompleted,
            "sessions_remaining": sessionsRemaining
        ]
        
        // Schedule for 30 minutes from now (give user time to naturally complete)
        // Or schedule for evening if it's already late
        let now = Date()
        let calendarComponents = Calendar.current.dateComponents([.hour], from: now)
        let currentHour = calendarComponents.hour ?? 12
        
        var triggerDate: Date
        if currentHour >= 18 {
            // It's evening, schedule for tomorrow morning at 9 AM
            var tomorrowComponents = Calendar.current.dateComponents([.year, .month, .day], from: Calendar.current.date(byAdding: .day, value: 1, to: now)!)
            tomorrowComponents.hour = 9
            tomorrowComponents.minute = 0
            triggerDate = Calendar.current.date(from: tomorrowComponents) ?? now.addingTimeInterval(30 * 60)
        } else {
            // Schedule for 30 minutes from now
            triggerDate = now.addingTimeInterval(30 * 60)
        }
        
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "almost_daily_goal_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Failed to schedule almost daily goal notification: \(error)")
            } else {
                debugPrint("✅ Almost daily goal notification scheduled for \(triggerDate) (sessions: \(sessionsCompleted)/5)")
                // Mark that we sent a notification today
                UserDefaults.standard.set(Date(), forKey: lastNotificationKey)
            }
        }
    }
    
    func cancelAlmostDailyGoalNotifications() {
        // Cancel all pending almost daily goal notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.contains("almost_daily_goal") }
                .map { $0.identifier }
            
            if !identifiers.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
                debugPrint("✅ Cancelled \(identifiers.count) almost daily goal notifications")
            }
        }
    }
    
    // MARK: - Blocked App Notification
    
    func sendBlockedAppNotification() {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.app_locked.title", comment: "App Locked")
        content.body = NSLocalizedString("notification.app_locked.body", comment: "Complete your dhikr practice in ScrollDeeds to unlock access.")
        content.sound = .default
        content.categoryIdentifier = "BLOCKED_APP_ATTEMPT"
        content.badge = 1
        
        // Immediate trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "blocked_app_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Failed to send blocked app notification: \(error)")
            } else {
                debugPrint("✅ Blocked app notification sent!")
            }
        }
    }
    
    // MARK: - Recurring Time Expired Notifications (Every 5 Minutes)
    
    func scheduleRecurringTimeExpiredNotifications() {
        guard guardSchedulingEnabled() else { return }
        cancelRecurringTimeExpiredNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.next_session.title", comment: "Ready for Your Next Session")
        content.body = NSLocalizedString("notification.next_session.body", comment: "Your previous session ended. Return to ScrollDeeds to start a new mindful break.")
        content.sound = .default
        content.categoryIdentifier = "UNLOCK_EXPIRED"
        content.badge = 1
        
        let maxCount = Self.maxRemindersPerLockSession
        // +30m, +2h, +6h — same cadence as other lock-session reminders
        let offsetsMinutes = [30, 120, 360].prefix(maxCount)
        
        for (index, offset) in offsetsMinutes.enumerated() {
            let i = index + 1
            let timeInterval = Double(offset * 60)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "recurring_lock_reminder_\(i)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    debugPrint("❌ Failed to schedule recurring notification \(i): \(error)")
                } else {
                    debugPrint("✅ Recurring notification \(i) scheduled for +\(offset) minutes")
                }
            }
        }
        
        debugPrint("📅 Scheduled \(maxCount) recurring notifications (max per lock session)")
    }
    
    func cancelRecurringTimeExpiredNotifications() {
        let reminderIdentifiers = (1...6).map { "recurring_lock_reminder_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: reminderIdentifiers)
        
        // Cancel all alarm notifications (all cycles)
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let alarmIdentifiers = requests.filter { $0.identifier.starts(with: "unlock_expired_alarm_") }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: alarmIdentifiers)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: alarmIdentifiers)
        }
        
        // Cancel all cycle trigger notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let cycleTriggerIdentifiers = requests.filter { $0.identifier.starts(with: "unlock_expired_cycle_trigger_") }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: cycleTriggerIdentifiers)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: cycleTriggerIdentifiers)
        }
        
        debugPrint("🗑️ Cancelled all recurring time expired notifications and alarms (pending + delivered)")
    }
    
    // MARK: - Locked App Reminder Notifications (when shield is active)
    
    private var lastLockedReminderScheduleTime: Date?
    private let lockedReminderDebounceInterval: TimeInterval = 5.0 // 5 seconds debounce
    /// Bumped whenever lock-related notifications are cancelled — invalidates in-flight async schedules.
    private var lockReminderScheduleGeneration = 0
    
    /// Cancels every notification tied to locked/expired state. Call when the user unlocks.
    /// - Parameter force: bypass the short debounce used by the 1s shield reconcile loop.
    func cancelAllLockRelatedNotifications(force: Bool = false) {
        if !force, let last = lastLockRelatedCancelAt, Date().timeIntervalSince(last) < 2 {
            return
        }
        lastLockRelatedCancelAt = Date()
        lockReminderScheduleGeneration += 1
        lastLockedReminderScheduleTime = nil
        cancelLockedAppReminders()
        cancelLockedAppRemindersAfterTap()
        cancelAutoLockNotifications()
        cancelUnlockExpiryNotification()
        cancelRecurringTimeExpiredNotifications()
        cancelDailyRecurringNotifications()
        debugPrint("🗑️ Cancelled all lock-related notifications (generation \(lockReminderScheduleGeneration))")
    }

    /// User earned unlock time — they should leave ScrollDeeds and use their apps.
    /// Kill lock reminders and conversion nudges so nothing "random" fires mid-session.
    func onAppsUnlocked() {
        if !notificationsAdaptedToUnlock {
            notificationsAdaptedToUnlock = true
            cancelAllLockRelatedNotifications(force: true)
            cancelReengagementNotifications()
            debugPrint("🔓 Notifications adapted to unlock session — conversion + lock nudges silenced")
        }
        // Always drop immediate pings — a background race can reschedule the 8s leave-app.
        cancelImmediateConversionNudges()
    }

    /// Shield is back on. Allows conversion / lock reminders to be scheduled again.
    func onAppsLocked() {
        notificationsAdaptedToUnlock = false
    }
    
    /// Remove stale lock notifications when an unlock session is still active.
    func purgeStaleLockNotificationsIfUnlocked() {
        guard ShieldManager.shared.hasActiveUnlockSession() else { return }
        onAppsUnlocked()
    }

    private func cancelImmediateConversionNudges() {
        cancelLeaveAppNonSubscriberWinback()
        cancelPaywallLeaveConversionNudge()
        cancelTenMinuteWelcomeBackNotification()
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["reengagement_series_kickoff", "reengagement_app_opened"]
        )
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["reengagement_series_kickoff", "reengagement_app_opened"]
        )
    }

    private func isConversionNotification(_ notification: UNNotification) -> Bool {
        let id = notification.request.identifier
        let info = notification.request.content.userInfo
        if info["reengagement"] as? Bool == true { return true }
        if info["leave_app_winback"] as? Bool == true { return true }
        if info["welcome_back_10min"] as? Bool == true { return true }
        if info["subscription_winback"] as? Bool == true { return true }
        if id.hasPrefix("reengagement_") { return true }
        if id == Self.leaveAppWinbackIdentifier { return true }
        if id == "welcome_back_10min" { return true }
        if id.hasPrefix("subscription_winback_") { return true }
        return false
    }

    private func shouldSuppressConversionNotification(_ notification: UNNotification) -> Bool {
        guard isConversionNotification(notification) else { return false }
        guard ShieldManager.shared.hasActiveUnlockSession() else { return false }
        debugPrint("⏳ Suppressing conversion notification during unlock: \(notification.request.identifier)")
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
        return true
    }
    
    private func isLockRelatedNotification(_ notification: UNNotification) -> Bool {
        let id = notification.request.identifier
        let info = notification.request.content.userInfo
        if info["locked_app_reminder"] as? Bool == true { return true }
        if info["locked_app_reminder_after_tap"] as? Bool == true { return true }
        if info["auto_locked"] as? Bool == true { return true }
        if info["unlock_expired"] as? Bool == true { return true }
        if id.starts(with: "locked_app_reminder_") { return true }
        if id.starts(with: "auto_lock_") { return true }
        if id == "unlock_expired_initial" { return true }
        if id.starts(with: "unlock_expired_alarm_") { return true }
        if id.starts(with: "recurring_lock_reminder_") { return true }
        if id.starts(with: "daily_recurring_alarm_") { return true }
        if id == "daily_recurring_trigger" { return true }
        return false
    }
    
    private func shouldSuppressLockNotification(_ notification: UNNotification) -> Bool {
        guard isLockRelatedNotification(notification) else { return false }
        guard ShieldManager.shared.hasActiveUnlockSession() else { return false }
        debugPrint("⏳ Suppressing stale lock notification: \(notification.request.identifier)")
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
        return true
    }
    
    /// Schedule recurring reminder notifications when apps are locked
    /// These remind the user to do dhikr to unlock their apps
    /// Uses calendar-based triggers for better reliability
    /// Includes debounce to prevent duplicate scheduling
    /// NOTE: Does NOT schedule if unlock expiry alarms are already active (to avoid duplicates)
    func scheduleLockedAppReminders() {
        guard guardSchedulingEnabled() else { return }
        
        if ShieldManager.shared.hasActiveUnlockSession() {
            debugPrint("⏳ Skipping locked app reminders — user still has active unlock session")
            onAppsUnlocked()
            return
        }
        onAppsLocked()
        if !ShieldManager.shared.isShieldActive {
            debugPrint("⏳ Skipping locked app reminders — shield not active")
            return
        }
        
        // Debounce: Don't schedule if we just scheduled within the last 5 seconds
        if let lastTime = lastLockedReminderScheduleTime,
           Date().timeIntervalSince(lastTime) < lockedReminderDebounceInterval {
            debugPrint("⏳ Skipping locked app reminders - already scheduled within \(lockedReminderDebounceInterval)s")
            return
        }
        lastLockedReminderScheduleTime = Date()
        
        // Check if unlock expiry alarms are already scheduled - if so, don't add locked reminders
        // This prevents duplicate notifications when unlock timer expires
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            
            let hasUnlockExpiryAlarms = requests.contains { $0.identifier.starts(with: "unlock_expired_alarm_") || $0.identifier == "unlock_expired_initial" }
            let hasAutoLockReminders = requests.contains {
                $0.identifier == "auto_lock_notification" || $0.identifier.starts(with: "auto_lock_followup_")
            }
            let hasLockedAppReminders = requests.contains { $0.identifier.starts(with: "locked_app_reminder_") }
            
            if hasUnlockExpiryAlarms {
                debugPrint("⏳ Skipping locked app reminders - unlock expiry alarms already scheduled")
                return
            }
            if hasAutoLockReminders {
                debugPrint("⏳ Skipping locked app reminders - auto-lock session reminders already scheduled (max 3)")
                return
            }
            if hasLockedAppReminders {
                debugPrint("⏳ Skipping locked app reminders - already pending")
                return
            }
            
            DispatchQueue.main.async {
                self.scheduleLockedAppRemindersInternal(generation: self.lockReminderScheduleGeneration)
            }
        }
    }
    
    /// Internal function to schedule locked-app reminders.
    /// Hard-capped at `maxRemindersPerLockSession` (onboarding: up to 3 per session).
    /// Spacing: +2 min, +30 min, +2h.
    private func scheduleLockedAppRemindersInternal(generation: Int) {
        // Cancel ALL existing lock reminders first to avoid duplicates / stacking past the cap
        cancelLockedAppReminders()
        cancelRecurringTimeExpiredNotifications()
        cancelLockedAppRemindersAfterTap()
        cancelAutoLockNotifications()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard generation == self.lockReminderScheduleGeneration else {
                debugPrint("⏳ Skipping lock reminders — schedule invalidated")
                return
            }
            guard !ShieldManager.shared.hasActiveUnlockSession() else {
                debugPrint("⏳ Skipping lock reminders — user unlocked during schedule")
                return
            }
            guard ShieldManager.shared.isShieldActive else {
                debugPrint("⏳ Skipping lock reminders — shield not active")
                return
            }
            
            let maxCount = Self.maxRemindersPerLockSession
            let offsetsMinutes = [2, 30, 120].prefix(maxCount)
            
            let messages = [
                NSLocalizedString("notification.locked_app.1", comment: "Your apps are locked. Complete dhikr in ScrollDeeds to unlock them."),
                NSLocalizedString("notification.locked_app.2", comment: "Take a mindful moment. Return to ScrollDeeds to unlock your apps."),
                NSLocalizedString("notification.locked_app.9", comment: "Time for dhikr. Open ScrollDeeds to continue your practice.")
            ]
            
            let calendar = Calendar.current
            let now = Date()
            
            for (index, offset) in offsetsMinutes.enumerated() {
                let i = index + 1
                let notificationTime = calendar.date(byAdding: .minute, value: offset, to: now)!
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
                
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("notification.app_name", comment: "ScrollDeeds")
                content.body = messages[index % messages.count]
                content.sound = .default
                content.categoryIdentifier = "DHIKR_REMINDER"
                content.badge = NSNumber(value: 1)
                content.userInfo = ["locked_app_reminder": true, "reminder_number": i]
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "locked_app_reminder_\(i)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        debugPrint("❌ Failed to schedule locked app reminder \(i): \(error)")
                    }
                }
            }
            
            debugPrint("📅 Scheduled \(maxCount) locked app reminder notifications (max per lock session)")
        }
    }
    
    func cancelLockedAppReminders() {
        // Cancel all reminder notifications (check up to 100 to be safe)
        let reminderIdentifiers = (1...100).map { "locked_app_reminder_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: reminderIdentifiers)
        debugPrint("🗑️ Cancelled all locked app reminder notifications (pending + delivered)")
    }

    /// Cancel the auto-lock notification and its follow-ups (sent by DeviceActivityMonitorExtension).
    func cancelAutoLockNotifications() {
        var identifiers = ["auto_lock_notification"]
        identifiers += (1...3).map { "auto_lock_followup_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
        debugPrint("🗑️ Cancelled auto-lock notifications")
    }
    
    // MARK: - Badge Management
    
    func updateBadge(count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    // MARK: - Re-engagement Notifications (Non-Paying Users)
    
    /// Schedule persuasive re-engagement notifications for users who didn't pay (including onboarding abandon).
    /// Never includes the 10s kickoff — leave-app / paywall-leave cover the immediate ping.
    func scheduleReengagementNotifications(includeImmediateKickoff: Bool = false) {
        guard guardSchedulingEnabled() else { return }
        if ShieldManager.shared.hasActiveUnlockSession() {
            debugPrint("⏳ Skipping re-engagement schedule — apps are unlocked")
            onAppsUnlocked()
            return
        }
        scheduleReengagementNotificationsInternal(includeImmediateKickoff: includeImmediateKickoff)
    }

    private func scheduleReengagementNotificationsInternal(includeImmediateKickoff: Bool = true) {
        cancelReengagementNotifications()

        let now      = Date()
        let calendar = Calendar.current

        // Read the name saved during onboarding (may be nil if user skipped the field).
        let savedName = UserDefaults.standard.string(forKey: "userName")
            .flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if includeImmediateKickoff {
            scheduleReengagementSeriesKickoff(savedName: savedName)
        }

        // Indices that get a personalised title when a name is available (every now and then,
        // not every notification — keeps it feeling natural instead of gimmicky).
        // 0 = 4 h (first touch), 5 = 7 days (identity moment), 9 = 35 days (final message).
        let personalisedIndices: Set<Int> = [0, 5, 9]

        // NLP-driven sequence: pain → dream outcome → social proof → identity → loss aversion → Islamic urgency → hard close
        let notifications: [(hours: Int, title: String, body: String)] = [
            // 4 h — strike while the iron is hot
            (4,
             NSLocalizedString("notification.reengagement.1.title", comment: ""),
             NSLocalizedString("notification.reengagement.1.body",  comment: "")),

            // 24 h — Islamic pain point (Fajr)
            (24,
             NSLocalizedString("notification.reengagement.2.title", comment: ""),
             NSLocalizedString("notification.reengagement.2.body",  comment: "")),

            // 48 h — dream outcome, vivid
            (48,
             NSLocalizedString("notification.reengagement.3.title", comment: ""),
             NSLocalizedString("notification.reengagement.3.body",  comment: "")),

            // 72 h — social proof
            (72,
             NSLocalizedString("notification.reengagement.4.title", comment: ""),
             NSLocalizedString("notification.reengagement.4.body",  comment: "")),

            // 5 days — specific loss
            (120,
             NSLocalizedString("notification.reengagement.5.title", comment: ""),
             NSLocalizedString("notification.reengagement.5.body",  comment: "")),

            // 7 days — identity shift
            (168,
             NSLocalizedString("notification.reengagement.6.title", comment: ""),
             NSLocalizedString("notification.reengagement.6.body",  comment: "")),

            // 14 days — FOMO + dream
            (336,
             NSLocalizedString("notification.reengagement.7.title", comment: ""),
             NSLocalizedString("notification.reengagement.7.body",  comment: "")),

            // 21 days — Islamic urgency (Ramadan)
            (504,
             NSLocalizedString("notification.reengagement.8.title", comment: ""),
             NSLocalizedString("notification.reengagement.8.body",  comment: "")),

            // 28 days — hard truth
            (672,
             NSLocalizedString("notification.reengagement.9.title", comment: ""),
             NSLocalizedString("notification.reengagement.9.body",  comment: "")),

            // 35 days — final close
            (840,
             NSLocalizedString("notification.reengagement.10.title", comment: ""),
             NSLocalizedString("notification.reengagement.10.body",  comment: ""))
        ]

        for (index, notification) in notifications.enumerated() {
            guard let triggerDate = calendar.date(byAdding: .hour, value: notification.hours, to: now),
                  triggerDate > now else { continue }

            // Occasionally personalise with the user's name to make it feel human.
            var notificationTitle = notification.title
            if let name = savedName, personalisedIndices.contains(index) {
                switch index {
                case 9:  notificationTitle = "\(name). \(notification.title)"   // "Ahmed. Last message from us."
                default: notificationTitle = "\(name), \(notification.title)"   // "Ahmed, You know the problem…"
                }
            }

            let content = UNMutableNotificationContent()
            content.title = notificationTitle
            content.body  = notification.body
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "REENGAGEMENT"
            content.userInfo = ["reengagement": true, "notification_index": index]

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger    = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request    = UNNotificationRequest(identifier: "reengagement_\(index)", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    debugPrint("❌ Re-engagement \(index) failed: \(error.localizedDescription)")
                } else {
                    debugPrint("✅ Re-engagement \(index) scheduled for +\(notification.hours)h")
                }
            }
        }

        UserDefaults.standard.set(true,  forKey: "reengagement_scheduled")
        UserDefaults.standard.set(now,   forKey: "reengagement_start_date")
        if includeImmediateKickoff {
            debugPrint("📅 Scheduled re-engagement kickoff (10s) + \(notifications.count) follow-up notifications")
        } else {
            debugPrint("📅 Scheduled \(notifications.count) re-engagement follow-ups (first at +4h; leave-app covers the immediate ping)")
        }
    }

    /// First ping 10s after the series is scheduled: opens the emotional arc and nudges the user back before the 4h message.
    private func scheduleReengagementSeriesKickoff(savedName: String?) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["reengagement_series_kickoff"])

        let title: String
        if let name = savedName {
            title = String(format: NSLocalizedString("notification.reengagement.series_kickoff.title_named", comment: ""), name)
        } else {
            title = NSLocalizedString("notification.reengagement.series_kickoff.title", comment: "")
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = NSLocalizedString("notification.reengagement.series_kickoff.body", comment: "")
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "REENGAGEMENT"
        content.userInfo = ["reengagement": true, "series_kickoff": true]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: "reengagement_series_kickoff", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Re-engagement series kickoff failed: \(error.localizedDescription)")
            } else {
                debugPrint("✅ Re-engagement series kickoff scheduled (+10s)")
            }
        }
    }
    
    /// Schedule bonus trigger notification - when user opens app but doesn't pay
    /// Called when user opens app, views paywall, but doesn't subscribe
    func scheduleAppOpenedButNotPaidNotification() {
        guard guardSchedulingEnabled() else { return }
        // Cancel any existing "opened but not paid" notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["reengagement_app_opened"])
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.bonus.title", comment: "You Came Back")
        content.body = NSLocalizedString("notification.bonus.body", comment: "That takes courage. You're one step away from taking control. Ready to commit?")
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "REENGAGEMENT"
        content.userInfo = ["reengagement": true, "bonus_trigger": true]
        
        // Schedule for 2 hours from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2 * 60 * 60, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "reengagement_app_opened",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Failed to schedule app-opened bonus notification: \(error)")
            } else {
                debugPrint("✅ Bonus notification scheduled for 2 hours from now")
            }
        }
    }
    
    /// Cancel all re-engagement notifications (call when user subscribes)
    func cancelReengagementNotifications() {
        // Cancel all indexed re-engagement notifications + opener + bonus
        let identifiers = (0..<11).map { "reengagement_\($0)" } + ["reengagement_app_opened", "reengagement_series_kickoff"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
        
        // Clear the flag
        UserDefaults.standard.set(false, forKey: "reengagement_scheduled")
        
        debugPrint("🗑️ Cancelled all re-engagement notifications")
    }
    
    /// Check if re-engagement notifications are currently scheduled
    func hasReengagementNotificationsScheduled() -> Bool {
        return UserDefaults.standard.bool(forKey: "reengagement_scheduled")
    }

    /// Re-schedule the series if the flag is stale or iOS dropped the pending requests.
    func ensureReengagementScheduled(includeImmediateKickoff: Bool = false) {
        guard guardSchedulingEnabled() else { return }
        if ShieldManager.shared.hasActiveUnlockSession() {
            debugPrint("⏳ Skipping re-engagement ensure — apps are unlocked")
            onAppsUnlocked()
            return
        }
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            let hasPending = requests.contains {
                $0.identifier.hasPrefix("reengagement_") || $0.identifier == "reengagement_series_kickoff"
            }
            guard !hasPending else { return }
            DispatchQueue.main.async {
                self?.scheduleReengagementNotifications(includeImmediateKickoff: includeImmediateKickoff)
            }
        }
    }
    
    // MARK: - Welcome Notifications
    
    func scheduleWelcomeNotifications() {
        guard guardSchedulingEnabled() else { return }
        // Check if we already scheduled welcome notifications
        if UserDefaults.standard.bool(forKey: "welcome_notifications_scheduled") {
            debugPrint("📅 Welcome notifications already scheduled, skipping")
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Welcome notifications schedule
        let notifications: [(hours: Int, title: String, body: String)] = [
            // 2 hours after download - Welcome
            (2, NSLocalizedString("notification.welcome.1.title", comment: "Welcome to ScrollDeeds"), NSLocalizedString("notification.welcome.1.body", comment: "Transform your screen time into worship. Start your journey today.")),
            
            // 24 hours after download - First reminder
            (24, NSLocalizedString("notification.welcome.2.title", comment: "Your Journey Awaits"), NSLocalizedString("notification.welcome.2.body", comment: "Take control of your screen time. Every moment counts.")),
            
            // 48 hours after download - Value proposition
            (48, NSLocalizedString("notification.welcome.3.title", comment: "Turn Scrolling Into Worship"), NSLocalizedString("notification.welcome.3.body", comment: "Join thousands who transformed their relationship with their phone. Start now."))
        ]
        
        for (index, notification) in notifications.enumerated() {
            guard let triggerDate = calendar.date(byAdding: .hour, value: notification.hours, to: now) else { continue }
            
            // Only schedule if the date is in the future
            guard triggerDate > now else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "WELCOME"
            content.userInfo = ["welcome": true, "notification_index": index]
            
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "welcome_\(index)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    debugPrint("❌ Failed to schedule welcome notification \(index): \(error)")
                } else {
                    debugPrint("✅ Welcome notification \(index) scheduled for +\(notification.hours) hours")
                }
            }
        }
        
        // Store that we've scheduled welcome notifications
        UserDefaults.standard.set(true, forKey: "welcome_notifications_scheduled")
        UserDefaults.standard.set(now, forKey: "welcome_start_date")
        
        debugPrint("📅 Scheduled \(notifications.count) welcome notifications")
    }
    
    /// Cancel welcome notifications (call when user subscribes)
    func cancelWelcomeNotifications() {
        let identifiers = (0..<5).map { "welcome_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
        
        UserDefaults.standard.set(false, forKey: "welcome_notifications_scheduled")
        
        debugPrint("🗑️ Cancelled all welcome notifications")
    }

    // MARK: - 10-Minute Welcome Back Nudge

    /// Schedule a one-time welcome-back nudge 10 minutes after the app first goes to background.
    /// After it has been scheduled once it is never rescheduled again.
    func scheduleTenMinuteWelcomeBackNotification() {
        guard guardSchedulingEnabled() else { return }
        if ShieldManager.shared.hasActiveUnlockSession() {
            debugPrint("⏳ Skipping welcome-back — apps are unlocked")
            return
        }
        let identifier = "welcome_back_10min"
        let deliveredKey = "welcome_back_10min_delivered"

        // Already delivered once — never send again.
        guard !UserDefaults.standard.bool(forKey: deliveredKey) else {
            debugPrint("⏭️ welcome-back nudge already delivered (lifetime), skipping")
            return
        }

        // Cancel any stale pending copy (defensive).
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let baseWelcomeTitle = NSLocalizedString("notification.welcome_back_10min.title", comment: "We miss you")
        let welcomeName = UserDefaults.standard.string(forKey: "userName")
            .flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let content = UNMutableNotificationContent()
        content.title = welcomeName.map { "\(baseWelcomeTitle), \($0)" } ?? baseWelcomeTitle
        content.body  = NSLocalizedString("notification.welcome_back_10min.body",  comment: "Come back to ScrollDeeds and continue your journey.")
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "WELCOME"
        content.userInfo = ["welcome_back_10min": true]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Failed to schedule 10-minute welcome-back notification: \(error)")
            } else {
                debugPrint("✅ Scheduled one-time 10-minute welcome-back notification")
            }
        }
    }

    /// Cancel the pending 10-minute welcome-back notification.
    func cancelTenMinuteWelcomeBackNotification() {
        let identifier = "welcome_back_10min"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        debugPrint("🗑️ Cancelled 10-minute welcome-back notification")
    }

    /// Cycles 1 → 2 → 3 → 1 for leave-app nudges (same core CTA; shorter copy so titles don’t truncate).
    private static let leaveAppWinbackCopyVariantKey = "leave_app_winback_copy_variant"

    private func localizedRotatingLeaveAppWinbackPair() -> (title: String, body: String) {
        let d = UserDefaults.standard
        let n = d.integer(forKey: Self.leaveAppWinbackCopyVariantKey)
        let variant = (n % 3) + 1
        d.set(n + 1, forKey: Self.leaveAppWinbackCopyVariantKey)
        let titleKey = "notification.leave_app_winback.\(variant).title"
        let bodyKey = "notification.leave_app_winback.\(variant).body"
        let title = NSLocalizedString(titleKey, comment: "")
        let body = NSLocalizedString(bodyKey, comment: "")
        if title == titleKey || body == bodyKey {
            return (
                NSLocalizedString("notification.leave_app_winback.1.title", comment: ""),
                NSLocalizedString("notification.leave_app_winback.1.body", comment: "")
            )
        }
        return (title, body)
    }

    // MARK: - Paywall leave nudge (removed)

    /// Clears any leftover 15s paywall-leave test notifications from older builds.
    func cancelPaywallLeaveConversionNudge() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["paywall_leave_conversion_nudge"]
        )
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["paywall_leave_conversion_nudge"]
        )
    }

    // MARK: - Immediate leave-app winback (non–StoreKit subscriber)

    private static let leaveAppWinbackIdentifier = "leave_app_non_subscriber_winback"
    private static let leaveAppWinbackDayKey = "leave_app_winback_calendar_day"
    private static let leaveAppWinbackCountKey = "leave_app_winback_count_today"
    /// Prevents runaway spam if something schedules repeatedly; still allows many genuine “leave app” events per day.
    private static let leaveAppWinbackMaxPerDay = 50
    /// Long enough to reach the Home Screen; short enough to verify in a real test.
    private static let leaveAppWinbackDelaySeconds: TimeInterval = 8

    /// Schedules a local notification shortly after the app backgrounds when the user has **not** purchased
    /// (no active RevenueCat entitlement) and is not on influencer access.
    /// Users on the **local** 3-day app trial are still eligible — they are not StoreKit subscribers yet.
    func scheduleLeaveAppNonSubscriberWinbackIfEligible(eligibleForLeaveAppWinback: Bool) {
        guard guardSchedulingEnabled() else { return }
        guard eligibleForLeaveAppWinback, !ShieldManager.shared.hasActiveUnlockSession() else {
            cancelLeaveAppNonSubscriberWinback()
            return
        }
        guard leaveAppWinbackCanScheduleToday() else {
            debugPrint("🔕 Leave-app winback skipped — daily cap reached")
            return
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.leaveAppWinbackIdentifier])

        let content = UNMutableNotificationContent()
        let winback = localizedRotatingLeaveAppWinbackPair()
        content.title = winback.title
        content.body = winback.body
        content.sound = .default
        content.userInfo = ["leave_app_winback": true]
        content.threadIdentifier = "scrolldeeds_conversion"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Self.leaveAppWinbackDelaySeconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.leaveAppWinbackIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Failed to schedule leave-app winback: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.recordLeaveAppWinbackScheduled()
            }
            debugPrint("✅ Scheduled leave-app winback (fires in ~\(Int(Self.leaveAppWinbackDelaySeconds))s if app stays backgrounded)")
            self.debugLogPendingNotifications()
        }
    }

    private func leaveAppWinbackCanScheduleToday() -> Bool {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let defaults = UserDefaults.standard
        if let stored = defaults.object(forKey: Self.leaveAppWinbackDayKey) as? Date, cal.isDate(stored, inSameDayAs: todayStart) {
            return defaults.integer(forKey: Self.leaveAppWinbackCountKey) < Self.leaveAppWinbackMaxPerDay
        }
        return true
    }

    private func recordLeaveAppWinbackScheduled() {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let defaults = UserDefaults.standard
        if let stored = defaults.object(forKey: Self.leaveAppWinbackDayKey) as? Date, cal.isDate(stored, inSameDayAs: todayStart) {
            let n = defaults.integer(forKey: Self.leaveAppWinbackCountKey) + 1
            defaults.set(n, forKey: Self.leaveAppWinbackCountKey)
        } else {
            defaults.set(todayStart, forKey: Self.leaveAppWinbackDayKey)
            defaults.set(1, forKey: Self.leaveAppWinbackCountKey)
        }
    }

    func cancelLeaveAppNonSubscriberWinback() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.leaveAppWinbackIdentifier])
    }

    // MARK: - App lifecycle (conversion + lock)

    /// Call from `didEnterBackground`. Schedules leave-app / re-engagement immediately
    /// (no async permission round-trip — iOS simply won't deliver if permission was denied).
    func handleAppDidEnterBackground(eligibleForConversion: Bool) {
        if let last = lastBackgroundHandleAt, Date().timeIntervalSince(last) < 1.2 {
            return
        }
        lastBackgroundHandleAt = Date()

        becomeActiveCancelWork?.cancel()
        becomeActiveCancelWork = nil

        // Unlocked users left to use the apps they just earned. Conversion copy
        // ("do a deed", "come back") is wrong here — silence it.
        scheduleDailySpiritualReminders()

        if ShieldManager.shared.hasActiveUnlockSession() {
            debugPrint("🔕 Skip conversion notifications — unlock session active")
            onAppsUnlocked()
            return
        }

        scheduleTenMinuteWelcomeBackNotification()

        // Leaving mid-onboarding is always a conversion moment — even if a leftover
        // sandbox/TestFlight subscription made `isPremium` true.
        let stillOnboarding = !LocalStorageManager.shared.hasCompletedOnboarding
        let shouldNudge = eligibleForConversion || stillOnboarding
        guard shouldNudge else {
            debugPrint("🔕 Skip leave-app / re-engagement — subscriber or influencer, onboarding done")
            cancelLeaveAppNonSubscriberWinback()
            cancelPaywallLeaveConversionNudge()
            return
        }

        debugPrint("📅 Background conversion nudge (onboardingIncomplete=\(stillOnboarding))")
        scheduleLeaveAppNonSubscriberWinbackIfEligible(eligibleForLeaveAppWinback: true)
        cancelPaywallLeaveConversionNudge()
        ensureReengagementScheduled(includeImmediateKickoff: false)
    }

    /// Call from `didBecomeActive`. Do **not** cancel conversion notifications here —
    /// a scene flicker or a 3-second peek back was deleting every test notification.
    /// If the user is actually in the app when one fires, `willPresent` hides the banner.
    func handleAppDidBecomeActive() {
        becomeActiveCancelWork?.cancel()
        becomeActiveCancelWork = nil
        checkAuthorizationStatus()
        cancelPaywallLeaveConversionNudge()
        if ShieldManager.shared.hasActiveUnlockSession() {
            onAppsUnlocked()
        }
        Task { @MainActor in
            FajrAlarmManager.shared.checkIfShouldRingOnForeground()
        }
    }
    
    // MARK: - Clear All
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearBadge()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Called when notification is received while app is in FOREGROUND
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        debugPrint("📱 Notification received while app is in foreground: \(notification.request.identifier)")

        guard notificationsEnabled else {
            completionHandler([])
            return
        }

        if shouldSuppressConversionNotification(notification) || shouldSuppressLockNotification(notification) {
            completionHandler([])
            return
        }

        if FajrAlarmManager.isFajrNotification(notification.request.identifier) {
            Task { @MainActor in
                FajrAlarmManager.shared.handleNotification(identifier: notification.request.identifier)
            }
        }

        // Conversion nudges: hide only when the user is truly back in the app.
        // App-switcher / inactive still presents — otherwise a 1–15s fire is swallowed forever.
        if notification.request.identifier == Self.leaveAppWinbackIdentifier
            || notification.request.identifier == "welcome_back_10min" {
            if UIApplication.shared.applicationState == .active {
                completionHandler([])
            } else {
                completionHandler([.banner, .sound])
            }
            return
        }
        
        // Check if this is the unlock expiry notification
        if notification.request.identifier == "unlock_expired_initial" || notification.request.identifier.starts(with: "unlock_expired_alarm_") || notification.request.identifier.starts(with: "recurring_lock_reminder_") {
            if ShieldManager.shared.hasActiveUnlockSession() {
                debugPrint("⏳ Ignoring stale unlock-expiry notification — session still active")
                cancelUnlockExpiryNotification()
                cancelRecurringTimeExpiredNotifications()
            } else {
                debugPrint("⏰ Unlock expired notification received - applying shield NOW!")
                ShieldManager.shared.forceApplyShieldOnExpiry()
            }
        }
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Called when user TAPS on notification OR when notification is delivered (app in background or closed)
    // This is called for ALL notifications, whether user taps or not
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        debugPrint("📱 Notification delivered/interacted: \(response.notification.request.identifier)")

        let fajrId = response.notification.request.identifier
        if FajrAlarmManager.isFajrNotification(fajrId) {
            if response.actionIdentifier == "FAJR_SNOOZE" {
                Task { @MainActor in
                    FajrAlarmManager.shared.snoozeFiveMinutes()
                }
            } else if response.actionIdentifier == UNNotificationDismissActionIdentifier {
                Task { @MainActor in
                    FajrAlarmManager.shared.dismissWithoutPhoto()
                }
            } else {
                Task { @MainActor in
                    FajrAlarmManager.shared.handleNotification(identifier: fajrId)
                }
            }
        }

        if response.notification.request.identifier == "welcome_back_10min" {
            UserDefaults.standard.set(true, forKey: "welcome_back_10min_delivered")
        }
        
        // Drop stale lock/expiry notifications when unlock session is still active.
        if shouldSuppressLockNotification(response.notification) {
            onAppsUnlocked()
            completionHandler()
            return
        }
        
        // CRITICAL: Apply shield immediately when expiry notification is delivered
        // Start background task to ensure shield is applied even if app is in background
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // Check if this is the daily recurring trigger notification
        if response.notification.request.identifier == "daily_recurring_trigger" {
            if ShieldManager.shared.hasActiveUnlockSession() {
                debugPrint("⏳ Ignoring daily recurring trigger — unlock session active")
                cancelDailyRecurringNotifications()
            } else if let expiryHour = response.notification.request.content.userInfo["expiry_hour"] as? Int,
               let expiryMinute = response.notification.request.content.userInfo["expiry_minute"] as? Int {
                debugPrint("📅 Daily recurring trigger fired - rescheduling notification series")
                rescheduleDailyNotificationSeries(expiryHour: expiryHour, expiryMinute: expiryMinute)
            }
        }
        
        // Check if this is the unlock expiry notification
        if response.notification.request.identifier == "unlock_expired_initial" || response.notification.request.identifier.starts(with: "unlock_expired_alarm_") || response.notification.request.identifier.starts(with: "recurring_lock_reminder_") || response.notification.request.identifier.starts(with: "daily_recurring_alarm_") {
            if ShieldManager.shared.hasActiveUnlockSession() {
                debugPrint("⏳ Ignoring stale unlock-expiry delivery — session still active")
                cancelUnlockExpiryNotification()
                cancelRecurringTimeExpiredNotifications()
            } else {
                debugPrint("⏰⏰⏰ Expiry notification delivered - FORCING shield application NOW!")
                ShieldManager.shared.forceApplyShieldOnExpiry()
            }
        }
        
        // Check if user TAPPED on notification (not just delivered)
        // If user tapped and app is locked, schedule 8 reminders every 30 minutes
        if response.actionIdentifier != UNNotificationDefaultActionIdentifier {
            // User tapped a specific action, not the notification itself
            debugPrint("🔓 User tapped action: \(response.actionIdentifier)")
        } else {
            // User tapped the notification itself
            debugPrint("👆 User tapped notification: \(response.notification.request.identifier)")
            
            // Check if shield is active (app is locked)
            if ShieldManager.shared.isShieldActive && !ShieldManager.shared.hasActiveUnlockSession() {
                debugPrint("🔒 App is locked - refreshing session reminders (max \(Self.maxRemindersPerLockSession))")
                scheduleLockedAppRemindersAfterTap()
            }
        }
        
        // Handle action if needed
        if response.actionIdentifier == "UNLOCK_ACTION" {
            // User wants to unlock - this will be handled by the app UI
            debugPrint("🔓 User tapped unlock action")
        }
        
        // End background task after a short delay to ensure shield is applied
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = .invalid
            }
        }
        
        completionHandler()
    }
}


