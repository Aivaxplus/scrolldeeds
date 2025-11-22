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
    @Published var todaySessions: Int = 0
    @Published var todayMinutes: Int = 0
    @Published var totalSessions: Int = 0
    @Published var totalMinutes: Int = 0
    @Published var currentStreak: Int = 0
    @Published var lastSessionDate: Date?
    @Published var dailyHistory: [DailyStats] = []
    
    private let defaults = UserDefaults.standard
    
    // Simple local keys (no user ID needed)
    private let sessionsKey = "todaySessions"
    private let minutesKey = "todayMinutes"
    private let totalSessionsKey = "totalSessions"
    private let totalMinutesKey = "totalMinutes"
    private let streakKey = "currentStreak"
    private let lastSessionKey = "lastSessionDate"
    private let lastResetKey = "lastResetDate"
    private let dailyHistoryKey = "dailyHistory"
    
    init() {
        loadData()
    }
    
    // MARK: - Local Storage Methods
    
    private func saveData() {
        defaults.set(todaySessions, forKey: sessionsKey)
        defaults.set(todayMinutes, forKey: minutesKey)
        defaults.set(totalSessions, forKey: totalSessionsKey)
        defaults.set(totalMinutes, forKey: totalMinutesKey)
        defaults.set(currentStreak, forKey: streakKey)
        defaults.set(lastSessionDate, forKey: lastSessionKey)
        
        if let encoded = try? JSONEncoder().encode(dailyHistory) {
            defaults.set(encoded, forKey: dailyHistoryKey)
        }
    }
    
    func loadData() {
        todaySessions = defaults.integer(forKey: sessionsKey)
        todayMinutes = defaults.integer(forKey: minutesKey)
        totalSessions = defaults.integer(forKey: totalSessionsKey)
        totalMinutes = defaults.integer(forKey: totalMinutesKey)
        currentStreak = defaults.integer(forKey: streakKey)
        
        if let date = defaults.object(forKey: lastSessionKey) as? Date {
            lastSessionDate = date
        }
        
        // Load daily history
        if let data = defaults.data(forKey: dailyHistoryKey),
           let history = try? JSONDecoder().decode([DailyStats].self, from: data) {
            dailyHistory = history
        }
    }
    
    func checkDailyReset() {
        let lastReset = defaults.object(forKey: lastResetKey) as? Date ?? Date.distantPast
        let calendar = Calendar.current
        
        if !calendar.isDateInToday(lastReset) {
            // Check if yesterday had any sessions
            if todaySessions == 0 && lastSessionDate != nil {
                // User didn't do any sessions yesterday - schedule streak reminder
                NotificationManager.shared.scheduleStreakReminder()
            }
            
            // Reset daily stats
            todaySessions = 0
            todayMinutes = 0
            defaults.set(0, forKey: sessionsKey)
            defaults.set(0, forKey: minutesKey)
            defaults.set(Date(), forKey: lastResetKey)
            
            // Update streak
            if let lastSession = lastSessionDate {
                let daysSinceLastSession = calendar.dateComponents([.day], from: lastSession, to: Date()).day ?? 0
                if daysSinceLastSession > 1 {
                    // Streak broken
                    currentStreak = 0
                    defaults.set(0, forKey: streakKey)
                }
            }
        }
    }
    
    func completeSession(minutesEarned: Int = 15) {
        todaySessions += 1
        todayMinutes += minutesEarned
        totalSessions += 1
        totalMinutes += minutesEarned
        
        let calendar = Calendar.current
        if let lastSession = lastSessionDate {
            let isToday = calendar.isDateInToday(lastSession)
            if !isToday {
                currentStreak += 1
            }
        } else {
            currentStreak = 1
        }
        
        lastSessionDate = Date()
        
        // Update daily history
        updateDailyHistory(sessions: todaySessions, minutes: todayMinutes)
        
        // Cancel streak reminder if scheduled (user completed session today)
        NotificationManager.shared.cancelStreakReminder()
        
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
        totalSessions = 0
        totalMinutes = 0
        currentStreak = 0
        lastSessionDate = nil
        dailyHistory = []
        
        defaults.removeObject(forKey: sessionsKey)
        defaults.removeObject(forKey: minutesKey)
        defaults.removeObject(forKey: totalSessionsKey)
        defaults.removeObject(forKey: totalMinutesKey)
        defaults.removeObject(forKey: streakKey)
        defaults.removeObject(forKey: lastSessionKey)
        defaults.removeObject(forKey: lastResetKey)
        defaults.removeObject(forKey: dailyHistoryKey)
    }
}

