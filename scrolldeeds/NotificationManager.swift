//
//  NotificationManager.swift
//  scrolldeeds
//
//  Manages push notifications for dhikr reminders and unlock timer
//

import SwiftUI
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

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isAuthorized: Bool = false
    
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
        // Set this instance as the delegate to handle notifications
        UNUserNotificationCenter.current().delegate = self
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
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func registerCategories() {
        // Actions for notifications
        let unlockAction = UNNotificationAction(
            identifier: "UNLOCK_ACTION",
            title: "Unlock Now",
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Remind Me Later",
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
        
        UNUserNotificationCenter.current().setNotificationCategories([unlockCategory, reminderCategory, blockedAppCategory])
    }
    
    // MARK: - Unlock Timer Notification
    
    func scheduleUnlockExpiryNotification(expiresAt: Date) {
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
        content.title = "Session Complete"
        content.body = "Your mindful break has ended. Return to ScrollDeeds to continue your practice."
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
        
        // Schedule RECURRING notifications that keep going off every 30 seconds
        // Pattern: 60 notifications, then wait 4 hours, then repeat
        scheduleRecurringAlarmNotifications(startingAt: expiresAt, limit: 60, cycleNumber: 1)
        
        // Store the expiry hour for daily recurring notifications
        let calendar = Calendar.current
        let expiryComponents = calendar.dateComponents([.hour, .minute], from: expiresAt)
        UserDefaults.standard.set(expiryComponents.hour, forKey: "unlock_expiry_hour")
        UserDefaults.standard.set(expiryComponents.minute, forKey: "unlock_expiry_minute")
        
        // Schedule daily recurring notifications starting tomorrow at the same hour
        scheduleDailyRecurringNotifications(expiryHour: expiryComponents.hour ?? 0, expiryMinute: expiryComponents.minute ?? 0)
    }
    
    // Schedule recurring alarm notifications that keep going off until user opens app
    // Pattern: 60 notifications every 60 seconds (1 hour), then wait 2 hours, then repeat
    // iOS LIMIT: Maximum 64 pending notifications per app
    private func scheduleRecurringAlarmNotifications(startingAt: Date, limit: Int = 60, cycleNumber: Int = 1) {
        // Cancel any existing recurring alarms for this cycle
        cancelRecurringTimeExpiredNotifications()
        
        // Schedule multiple notifications every 60 seconds (1 minute)
        // 60 notifications × 60 seconds = 60 minutes = 1 hour of reminders
        // Limit to stay under iOS's 64 notification limit
        let intervalSeconds: Double = 60.0 // 60 seconds (1 minute) between notifications
        
        // Use varied messages to avoid repetition
        let alarmMessages = [
            "Return to ScrollDeeds to continue your mindful practice.",
            "Your session has ended. Open ScrollDeeds to stay accountable.",
            "Time to return. ScrollDeeds is waiting for you.",
            "Complete your practice cycle. Return to ScrollDeeds now.",
            "Your mindful break is over. Come back to ScrollDeeds.",
            "Session ended. Return to ScrollDeeds to maintain focus.",
            "Time's up. Open ScrollDeeds to continue your journey.",
            "Your practice window closed. Return to ScrollDeeds.",
            "Break complete. ScrollDeeds needs your attention.",
            "Session finished. Come back to ScrollDeeds now."
        ]
        
        let calendar = Calendar.current
        var scheduledCount = 0
        
        for i in 1...limit {
            let notificationTime = startingAt.addingTimeInterval(Double(i) * intervalSeconds) // Every 15 seconds
            let timeInterval = notificationTime.timeIntervalSinceNow
            
            guard timeInterval > 0 else { continue }
            
            // Use calendar trigger for better reliability
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationTime)
            
            // Rotate through messages to avoid repetition
            let messageIndex = (i - 1) % alarmMessages.count
            let selectedMessage = alarmMessages[messageIndex]
            
            let content = UNMutableNotificationContent()
            content.title = "ScrollDeeds"
            content.body = selectedMessage
            content.sound = .default
            content.categoryIdentifier = "UNLOCK_EXPIRED"
            content.badge = NSNumber(value: i + 1)
            content.userInfo = [
                "unlock_expired": true,
                "requires_app_open": true,
                "alarm_number": i,
                "cycle_number": cycleNumber
            ]
            content.threadIdentifier = "shield_expiry"
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "unlock_expired_alarm_\(cycleNumber)_\(i)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    debugPrint("❌ Failed to schedule alarm notification \(i): \(error.localizedDescription)")
                } else {
                    scheduledCount += 1
                }
            }
        }
        
        // After 60 notifications (15 minutes with 15s interval), schedule a trigger notification 2 hours later
        // This trigger will reschedule another 60 notifications
        let lastNotificationTime = startingAt.addingTimeInterval(Double(limit) * intervalSeconds)
        let nextCycleStartTime = lastNotificationTime.addingTimeInterval(2 * 60 * 60) // 2 hours later
        
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: nextCycleStartTime)
        
        let triggerContent = UNMutableNotificationContent()
        triggerContent.title = "ScrollDeeds"
        triggerContent.body = "Return to ScrollDeeds to continue your mindful practice."
        triggerContent.sound = .default
        triggerContent.categoryIdentifier = "UNLOCK_EXPIRED"
        triggerContent.userInfo = [
            "unlock_expired": true,
            "requires_app_open": true,
            "reschedule_cycle": true,
            "cycle_number": cycleNumber + 1,
            "original_expiry": startingAt.timeIntervalSince1970
        ]
        triggerContent.threadIdentifier = "shield_expiry_cycle"
        
        let triggerRequest = UNNotificationRequest(
            identifier: "unlock_expired_cycle_trigger_\(cycleNumber)",
            content: triggerContent,
            trigger: UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(triggerRequest) { error in
            if let error = error {
                debugPrint("❌ Failed to schedule cycle trigger: \(error.localizedDescription)")
            } else {
                debugPrint("✅ Scheduled cycle trigger for 2 hours later (cycle \(cycleNumber + 1))")
            }
        }
        
        let totalMinutes = Int(Double(limit) * intervalSeconds / 60.0)
        debugPrint("✅ Scheduled \(scheduledCount) recurring alarm notifications (cycle \(cycleNumber), every 1 minute for \(totalMinutes) minutes)")
        debugPrint("✅ Next cycle will start in 2 hours if user hasn't opened app")
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
        
        guard let firstNotificationDate = calendar.date(from: dateComponents) else { return }
        
        // Schedule a single notification that will trigger tomorrow to reschedule the series
        // This notification will check if user opened app, and if not, reschedule 60 notifications
        let content = UNMutableNotificationContent()
        content.title = "ScrollDeeds"
        content.body = "Return to ScrollDeeds to continue your mindful practice."
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
    
    // Reschedule the series of 60 notifications for today (called when daily trigger fires)
    // Uses 60 second intervals (same as recurring alarms) = 1 hour of notifications
    func rescheduleDailyNotificationSeries(expiryHour: Int, expiryMinute: Int) {
        let calendar = Calendar.current
        let now = Date()
        let intervalSeconds = 60 // 60 seconds (1 minute) between notifications
        
        // Get today at the expiry hour
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = expiryHour
        dateComponents.minute = expiryMinute
        dateComponents.second = 0
        
        guard let firstNotificationDate = calendar.date(from: dateComponents) else { return }
        
        // If the time has already passed today, schedule for tomorrow
        let targetDate = firstNotificationDate < now ? calendar.date(byAdding: .day, value: 1, to: firstNotificationDate)! : firstNotificationDate
        
        let alarmMessages = [
            "Return to ScrollDeeds to continue your mindful practice.",
            "Your session has ended. Open ScrollDeeds to stay accountable.",
            "Time to return. ScrollDeeds is waiting for you.",
            "Complete your practice cycle. Return to ScrollDeeds now.",
            "Your mindful break is over. Come back to ScrollDeeds.",
            "Session ended. Return to ScrollDeeds to maintain focus.",
            "Time's up. Open ScrollDeeds to continue your journey.",
            "Your practice window closed. Return to ScrollDeeds.",
            "Break complete. ScrollDeeds needs your attention.",
            "Session finished. Come back to ScrollDeeds now."
        ]
        
        var scheduledCount = 0
        
        for i in 1...60 {
            guard let notificationTime = calendar.date(byAdding: .second, value: (i - 1) * intervalSeconds, to: targetDate) else { continue }
            let notificationComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationTime)
            
            // Rotate through messages
            let messageIndex = (i - 1) % alarmMessages.count
            let selectedMessage = alarmMessages[messageIndex]
            
            let content = UNMutableNotificationContent()
            content.title = "ScrollDeeds"
            content.body = selectedMessage
            content.sound = .default
            content.categoryIdentifier = "UNLOCK_EXPIRED"
            content.badge = NSNumber(value: i + 1)
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
        
        let totalMinutes = (60 * intervalSeconds) / 60
        debugPrint("✅ Rescheduled \(scheduledCount) daily recurring notifications for \(targetDate) (every 1 minute for \(totalMinutes) minutes)")
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
    
    // Schedule 8 reminders every 30 minutes when user taps notification and app is locked
    func scheduleLockedAppRemindersAfterTap() {
        // Cancel any existing reminders first
        cancelLockedAppRemindersAfterTap()
        
        let calendar = Calendar.current
        let now = Date()
        
        let reminderMessages = [
            "Your apps are locked. Complete dhikr in ScrollDeeds to unlock them.",
            "Take a mindful moment. Return to ScrollDeeds to unlock your apps.",
            "Time for reflection. Open ScrollDeeds and complete your practice.",
            "Your apps await. Complete dhikr in ScrollDeeds to continue.",
            "A mindful break helps. Return to ScrollDeeds to unlock.",
            "Pause and reflect. Complete your practice in ScrollDeeds.",
            "Your apps are ready. Unlock them with dhikr in ScrollDeeds.",
            "Take a moment. Return to ScrollDeeds to unlock your apps."
        ]
        
        var scheduledCount = 0
        
        // Schedule 8 reminders every 30 minutes
        for i in 1...8 {
            guard let reminderTime = calendar.date(byAdding: .minute, value: i * 30, to: now) else { continue }
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
            
            let messageIndex = (i - 1) % reminderMessages.count
            let selectedMessage = reminderMessages[messageIndex]
            
            let content = UNMutableNotificationContent()
            content.title = "ScrollDeeds Reminder"
            content.body = selectedMessage
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
        
        debugPrint("✅ Scheduled \(scheduledCount) locked app reminders (every 30 minutes, 8 times)")
    }
    
    func cancelLockedAppRemindersAfterTap() {
        let reminderIdentifiers = (1...8).map { "locked_app_reminder_after_tap_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: reminderIdentifiers)
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
        let fiveMinutesBefore = expiresAt.addingTimeInterval(-5 * 60)
        let timeInterval = fiveMinutesBefore.timeIntervalSinceNow
        
        guard timeInterval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "5 Minutes Remaining"
        content.body = "Your mindful break ends soon. Use this time intentionally and prepare to return to ScrollDeeds."
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
        cancelDailyReminders()
        
        for (index, time) in times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Time for Your Practice"
            content.body = "Take a mindful moment. Complete your dhikr in ScrollDeeds to unlock your apps."
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
    
    // MARK: - Streak Notification
    
    func scheduleStreakReminder() {
        let streak = UserDefaults.standard.integer(forKey: "currentStreak")
        let content = UNMutableNotificationContent()
        content.title = "Maintain Your Streak"
        content.body = "You're on a \(streak)-day streak. Complete a session today to keep it going."
        content.sound = .default
        
        // Schedule for 8 PM today if user hasn't done any sessions
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelStreakReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])
    }
    
    // MARK: - Blocked App Notification
    
    func sendBlockedAppNotification() {
        let content = UNMutableNotificationContent()
        content.title = "App Locked"
        content.body = "Complete your dhikr practice in ScrollDeeds to unlock access."
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
        // Cancel any existing recurring notifications first
        cancelRecurringTimeExpiredNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = "Ready for Your Next Session"
        content.body = "Your previous session ended. Return to ScrollDeeds to start a new mindful break."
        content.sound = .default
        content.categoryIdentifier = "UNLOCK_EXPIRED"
        content.badge = 1
        
        // Schedule notifications every 5 minutes after unlock expires (6 notifications total)
        // This reminds the user to complete dhikr again
        for i in 1...6 {
            let timeInterval = Double(i * 5 * 60) // 5, 10, 15, 20, 25, 30 minutes after unlock expired
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
                    debugPrint("✅ Recurring notification \(i) scheduled for +\(i*5) minutes")
                }
            }
        }
        
        debugPrint("📅 Scheduled 6 recurring notifications (every 5 minutes)")
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
    
    /// Schedule recurring reminder notifications when apps are locked
    /// These remind the user to do dhikr to unlock their apps
    /// Uses calendar-based triggers for better reliability
    func scheduleLockedAppReminders() {
        // Cancel ALL existing notifications first to avoid duplicates
        cancelLockedAppReminders()
        cancelRecurringTimeExpiredNotifications()
        cancelLockedAppRemindersAfterTap()
        
        // Use a single, professional, consistent message
        let professionalMessage = "Your apps are locked. Complete dhikr in ScrollDeeds to unlock them."
        
        // Schedule notifications every 30 minutes (less spammy, more professional)
        // Use calendar-based triggers starting from now
        let calendar = Calendar.current
        let now = Date()
        
        // Schedule 8 notifications (4 hours worth) - professional and not overwhelming
        for i in 1...8 {
            let notificationTime = calendar.date(byAdding: .minute, value: i * 30, to: now)!
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
            
            let content = UNMutableNotificationContent()
            content.title = "ScrollDeeds"
            content.body = professionalMessage
            content.sound = .default
            content.categoryIdentifier = "DHIKR_REMINDER"
            content.badge = NSNumber(value: i)
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
                } else {
                    debugPrint("✅ Locked app reminder \(i) scheduled for \(notificationTime)")
                }
            }
        }
        
        debugPrint("📅 Scheduled 8 professional locked app reminder notifications (every 30 minutes for 4 hours)")
    }
    
    func cancelLockedAppReminders() {
        // Cancel all reminder notifications (check up to 100 to be safe)
        let reminderIdentifiers = (1...100).map { "locked_app_reminder_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: reminderIdentifiers)
        debugPrint("🗑️ Cancelled all locked app reminder notifications (pending + delivered)")
    }
    
    // MARK: - Badge Management
    
    func updateBadge(count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
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
        
        // Check if this is a cycle trigger notification (reschedule next cycle)
        if notification.request.identifier.starts(with: "unlock_expired_cycle_trigger_") {
            if let cycleNumber = notification.request.content.userInfo["cycle_number"] as? Int,
               let originalExpiryTimestamp = notification.request.content.userInfo["original_expiry"] as? TimeInterval {
                let originalExpiry = Date(timeIntervalSince1970: originalExpiryTimestamp)
                debugPrint("🔄 Cycle trigger received in foreground - rescheduling cycle \(cycleNumber)")
                // Reschedule another 60 notifications starting now
                scheduleRecurringAlarmNotifications(startingAt: Date(), limit: 60, cycleNumber: cycleNumber)
            }
        }
        
        // Check if this is the unlock expiry notification
        if notification.request.identifier == "unlock_expired_initial" || notification.request.identifier.starts(with: "unlock_expired_alarm_") || notification.request.identifier.starts(with: "recurring_lock_reminder_") {
            // CRITICAL: Apply shield immediately when notification is received
            debugPrint("⏰ CRITICAL: Unlock expired notification received - applying shield NOW!")
            ShieldManager.shared.forceApplyShieldOnExpiry()
        }
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Called when user TAPS on notification OR when notification is delivered (app in background or closed)
    // This is called for ALL notifications, whether user taps or not
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        debugPrint("📱 Notification delivered/interacted: \(response.notification.request.identifier)")
        
        // CRITICAL: Apply shield immediately when expiry notification is delivered
        // Start background task to ensure shield is applied even if app is in background
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // Check if this is the daily recurring trigger notification
        if response.notification.request.identifier == "daily_recurring_trigger" {
            // This is the daily trigger - reschedule the series if user hasn't opened app
            if let expiryHour = response.notification.request.content.userInfo["expiry_hour"] as? Int,
               let expiryMinute = response.notification.request.content.userInfo["expiry_minute"] as? Int {
                debugPrint("📅 Daily recurring trigger fired - rescheduling notification series")
                rescheduleDailyNotificationSeries(expiryHour: expiryHour, expiryMinute: expiryMinute)
            }
        }
        
        // Check if this is a cycle trigger notification (reschedule next cycle)
        if response.notification.request.identifier.starts(with: "unlock_expired_cycle_trigger_") {
            if let cycleNumber = response.notification.request.content.userInfo["cycle_number"] as? Int,
               let originalExpiryTimestamp = response.notification.request.content.userInfo["original_expiry"] as? TimeInterval {
                let originalExpiry = Date(timeIntervalSince1970: originalExpiryTimestamp)
                debugPrint("🔄 Cycle trigger fired - rescheduling cycle \(cycleNumber)")
                // Reschedule another 60 notifications starting now
                scheduleRecurringAlarmNotifications(startingAt: Date(), limit: 60, cycleNumber: cycleNumber)
            }
        }
        
        // Check if this is the unlock expiry notification
        if response.notification.request.identifier == "unlock_expired_initial" || response.notification.request.identifier.starts(with: "unlock_expired_alarm_") || response.notification.request.identifier.starts(with: "recurring_lock_reminder_") || response.notification.request.identifier.starts(with: "daily_recurring_alarm_") {
            // CRITICAL: Apply shield immediately - this works in background too!
            debugPrint("⏰⏰⏰ CRITICAL: Expiry notification delivered - FORCING shield application NOW!")
            ShieldManager.shared.forceApplyShieldOnExpiry()
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
            if ShieldManager.shared.isShieldActive {
                debugPrint("🔒 App is locked - scheduling 8 reminders every 30 minutes")
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


