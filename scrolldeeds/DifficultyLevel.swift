//
//  DifficultyLevel.swift
//  scrolldeeds
//
//  Difficulty levels for unlock duration
//

import Foundation
import SwiftUI

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case extreme = "extreme"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .extreme: return "Extreme"
        }
    }
    
    var unlockDurationHours: Int {
        switch self {
        case .easy: return 6
        case .medium: return 3
        case .hard: return 1
        case .extreme: return 0 // 30 minutes, so 0 hours
        }
    }
    
    var unlockDurationMinutes: Int {
        switch self {
        case .easy: return 6 * 60 // 6 hours
        case .medium: return 3 * 60 // 3 hours
        case .hard: return 1 * 60 // 1 hour
        case .extreme: return 30 // 30 minutes
        }
    }
    
    var displayDuration: String {
        switch self {
        case .easy: return "6 hours"
        case .medium: return "3 hours"
        case .hard: return "1 hour"
        case .extreme: return "30 minutes"
        }
    }
    
    var description: String {
        switch self {
        case .easy:
            return "6 hours of access after each dhikr session. Perfect for starting your mindful journey."
        case .medium:
            return "3 hours of access after each dhikr session. A balanced approach to mindful screen time."
        case .hard:
            return "1 hour of access after each dhikr session. Challenge yourself to be more intentional."
        case .extreme:
            return "30 minutes of access after each dhikr session. Maximum accountability for your time."
        }
    }
    
    var encouragement: String {
        switch self {
        case .easy:
            return "Start where you are. Every step towards mindfulness is a step closer to Allah."
        case .medium:
            return "You're building discipline. Remember, the best time to take time for Allah is now."
        case .hard:
            return "You're choosing growth. Time spent in remembrance is never wasted."
        case .extreme:
            return "You're committed to change. May this journey bring you closer to Allah with every moment."
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "leaf.fill"
        case .medium: return "flame.fill"
        case .hard: return "bolt.fill"
        case .extreme: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return Color(red: 0.2, green: 0.8, blue: 0.4) // Green
        case .medium: return Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
        case .hard: return Color(red: 1.0, green: 0.3, blue: 0.3) // Red
        case .extreme: return Color(red: 0.6, green: 0.3, blue: 1.0) // Purple
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .easy:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.1, green: 0.7, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .medium:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.6, blue: 0.0), Color(red: 1.0, green: 0.4, blue: 0.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .hard:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 0.9, green: 0.2, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .extreme:
            return LinearGradient(
                colors: [Color(red: 0.6, green: 0.3, blue: 1.0), Color(red: 0.5, green: 0.2, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

