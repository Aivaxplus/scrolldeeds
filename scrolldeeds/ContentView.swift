//
//  ContentView.swift
//  scrolldeeds
//
//  Created by Sabri El makhoukhi on 30/10/2025.
//

import SwiftUI
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

struct ContentView: View {
    @StateObject private var permissions = PermissionsManager()
    @ObservedObject private var shieldManager = ShieldManager.shared
    @StateObject private var detector = RecitationDetector()
    @StateObject private var localStorage = LocalStorageManager.shared
    @StateObject private var userDataManager = UserDataManager()
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("userAppearance") private var userAppearance: Int = 0 // 0 = Dark (default), 1 = Light, 2 = System

    @State private var isRecitationPresented: Bool = false
    @State private var isUnlockActive: Bool = false
    @State private var unlockEndsAt: Date? = nil
    @State private var showOnboarding: Bool = true
    @State private var showQuestionnaire: Bool = false
    @State private var currentTime: Date = Date()
    @State private var showProgressView: Bool = false
    @State private var showSettingsView: Bool = false
    @State private var showQuickGuide: Bool = false
    @State private var showSplashScreen: Bool = true // Always shows on app launch
    @State private var showAlarm: Bool = false // Alarm view when 15 minutes expire
    
    // Timer to update the countdown every second
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if showSplashScreen {
                SplashScreenView {
                    debugPrint("✨ CONTENTVIEW: Splash screen completed, hiding it now")
                    showSplashScreen = false
                }
                .transition(.opacity)
                .onAppear {
                    debugPrint("✨ CONTENTVIEW: Splash screen is now visible")
                }
            } else if showAlarm {
                // Full-screen alarm view - user must acknowledge
                AlarmView {
                    showAlarm = false
                    // Shield is already applied by ShieldManager
                }
                .transition(.opacity)
                .zIndex(1000) // Ensure alarm is on top
            } else {
                mainContent
                    .onAppear {
                        debugPrint("✨ CONTENTVIEW: Main content is now visible")
                        // Restore unlock state and notifications when app starts
                        restoreUnlockState()
                    }
            }
        }
    }
    
    private var mainContent: some View {
        NavigationView {
            if !localStorage.hasCompletedOnboarding {
                if showOnboarding {
                    // First: Onboarding
                    OnboardingView(onNext: {
                        showOnboarding = false
                        showQuestionnaire = true
                    })
                } else if showQuestionnaire {
                    // Second: Questionnaire with app selection
                    QuestionnaireView(
                        onFinished: { 
                            localStorage.completeOnboarding()
                            // Show quick guide after brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if !localStorage.hasSeenQuickGuide {
                                    showQuickGuide = true
                                }
                            }
                        }, 
                        shieldManager: shieldManager,
                        localStorage: localStorage
                    )
                }
            } else {
                // Main dashboard
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            dashboardCard
                            readyCard
                            lockedApps
                            progressCard
                        }
                        .padding(20)
                    }
                }
                .navigationTitle("ScrollDeeds")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(AppTheme.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .sheet(isPresented: $showProgressView) {
                    NavigationView {
                        ProgressView(userDataManager: userDataManager, localStorage: localStorage)
                    }
                }
                .sheet(isPresented: $showSettingsView) {
                    NavigationView {
                        SettingsView(localStorage: localStorage)
                    }
                }
                .fullScreenCover(isPresented: $showQuickGuide) {
                    QuickGuideView(onComplete: {
                        showQuickGuide = false
                    })
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showProgressView = true }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showSettingsView = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(colorScheme(for: userAppearance))
        .onAppear {
            // Set navigation bar title color to green (for both light and dark mode)
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppTheme.background)
            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor(AppTheme.primary)
            ]
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor(AppTheme.primary)
            ]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            
            permissions.requestAllPermissions()
            notificationManager.requestAuthorization()
            userDataManager.checkDailyReset()
            
            // Restore unlock state from previous session
            restoreUnlockState()
            
            // Apply shield if apps are selected and not currently unlocked
            if !shieldManager.selectedApplications.isEmpty && !isUnlockActive {
                shieldManager.applyShield()
            }
            
            // Clear badge when app opens
            notificationManager.clearBadge()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            // Check if 15 minute unlock timer has expired
            if isUnlockActive, let end = unlockEndsAt, Date() >= end {
                // 15 minutes expired - shield should be applied
                debugPrint("⏰ 15 minutes expired - shield should be applied")
                reapplyLock()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // App going to background - ShieldManager will handle timer via background task
            // Background task will apply shield after 15 minutes
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // App came back to foreground - check if 15 minutes expired
            restoreUnlockState()
            
            // CRITICAL: Only cancel notifications if time has expired and shield is being activated
            // This ensures notifications continue until user actually opens app AND shield is activated
            if let end = unlockEndsAt, Date() >= end {
                debugPrint("⏰ 15 minutes expired - User opened app, stopping alarms and activating shield")
                isUnlockActive = false
                unlockEndsAt = nil
                clearUnlockTime()
                
                // NOW cancel notifications because shield is being activated
                notificationManager.cancelUnlockExpiryNotification()
                notificationManager.cancelRecurringTimeExpiredNotifications()
                
                showAlarm = true // Show full-screen alarm
            } else {
                // Time still valid - keep notifications running
                debugPrint("⏰ Still unlocked - notifications will continue until time expires")
            }
        }
        .sheet(isPresented: $isRecitationPresented) {
            PracticeSessionView(detector: detector) {
                // On completion: unlock apps for 15 minutes
                HapticManager.shared.appsUnlocked()
                userDataManager.completeSession(minutesEarned: 15)
                shieldManager.removeShield()
                isUnlockActive = true
                
                // Set unlock time to 15 minutes from now
                let end = Date().addingTimeInterval(15 * 60) // 15 minutes unlock time
                unlockEndsAt = end
                saveUnlockTime(end)
                shieldManager.setUnlockEndTime(end)
                
                // Cancel ALL old notifications before scheduling new ones
                notificationManager.cancelUnlockExpiryNotification()
                notificationManager.cancelRecurringTimeExpiredNotifications()
                notificationManager.cancelLockedAppReminders() // Cancel reminders since apps are now unlocked
                
                // Schedule notification for when time expires (this will also schedule recurring alarms)
                notificationManager.scheduleUnlockExpiryNotification(expiresAt: end)
                
                debugPrint("✅ Apps unlocked for 15 minutes - shield will auto-apply after timer")
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stop doomscrolling with Dhikr")
                .font(.title)
                .bold()
            Text("Lock selected apps. Unlock 15 minutes by reciting 3 times.")
                .foregroundColor(.secondary)
        }
    }

    private var dashboardCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section with gradient
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apps Currently")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textOnDark.opacity(0.85))
                    Text(isUnlockActive ? "Unlocked" : "Locked")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textOnDark)
                }
                Spacer()
                ZStack {
                    // Animated pulse effect when locked
                    if !isUnlockActive {
                        Circle()
                            .fill(AppTheme.textOnDark.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .scaleEffect(isUnlockActive ? 1.0 : 1.2)
                            .opacity(isUnlockActive ? 0 : 0.3)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isUnlockActive
                            )
                    }
                    
                    Circle()
                        .fill(AppTheme.textOnDark.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isUnlockActive ? 1.1 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isUnlockActive)
                    
                    Image(systemName: isUnlockActive ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(AppTheme.textOnDark)
                        .rotationEffect(.degrees(isUnlockActive ? 0 : -5))
                        .scaleEffect(isUnlockActive ? 1.1 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isUnlockActive)
                }
            }
            .padding(24)
            .background(AppTheme.gradientPrimary)
            
            // Bottom status section (with proper background)
            if isUnlockActive, let end = unlockEndsAt {
                let remaining = max(0, Int(end.timeIntervalSince(currentTime)))
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.accent)
                    Text("Time left: \(remaining / 60)m \(remaining % 60)s")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .monospacedDigit()
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(AppTheme.card)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("Recite dhikr to unlock your apps")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(AppTheme.card)
            }
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppTheme.primary.opacity(0.2), radius: 20, y: 10)
    }

    private var readyCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: "sparkles")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ready to Unlock?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Complete a spiritual practice to unlock your apps for 15 minutes. When the timer ends, alarms keep ringing until you relock.")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineSpacing(3)
                }
            }
            
            Button(action: {
                if !isUnlockActive {
                    HapticManager.shared.medium()
                    isRecitationPresented = true
                }
            }) {
                HStack(spacing: 10) {
                    if !isUnlockActive {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .rotationEffect(.degrees(isUnlockActive ? 0 : 15))
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                value: isUnlockActive
                            )
                    }
                    
                    Text(isUnlockActive ? "Apps Already Unlocked" : "Unlock Apps with Dhikr")
                    
                    if !isUnlockActive {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isUnlockActive)
            .opacity(isUnlockActive ? 0.6 : 1.0)
            .scaleEffect(isUnlockActive ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isUnlockActive)
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
                Text("You'll recite dhikr 3 times")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(24)
        .background(AppTheme.card)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 15, y: 8)
    }

    private var lockedApps: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with animated lock icon
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(shieldManager.isShieldActive ? AppTheme.error.opacity(0.15) : AppTheme.primary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: shieldManager.isShieldActive ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(shieldManager.isShieldActive ? AppTheme.error : AppTheme.primary)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: shieldManager.isShieldActive)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Locked Apps")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 6) {
                        Text(shieldManager.isShieldActive ? "Currently Locked" : "Currently Unlocked")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        if isUnlockActive {
                            Text("• \(timeRemaining())")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.accent)
                        }
                    }
                }
                
                Spacer()
                
                // Badge with count
                HStack(spacing: 6) {
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                    Text("\(shieldManager.selectedApplications.count)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.primary.opacity(0.12))
                .cornerRadius(14)
            }
            
            // Selection button with better styling
            SelectionView(shieldManager: shieldManager)
            
            // App list with animations
            #if canImport(FamilyControls)
            if #available(iOS 16.0, *), !shieldManager.selectedApplications.isEmpty {
                VStack(spacing: 12) {
                    // Info banner
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.primary.opacity(0.7))
                        
                        Text("App icons hidden for privacy")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.primary.opacity(0.08))
                    .cornerRadius(12)
                    
                    // App tiles in a nice list
                    let tokens = Array(shieldManager.selectedApplications)
                    ForEach(Array(tokens.enumerated()), id: \.element) { index, _ in
                        LockedAppRow(
                            index: index,
                            isLocked: shieldManager.isShieldActive
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7)
                                .delay(Double(index) * 0.05),
                            value: shieldManager.selectedApplications
                        )
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textMuted.opacity(0.5))
                    
                    Text("No apps selected yet")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text("Tap 'Change Selection' to choose apps")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
            #endif
        }
        .padding(24)
        .background(AppTheme.card)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 15, y: 8)
    }

    private var progressCard: some View {
        Button(action: { showProgressView = true }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Today's Progress")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    if userDataManager.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.accent)
                            Text("\(userDataManager.currentStreak)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.accent)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.accent.opacity(0.15))
                        .cornerRadius(12)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                }
                
                VStack(spacing: 12) {
                    // Today's stats in a cleaner layout
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.primary)
                                Text("Today")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Text("\(userDataManager.todaySessions)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("dhikr sessions")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.accent)
                                Text("Unlocked")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Text("\(userDataManager.todayMinutes)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("minutes")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                }
            }
            .padding(24)
            .background(AppTheme.card)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 15, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func stat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primary)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(AppTheme.muted)
        .cornerRadius(16)
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Permissions")
                .font(.headline)
            HStack {
                Label(permissions.hasFamilyControlsAuthorization ? "App Limits: Granted" : "App Limits: Not Granted",
                      systemImage: permissions.hasFamilyControlsAuthorization ? "checkmark.seal.fill" : "xmark.seal")
                    .foregroundColor(permissions.hasFamilyControlsAuthorization ? .green : .red)
                Spacer()
                Button("Request") { permissions.requestFamilyControlsPermission() }
            }
            HStack {
                Label(permissions.hasSpeechAuthorization ? "Speech: Granted" : "Speech: Not Granted",
                      systemImage: permissions.hasSpeechAuthorization ? "checkmark.seal.fill" : "xmark.seal")
                    .foregroundColor(permissions.hasSpeechAuthorization ? .green : .red)
                Spacer()
                Button("Request") { permissions.requestSpeechPermission() }
            }
        }
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Controls")
                .font(.headline)
            HStack(spacing: 12) {
                Button(action: shieldManager.applyShield) {
                    Text("Activate Lock")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                Button(action: { isRecitationPresented = true }) {
                    Text("Unlock with Dhikr")
                        .frame(maxWidth: .infinity)
        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!permissions.hasSpeechAuthorization)
            }
        }
    }

    private var unlockStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isUnlockActive, let end = unlockEndsAt {
                let remaining = max(0, Int(end.timeIntervalSince(currentTime)))
                Text("Unlocked time remaining: \(remaining / 60)m \(remaining % 60)s")
                    .monospacedDigit()
                    .foregroundColor(.green)
            } else {
                Text("Locked by default. Complete recitation to unlock 15 minutes.")
                    .foregroundColor(.secondary)
            }
        }
    }


    private func reapplyLock() {
        debugPrint("⏰ Time expired! Reapplying lock...")
        
        HapticManager.shared.appsLocked()
        isUnlockActive = false
        unlockEndsAt = nil
        
        // Clear saved unlock time
        clearUnlockTime()
        shieldManager.clearUnlockEndTime() // Also clear in ShieldManager
        
        // Cancel any pending notifications
        notificationManager.cancelUnlockExpiryNotification()
        notificationManager.cancelFiveMinuteWarning()
        
        // Apply shield
        shieldManager.applyShield()
        
        // Send immediate notification
        notificationManager.scheduleUnlockExpiryNotification(expiresAt: Date())
        
        // Schedule recurring alarm notifications (every 15 seconds for 30 minutes)
        notificationManager.scheduleRecurringTimeExpiredNotifications()
        
        debugPrint("✅ Lock reapplied! Shield active + recurring alarm notifications scheduled every 15s.")
    }
    
    // MARK: - Persistent Unlock State
    
    private func loadUnlockTime() -> Date? {
        if let timestamp = UserDefaults.standard.object(forKey: "unlockEndsAt") as? Double {
            return Date(timeIntervalSince1970: timestamp)
        }
        return nil
    }
    
    private func saveUnlockTime(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "unlockEndsAt")
        debugPrint("💾 Saved unlock time: \(date)")
    }
    
    private func clearUnlockTime() {
        UserDefaults.standard.removeObject(forKey: "unlockEndsAt")
        debugPrint("🗑️ Cleared unlock time")
    }
    
    private func restoreUnlockState() {
        // Restore 15 minute unlock timer if still valid
        if let savedTime = loadUnlockTime() {
            if savedTime > Date() {
                // Still within 15 minute unlock period
                isUnlockActive = true
                unlockEndsAt = savedTime
                shieldManager.setUnlockEndTime(savedTime)
                let remaining = Int(savedTime.timeIntervalSinceNow)
                let minutes = remaining / 60
                let seconds = remaining % 60
                debugPrint("✅ Restored unlock state: \(minutes)m \(seconds)s remaining")
                
                // CRITICAL: Re-schedule notifications if they don't exist yet
                // This ensures notifications continue even after app restart
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    let hasExpiryNotification = requests.contains { $0.identifier == "unlock_expired_initial" || $0.identifier.starts(with: "unlock_expired_alarm_") }
                    if !hasExpiryNotification {
                        DispatchQueue.main.async {
                            debugPrint("📅 Re-scheduling notifications for remaining unlock time (\(Int(savedTime.timeIntervalSinceNow/60))m remaining)")
                            self.notificationManager.scheduleUnlockExpiryNotification(expiresAt: savedTime)
                        }
                    } else {
                        debugPrint("✅ Unlock expiry notifications already scheduled")
                    }
                }
            } else {
                // 15 minutes expired - shield should be active
                clearUnlockTime()
                isUnlockActive = false
                shieldManager.applyShield()
                
                // Cancel notifications since shield is now active
                notificationManager.cancelUnlockExpiryNotification()
                notificationManager.cancelRecurringTimeExpiredNotifications()
                
                debugPrint("⏰ 15 minutes expired - shield applied, notifications cancelled")
            }
        } else {
            // No unlock time - shield is active by default
            isUnlockActive = false
            unlockEndsAt = nil
            
            // CRITICAL: If shield is active, ensure reminder notifications are scheduled
            // This fixes the issue where notifications stop after 45+ minutes
            if shieldManager.isShieldActive {
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    let hasReminderNotifications = requests.contains { $0.identifier.starts(with: "locked_app_reminder_") }
                    if !hasReminderNotifications {
                        DispatchQueue.main.async {
                            debugPrint("📅 Shield is active but no reminders found - re-scheduling now!")
                            self.notificationManager.scheduleLockedAppReminders()
                        }
                    } else {
                        debugPrint("✅ Reminder notifications already scheduled")
                    }
                }
            }
            
            debugPrint("✅ No unlock session - shield is active by default")
        }
    }
    
    private func timeRemaining() -> String {
        guard let end = unlockEndsAt else { return "0s" }
        let remaining = max(0, Int(end.timeIntervalSince(currentTime)))
        if remaining >= 60 {
            return "\(remaining / 60)m"
        } else {
            return "\(remaining)s"
        }
    }
    
    private func colorScheme(for index: Int) -> ColorScheme? {
        switch index {
        case 0: return .dark  // Dark mode (default)
        case 1: return .light // Light mode
        case 2: return nil    // System default
        default: return .dark
        }
    }
}

#Preview {
    ContentView()
}

