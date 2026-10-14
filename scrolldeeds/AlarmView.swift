//
//  AlarmView.swift
//  scrolldeeds
//
//  Full-screen alarm that appears when 15 minutes expire
//  User must stay in this view until they acknowledge
//

import SwiftUI
import AudioToolbox

struct AlarmView: View {
    let onDismiss: () -> Void
    
    @State private var isAnimating = true
    @State private var pulseScale: CGFloat = 1.0
    @State private var alarmTimer: Timer?
    
    var body: some View {
        ZStack {
            SDPageBackground()
            AppTheme.error.opacity(pulseScale > 1.0 ? 0.10 : 0.06)
                .ignoresSafeArea()
            
            SDOverlayCard(maxWidth: 360) {
                VStack(spacing: 26) {
                // Alarm icon with animation
                SDIconBadge(systemName: "bell.fill", size: 92, iconSize: 40, color: AppTheme.error)
                        .scaleEffect(pulseScale)
                
                // Title
                Text(NSLocalizedString("alarm.title", comment: "⏰ TIME'S UP! 🔒"))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.8)
                
                // Message
                VStack {
                    Text(NSLocalizedString("alarm.message", comment: "Your time is over.\nYour apps are now locked."))
                            .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.9)
                }
                
                // Dismiss button
                Button(action: {
                    stopAlarm()
                    onDismiss()
                }) {
                    Text(NSLocalizedString("alarm.understand", comment: "OK, I Understand"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(ActionCardButtonStyle())
                .padding(.top, 20)
                }
            }
        }
        .onAppear {
            PostHogManager.shared.screen(AnalyticsScreen.alarm)
            startAlarm()
        }
        .onDisappear {
            stopAlarm()
        }
    }
    
    private func startAlarm() {
        isAnimating = true
        // Start pulsing animation
        withAnimation(
            Animation.easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.3
        }
        
        // Play alarm sound immediately
        playAlarmSound()
        
        // Schedule alarm to play every 2 seconds
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if isAnimating {
                playAlarmSound()
            }
        }
    }
    
    private func playAlarmSound() {
        // Use system alarm sound (1005 is a loud alarm sound)
        AudioServicesPlaySystemSound(1005)
        // Also vibrate
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    private func stopAlarm() {
        isAnimating = false
        alarmTimer?.invalidate()
        alarmTimer = nil
        withAnimation {
            pulseScale = 1.0
        }
    }
}

