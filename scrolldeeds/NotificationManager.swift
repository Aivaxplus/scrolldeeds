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
        
        // Schedule RECURRING notifications that keep going off every 15 seconds
        // These will keep ringing until user opens the app
        // Limit to first 60 notifications (15 minutes) to stay under iOS limit
        scheduleRecurringAlarmNotifications(startingAt: expiresAt, limit: 60)
    }
    
    // Schedule recurring alarm notifications that keep going off until user opens app
    private func scheduleRecurringAlarmNotifications(startingAt: Date, limit: Int = 60) {
        // Cancel any existing recurring alarms
        cancelRecurringTimeExpiredNotifications()
        
        // Schedule multiple notifications every 15 seconds
        // Limit to stay under iOS's 64 notification limit
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
            let notificationTime = startingAt.addingTimeInterval(Double(i) * 15.0) // Every 15 seconds
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
            content.userInfo = ["unlock_expired": true, "requires_app_open": true, "alarm_number": i]
            content.threadIdentifier = "shield_expiry"
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "unlock_expired_alarm_\(i)",
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
        
        debugPrint("✅ Scheduled \(scheduledCount) recurring alarm notifications (every 15 seconds for \(limit * 15 / 60) minutes)")
        debugPrint("✅ Alarms continue until the user returns to ScrollDeeds")
    }
    
    func cancelUnlockExpiryNotification() {
        // Cancel initial notification
        let initialIdentifier = ["unlock_expired_initial"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: initialIdentifier)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: initialIdentifier)
        
        // Cancel all alarm notifications (1-120)
        let alarmIdentifiers = (1...120).map { "unlock_expired_alarm_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: alarmIdentifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: alarmIdentifiers)
        
        // Cancel recurring reminder notifications as well
        let reminderIdentifiers = (1...6).map { "recurring_lock_reminder_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: reminderIdentifiers)
        
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
        let alarmIdentifiers = (1...120).map { "unlock_expired_alarm_\($0)" }
        let allIdentifiers = reminderIdentifiers + alarmIdentifiers
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIdentifiers)
        
        // Also remove any delivered notifications to clear the notification center
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: allIdentifiers)
        
        debugPrint("🗑️ Cancelled all recurring time expired notifications and alarms (pending + delivered)")
    }
    
    // MARK: - Locked App Reminder Notifications (when shield is active)
    
    /// Schedule recurring reminder notifications when apps are locked
    /// These remind the user to do dhikr to unlock their apps
    /// Uses calendar-based triggers for better reliability
    func scheduleLockedAppReminders() {
        // Cancel any existing reminders first
        cancelLockedAppReminders()
        
        // Schedule notifications every 10 minutes using calendar triggers
        // This is more reliable than time interval triggers
        let reminderMessages = [
            "Your apps are locked. Complete dhikr in ScrollDeeds to unlock them.",
            "Take a mindful moment. Return to ScrollDeeds to unlock your apps.",
            "Time for reflection. Open ScrollDeeds and complete your practice.",
            "Your apps await. Complete dhikr in ScrollDeeds to continue.",
            "A mindful break helps. Return to ScrollDeeds to unlock.",
            "Pause and reflect. Complete your practice in ScrollDeeds.",
            "Your apps are ready. Unlock them with dhikr in ScrollDeeds.",
            "Take a moment. Return to ScrollDeeds to unlock your apps.",
            "Mindful practice awaits. Open ScrollDeeds to continue.",
            "Your apps are waiting. Complete dhikr in ScrollDeeds."
        ]
        
        // Schedule notifications for the next 6 hours (every 10 minutes)
        // Use calendar-based triggers starting from now
        let calendar = Calendar.current
        let now = Date()
        
        // Schedule first 12 notifications (2 hours worth) to stay under iOS limit
        // We'll reschedule more when app opens again
        for i in 1...12 {
            let notificationTime = calendar.date(byAdding: .minute, value: i * 10, to: now)!
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
            
            // Rotate through messages
            let messageIndex = (i - 1) % reminderMessages.count
            let selectedMessage = reminderMessages[messageIndex]
            
            let content = UNMutableNotificationContent()
            content.title = "ScrollDeeds Reminder"
            content.body = selectedMessage
            content.sound = .default
            content.categoryIdentifier = "DHIKR_REMINDER"
            content.badge = 1
            content.userInfo = ["locked_app_reminder": true, "reminder_number": i, "scheduled_at": notificationTime.timeIntervalSince1970]
            
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
        
        debugPrint("📅 Scheduled 12 locked app reminder notifications (every 10 minutes for 2 hours)")
        debugPrint("📅 More will be scheduled when app opens again if shield is still active")
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
        
        // Check if this is the unlock expiry notification
        if response.notification.request.identifier == "unlock_expired_initial" || response.notification.request.identifier.starts(with: "unlock_expired_alarm_") || response.notification.request.identifier.starts(with: "recurring_lock_reminder_") {
            // CRITICAL: Apply shield immediately - this works in background too!
            debugPrint("⏰⏰⏰ CRITICAL: Expiry notification delivered - FORCING shield application NOW!")
            ShieldManager.shared.forceApplyShieldOnExpiry()
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


