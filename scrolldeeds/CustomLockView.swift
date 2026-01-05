//
//  CustomLockView.swift
//
//  Premium custom lock view in ScrollDeeds app style
//

import SwiftUI

struct CustomLockView: View {
    @ObservedObject private var shieldManager = ShieldManager.shared
    @ObservedObject var userDataManager: UserDataManager
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showDhikr = false
    @State private var pulseAnimation = false
    var onUnlock: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Rich gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.42, blue: 0.28),
                    Color(red: 0.10, green: 0.32, blue: 0.22),
                    Color(red: 0.08, green: 0.24, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle pattern
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.5
                        )
                    )
                    .frame(width: geo.size.width, height: geo.size.width)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.shared.soft()
                        onDismiss?()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Lock Icon with Premium Animation
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.white.opacity(0.08 - Double(i) * 0.02), lineWidth: 1.5)
                            .frame(width: CGFloat(100 + i * 30), height: CGFloat(100 + i * 30))
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                                value: pulseAnimation
                            )
                    }
                    
                    // Inner glow
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .blur(radius: 10)
                    
                    // Main icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    
                    // Lock icon
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(height: 180)
                .padding(.bottom, 20)
                
                // Title and Message
                VStack(spacing: 14) {
                    Text("Apps Locked")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Complete 3 dhikr recitations to\nunlock for \(userDataManager.difficultyLevel.displayDuration)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.bottom, 36)
                
                // Action Button
                Button(action: {
                    HapticManager.shared.medium()
                    showDhikr = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Start Dhikr")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(Color(red: 0.14, green: 0.42, blue: 0.28))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.white, Color(red: 0.95, green: 0.97, blue: 0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.2), radius: 16, y: 8)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Footer info
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        InfoBadge(icon: "sparkles", text: "3 recitations")
                        InfoBadge(icon: "clock", text: userDataManager.difficultyLevel.displayDuration)
                    }
                    
                    Text("Mindful moments lead to intentional choices")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .italic()
                }
                .padding(.bottom, 44)
            }
        }
        .onAppear {
            pulseAnimation = true
        }
        .sheet(isPresented: $showDhikr) {
            PracticeSessionView(detector: RecitationDetector(), userDataManager: userDataManager) {
                // On completion: unlock apps (only if premium)
                guard subscriptionManager.isPremium else {
                    // User is not premium - unlock should not happen
                    return
                }
                
                HapticManager.shared.appsUnlocked()
                shieldManager.removeShield()
                
                // Set unlock time based on difficulty level
                let minutes = userDataManager.difficultyLevel.unlockDurationMinutes
                let end = Date().addingTimeInterval(TimeInterval(minutes * 60))
                shieldManager.setUnlockEndTime(end)
                
                // Cancel old notifications
                notificationManager.cancelUnlockExpiryNotification()
                notificationManager.cancelRecurringTimeExpiredNotifications()
                notificationManager.cancelLockedAppReminders()
                
                // Schedule new notification
                notificationManager.scheduleUnlockExpiryNotification(expiresAt: end)
                
                // Track analytics
                AnalyticsManager.shared.trackSessionCompleted()
                
                // Close dhikr view
                showDhikr = false
                
                // Call unlock callback to update ContentView
                onUnlock?()
            }
        }
    }
}

// MARK: - Info Badge
struct InfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white.opacity(0.7))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

#Preview {
    CustomLockView(userDataManager: UserDataManager(), onUnlock: nil, onDismiss: nil)
}
