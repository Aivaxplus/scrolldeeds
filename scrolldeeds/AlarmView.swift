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
            // Red alarm background with pulsing effect
            Color.red
                .ignoresSafeArea()
                .opacity(pulseScale > 1.0 ? 0.9 : 1.0)
            
            VStack(spacing: 30) {
                // Alarm icon with animation
                Image(systemName: "bell.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(pulseScale)
                
                // Title
                Text("⏰ TIME'S UP! 🔒")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Message
                Text("Your 15 minutes are over.\nYour apps are now locked.")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Dismiss button
                Button(action: {
                    stopAlarm()
                    onDismiss()
                }) {
                    Text("OK, I Understand")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
        }
        .onAppear {
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

