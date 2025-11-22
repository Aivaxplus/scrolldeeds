//
//  HapticManager.swift
//  scrolldeeds
//
//  Manages haptic feedback throughout the app
//

import UIKit
import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Haptic Feedback Types
    
    /// Subtle success feedback - for completing dhikr, unlocking apps
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning feedback - for 5 minute warning, approaching limit
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error feedback - for failed verification, errors
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Light tap - for button presses, selections (upgraded to medium for better feel)
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Medium tap - for important buttons, toggles (upgraded to heavy for better feel)
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Heavy tap - for critical actions, unlocking
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Soft feedback - for subtle interactions (upgraded to light for better feel)
    func soft() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Rigid feedback - for locked/blocked actions
    func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    /// Selection changed - for picker changes, tab switches
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - App-Specific Haptics
    
    /// When user starts recording dhikr (upgraded to heavy for stronger feedback)
    func recordingStarted() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// When user stops recording dhikr (upgraded to medium for stronger feedback)
    func recordingStopped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// When dhikr is verified successfully (enhanced with stronger second tap)
    func dhikrVerified() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Add a second stronger tap for extra satisfaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    /// When apps are unlocked (enhanced triple tap celebration)
    func appsUnlocked() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Triple tap for celebration with stronger feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    /// When apps are locked
    func appsLocked() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    /// When user completes onboarding (enhanced with medium tap)
    func onboardingComplete() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.medium()
        }
    }
    
    /// When user navigates to next onboarding step (upgraded)
    func onboardingNext() {
        light()
    }
    
    /// When user goes back in onboarding (upgraded)
    func onboardingBack() {
        light()
    }
    
    /// When user changes appearance mode (upgraded)
    func appearanceChanged() {
        medium()
    }
    
    /// When user adds a reminder (upgraded)
    func reminderAdded() {
        heavy()
    }
    
    /// When user deletes a reminder (kept strong)
    func reminderDeleted() {
        rigid()
    }
}

// MARK: - SwiftUI View Extension for Easy Access

extension View {
    func haptic(_ style: HapticStyle) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticManager.shared.trigger(style)
            }
        )
    }
}

enum HapticStyle {
    case light, medium, heavy, soft, rigid
    case success, warning, error
    case selection
}

extension HapticManager {
    func trigger(_ style: HapticStyle) {
        switch style {
        case .light: light()
        case .medium: medium()
        case .heavy: heavy()
        case .soft: soft()
        case .rigid: rigid()
        case .success: success()
        case .warning: warning()
        case .error: error()
        case .selection: selection()
        }
    }
}

