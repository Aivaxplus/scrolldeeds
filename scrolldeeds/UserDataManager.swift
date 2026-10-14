//
//  UserDataManager.swift
//  scrolldeeds
//
//  Manages all user progress data locally using UserDefaults
//

import SwiftUI
import Combine

struct DailyStats: Codable {
    let date: Date
    var sessions: Int
    var minutes: Int
}

class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    
    @Published var todaySessions: Int = 0
    @Published var todayMinutes: Int = 0
    /// Real minutes spent on shielded apps today (DeviceActivity). Used by heart health — not unlock budget.
    @Published var todayScrollMinutes: Int = 0
    @Published var totalSessions: Int = 0
    @Published var totalMinutes: Int = 0
    @Published var currentStreak: Int = 0
    @Published var lastSessionDate: Date?
    @Published var dailyHistory: [DailyStats] = []
    @Published var dailyGoalCompleted: Bool = false // True when 5 sessions completed today
    @Published var lastDayCompleted: Date? // Last date when daily goal was completed
    @Published var userAge: String? = nil // Age group (e.g., "18-24")
    @Published var userName: String? = nil // Display name from onboarding
    @Published var referralSource: String? = nil // How they heard about us
    @Published var userID: String // Unique user identifier
    @Published var commitmentLevel: Int = 0 // 0-4 scale from questionnaire
    /// Onboarding-only: 0 = gentle, 1 = balanced, 2 = strict (how firm the system should feel).
    @Published var onboardingDifficultyLevel: Int = 1
    /// Minutes the next deed unlocks — published so the dashboard updates when difficulty changes.
    @Published private(set) var preferredUnlockMinutes: Int = 30
    
    private let defaults = UserDefaults.standard
    private let appGroup = UserDefaults(suiteName: "group.com.scrolldeeds.app")
    
    // Simple local keys (no user ID needed)
    private let sessionsKey = "todaySessions"
    private let minutesKey = "todayMinutes"
    private let scrollMinutesKey = "todayScrollMinutes"
    static let appGroupScrollMinutesKey = "heartTodayScrollMinutes"
    static let appGroupScrollDayKey = "heartScrollDayStart"
    private let totalSessionsKey = "totalSessions"
    private let totalMinutesKey = "totalMinutes"
    private let streakKey = "currentStreak"
    private let lastSessionKey = "lastSessionDate"
    private let lastResetKey = "lastResetDate"
    private let dailyHistoryKey = "dailyHistory"
    private let userAgeKey = "userAge"
    private let userNameKey = "userName"
    private let referralSourceKey = "referralSource"
    private let userIDKey = "userID"
    private let commitmentLevelKey = "commitmentLevel"
    private let onboardingDifficultyLevelKey = "onboardingDifficultyLevel"
    /// Persisted unlock budget (minutes) chosen via onboarding Easy / Medium / Hard.
    private let onboardingPreferredUnlockMinutesKey = "onboardingPreferredUnlockMinutes"
    static let pendingUnlockMinutesKey = "pendingUnlockMinutes"
    private let dailyGoalCompletedKey = "dailyGoalCompleted"
    private let lastDayCompletedKey = "lastDayCompleted"

    /// Minutes granted for the deed that just finished. Uses pending if set,
    /// otherwise the Easy / Medium / Hard choice.
    var unlockDurationMinutes: Int {
        let pending = UserDefaults.standard.integer(forKey: Self.pendingUnlockMinutesKey)
        return pending > 0 ? pending : effectiveUnlockMinutesAfterDeed()
    }

    var unlockDurationHours: Int { unlockDurationMinutes / 60 }
    
    // Daily goal: 5 sessions = day completed
    let dailyGoalSessions = 5
    
    private init() {
        // Generate or load unique user ID
        if let savedUserID = defaults.string(forKey: userIDKey) {
            self.userID = savedUserID
        } else {
            // Generate new UUID for this user
            self.userID = UUID().uuidString
            defaults.set(self.userID, forKey: userIDKey)
            defaults.synchronize()
        }
        loadData()
    }
    
    // MARK: - Local Storage Methods
    
    private func saveData() {
        defaults.set(todaySessions, forKey: sessionsKey)
        defaults.set(todayMinutes, forKey: minutesKey)
        defaults.set(todayScrollMinutes, forKey: scrollMinutesKey)
        defaults.set(totalSessions, forKey: totalSessionsKey)
        defaults.set(totalMinutes, forKey: totalMinutesKey)
        defaults.set(currentStreak, forKey: streakKey)
        defaults.set(lastSessionDate, forKey: lastSessionKey)
        defaults.set(userAge, forKey: userAgeKey)
        defaults.set(userName, forKey: userNameKey)
        defaults.set(referralSource, forKey: referralSourceKey)
        defaults.set(userID, forKey: userIDKey) // Save user ID
        defaults.set(dailyGoalCompleted, forKey: dailyGoalCompletedKey)
        defaults.set(lastDayCompleted, forKey: lastDayCompletedKey)
        syncScrollMinutesToAppGroup()
        
        if let encoded = try? JSONEncoder().encode(dailyHistory) {
            defaults.set(encoded, forKey: dailyHistoryKey)
        }
    }
    
    func setUserAge(_ age: String) {
        userAge = age
        defaults.set(age, forKey: userAgeKey)
    }
    
    func setUserName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        userName = trimmed.isEmpty ? nil : trimmed
        defaults.set(userName, forKey: userNameKey)
    }
    
    func setReferralSource(_ source: String) {
        referralSource = source
        defaults.set(source, forKey: referralSourceKey)
    }
    
    func setCommitmentLevel(_ level: Int) {
        commitmentLevel = level
        defaults.set(level, forKey: commitmentLevelKey)
    }
    
    /// How long one heart lasts on the locked apps. Easy 15, medium 10, hard 5.
    static func onboardingUnlockMinutes(forDifficultyLevel level: Int) -> Int {
        switch min(2, max(0, level)) {
        case 0: return 15
        case 2: return 5
        default: return 10
        }
    }
    
    /// Minutes granted after each completed good deed. Uses onboarding choice when set; otherwise legacy **10** min.
    func effectiveUnlockMinutesAfterDeed() -> Int {
        if preferredUnlockMinutes >= 5 && preferredUnlockMinutes <= 120 {
            return preferredUnlockMinutes
        }
        if defaults.object(forKey: onboardingPreferredUnlockMinutesKey) != nil {
            let m = defaults.integer(forKey: onboardingPreferredUnlockMinutesKey)
            if m >= 5 && m <= 120 { return m }
        }
        if defaults.object(forKey: onboardingDifficultyLevelKey) != nil {
            return Self.onboardingUnlockMinutes(forDifficultyLevel: onboardingDifficultyLevel)
        }
        return 10
    }

    func clearPendingUnlockMinutes() {
        UserDefaults.standard.removeObject(forKey: Self.pendingUnlockMinutesKey)
    }
    
    func setOnboardingDifficultyLevel(_ level: Int) {
        let clamped = min(2, max(0, level))
        onboardingDifficultyLevel = clamped
        defaults.set(clamped, forKey: onboardingDifficultyLevelKey)
        let minutes = Self.onboardingUnlockMinutes(forDifficultyLevel: clamped)
        preferredUnlockMinutes = minutes
        defaults.set(minutes, forKey: onboardingPreferredUnlockMinutesKey)
        // Don't let the last deed's minutes keep the dashboard stuck on +60.
        clearPendingUnlockMinutes()
        NafsiLivesManager.shared.applyDifficulty()
    }
    
    func loadData() {
        todaySessions = defaults.integer(forKey: sessionsKey)
        todayMinutes = defaults.integer(forKey: minutesKey)
        todayScrollMinutes = defaults.integer(forKey: scrollMinutesKey)
        totalSessions = defaults.integer(forKey: totalSessionsKey)
        totalMinutes = defaults.integer(forKey: totalMinutesKey)
        currentStreak = defaults.integer(forKey: streakKey)
        
        if let date = defaults.object(forKey: lastSessionKey) as? Date {
            lastSessionDate = date
        }
        
        // Load user demographics
        userAge = defaults.string(forKey: userAgeKey)
        userName = defaults.string(forKey: userNameKey)
        referralSource = defaults.string(forKey: referralSourceKey)
        commitmentLevel = defaults.integer(forKey: commitmentLevelKey)
        if defaults.object(forKey: onboardingDifficultyLevelKey) != nil {
            onboardingDifficultyLevel = min(2, max(0, defaults.integer(forKey: onboardingDifficultyLevelKey)))
            preferredUnlockMinutes = Self.onboardingUnlockMinutes(forDifficultyLevel: onboardingDifficultyLevel)
            defaults.set(preferredUnlockMinutes, forKey: onboardingPreferredUnlockMinutesKey)
        } else if defaults.object(forKey: onboardingPreferredUnlockMinutesKey) != nil {
            let stored = defaults.integer(forKey: onboardingPreferredUnlockMinutesKey)
            preferredUnlockMinutes = (stored >= 5 && stored <= 120) ? stored : 10
        } else {
            onboardingDifficultyLevel = 1
            preferredUnlockMinutes = 10
        }
        
        // Load user ID (should already be set in init, but load for consistency)
        if let savedUserID = defaults.string(forKey: userIDKey) {
            userID = savedUserID
        }
        
        // Load daily history
        if let data = defaults.data(forKey: dailyHistoryKey),
           let history = try? JSONDecoder().decode([DailyStats].self, from: data) {
            dailyHistory = history
        }
        
        // Load daily goal completion
        dailyGoalCompleted = defaults.bool(forKey: dailyGoalCompletedKey)
        if let date = defaults.object(forKey: lastDayCompletedKey) as? Date {
            lastDayCompleted = date
        }
    }
    
    func checkDailyReset() {
        let lastReset = defaults.object(forKey: lastResetKey) as? Date ?? Date.distantPast
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if !calendar.isDateInToday(lastReset) {
            // Check if yesterday's goal was completed
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if let lastCompleted = lastDayCompleted {
                if !calendar.isDate(lastCompleted, inSameDayAs: yesterday) {
                    // Yesterday was not completed - streak broken
                    if currentStreak > 0 {
                        currentStreak = 0
                        defaults.set(0, forKey: streakKey)
                    }
                }
            } else {
                // No previous completion - streak is 0
                if currentStreak > 0 {
                    currentStreak = 0
                    defaults.set(0, forKey: streakKey)
                }
            }
            
            // Check if yesterday had any sessions
            if todaySessions == 0 && lastSessionDate != nil {
                // User didn't do any sessions yesterday - schedule streak reminder
                NotificationManager.shared.scheduleStreakReminder()
            }
            
            // Reset daily stats
            todaySessions = 0
            todayMinutes = 0
            todayScrollMinutes = 0
            dailyGoalCompleted = false
            defaults.set(0, forKey: sessionsKey)
            defaults.set(0, forKey: minutesKey)
            defaults.set(0, forKey: scrollMinutesKey)
            defaults.set(false, forKey: dailyGoalCompletedKey)
            defaults.set(Date(), forKey: lastResetKey)
            syncScrollMinutesToAppGroup(forceDay: today)
            
            // Reset daily goal notification tracking (allow new notifications for new day)
            UserDefaults.standard.removeObject(forKey: "last_daily_goal_notification_date")
        } else {
            mergeScrollMinutesFromAppGroup()
        }
    }

    /// Pull scroll totals written by the DeviceActivity extension (auto-lock in background).
    /// Safe to call often — never lowers today's committed total except on day reset.
    func mergeScrollMinutesFromAppGroup() {
        guard let group = appGroup else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let stored = group.object(forKey: Self.appGroupScrollDayKey) as? Date,
           !calendar.isDate(stored, inSameDayAs: today) {
            // Stale day in the extension ledger — drop it; local day reset owns local counters.
            group.set(today, forKey: Self.appGroupScrollDayKey)
            group.set(0, forKey: Self.appGroupScrollMinutesKey)
            return
        }
        if group.object(forKey: Self.appGroupScrollDayKey) == nil {
            group.set(today, forKey: Self.appGroupScrollDayKey)
        }

        let shared = max(0, group.integer(forKey: Self.appGroupScrollMinutesKey))
        if shared > todayScrollMinutes {
            todayScrollMinutes = shared
            defaults.set(todayScrollMinutes, forKey: scrollMinutesKey)
            objectWillChange.send()
        } else if todayScrollMinutes > shared {
            group.set(todayScrollMinutes, forKey: Self.appGroupScrollMinutesKey)
        }
    }

    /// Commit scroll from one DeviceActivity unlock session once (app + extension safe).
    /// - Parameter treatAsFullBudget: threshold auto-lock — count the full allowed budget.
    static func commitSessionScrollInAppGroup(
        spentMinutes: Int,
        allowedMinutes: Int,
        sessionStart: Date?,
        treatAsFullBudget: Bool
    ) {
        guard let group = UserDefaults(suiteName: "group.com.scrolldeeds.app") else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let stored = group.object(forKey: appGroupScrollDayKey) as? Date,
           !calendar.isDate(stored, inSameDayAs: today) {
            group.set(today, forKey: appGroupScrollDayKey)
            group.set(0, forKey: appGroupScrollMinutesKey)
        } else if group.object(forKey: appGroupScrollDayKey) == nil {
            group.set(today, forKey: appGroupScrollDayKey)
        }

        let startInterval = sessionStart?.timeIntervalSince1970 ?? 0
        let committedKey = "heartCommittedSessionStart"
        if startInterval > 0, group.double(forKey: committedKey) == startInterval {
            return
        }

        var minutes = max(0, spentMinutes)
        if treatAsFullBudget {
            minutes = max(minutes, max(0, allowedMinutes))
        }
        if minutes > 0 {
            let current = max(0, group.integer(forKey: appGroupScrollMinutesKey))
            group.set(current + minutes, forKey: appGroupScrollMinutesKey)
        }
        if startInterval > 0 {
            group.set(startInterval, forKey: committedKey)
        }
    }

    private func syncScrollMinutesToAppGroup(forceDay: Date? = nil) {
        guard let group = appGroup else { return }
        let day = forceDay ?? Calendar.current.startOfDay(for: Date())
        group.set(day, forKey: Self.appGroupScrollDayKey)
        if forceDay != nil {
            group.set(todayScrollMinutes, forKey: Self.appGroupScrollMinutesKey)
            return
        }
        let shared = max(0, group.integer(forKey: Self.appGroupScrollMinutesKey))
        group.set(max(shared, todayScrollMinutes), forKey: Self.appGroupScrollMinutesKey)
    }
    
    func completeSession(minutesEarned: Int = 15) {
        todaySessions += 1
        todayMinutes += minutesEarned
        totalSessions += 1
        totalMinutes += minutesEarned
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if daily goal is completed (5 sessions)
        if todaySessions >= dailyGoalSessions && !dailyGoalCompleted {
            // Get previous completion date before updating
            let previousCompletion = lastDayCompleted
            dailyGoalCompleted = true
            lastDayCompleted = today
            
            // Update streak based on previous completion
            if let previous = previousCompletion {
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
                
                // Check if we completed yesterday
                if calendar.isDate(previous, inSameDayAs: yesterday) {
                    // Consecutive day - increment streak
                    currentStreak += 1
                } else {
                    // Gap in days - reset streak to 1
                    currentStreak = 1
                }
            } else {
                // First time completing daily goal
                currentStreak = 1
            }
        }
        
        lastSessionDate = Date()
        
        // Update daily history
        updateDailyHistory(sessions: todaySessions, minutes: todayMinutes)
        
        // Cancel streak reminder if scheduled (user completed session today)
        NotificationManager.shared.cancelStreakReminder()
        
        // Schedule "almost daily goal" notification if close to completing (3 or 4 sessions)
        if todaySessions >= 3 && todaySessions < 5 {
            NotificationManager.shared.scheduleAlmostDailyGoalNotification(
                sessionsCompleted: todaySessions,
                sessionsRemaining: sessionsRemaining
            )
        } else if todaySessions >= 5 {
            // Goal completed - cancel any pending "almost" notifications
            NotificationManager.shared.cancelAlmostDailyGoalNotifications()
        }
        
        // Save locally
        saveData()
    }
    
    private func updateDailyHistory(sessions: Int, minutes: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we already have an entry for today
        if let index = dailyHistory.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            // Update existing entry
            dailyHistory[index].sessions = sessions
            dailyHistory[index].minutes = minutes
        } else {
            // Add new entry
            dailyHistory.append(DailyStats(date: today, sessions: sessions, minutes: minutes))
        }
        
        // Keep only last 30 days
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        dailyHistory = dailyHistory.filter { $0.date >= thirtyDaysAgo }
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(dailyHistory) {
            defaults.set(encoded, forKey: dailyHistoryKey)
        }
    }
    
    func getLast7Days() -> [DailyStats] {
        let calendar = Calendar.current
        var result: [DailyStats] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let startOfDay = calendar.startOfDay(for: date)
                if let stats = dailyHistory.first(where: { calendar.isDate($0.date, inSameDayAs: startOfDay) }) {
                    result.append(stats)
                } else {
                    result.append(DailyStats(date: startOfDay, sessions: 0, minutes: 0))
                }
            }
        }
        
        return result.reversed()
    }
    
    func resetAllData() {
        todaySessions = 0
        todayMinutes = 0
        todayScrollMinutes = 0
        totalSessions = 0
        totalMinutes = 0
        currentStreak = 0
        lastSessionDate = nil
        dailyHistory = []
        
        defaults.removeObject(forKey: sessionsKey)
        defaults.removeObject(forKey: minutesKey)
        defaults.removeObject(forKey: scrollMinutesKey)
        defaults.removeObject(forKey: totalSessionsKey)
        defaults.removeObject(forKey: totalMinutesKey)
        defaults.removeObject(forKey: streakKey)
        defaults.removeObject(forKey: lastSessionKey)
        defaults.removeObject(forKey: lastResetKey)
        defaults.removeObject(forKey: dailyHistoryKey)
        defaults.removeObject(forKey: dailyGoalCompletedKey)
        defaults.removeObject(forKey: lastDayCompletedKey)
        appGroup?.set(0, forKey: Self.appGroupScrollMinutesKey)
        appGroup?.set(Calendar.current.startOfDay(for: Date()), forKey: Self.appGroupScrollDayKey)
    }
    
    // MARK: - Daily Goal Helpers
    
    var dailyGoalProgress: Double {
        return min(1.0, Double(todaySessions) / Double(dailyGoalSessions))
    }
    
    var sessionsRemaining: Int {
        return max(0, dailyGoalSessions - todaySessions)
    }
    
    var isDailyGoalCompleted: Bool {
        return dailyGoalCompleted
    }
}

