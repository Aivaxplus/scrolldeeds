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
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @AppStorage("userAppearance") private var userAppearance: Int = 0 // 0 = Dark (default), 1 = Light, 2 = System

    @State private var isRecitationPresented: Bool = false
    @State private var isUnlockActive: Bool = false
    @State private var unlockEndsAt: Date? = nil
    @State private var showOnboarding: Bool = true
    @State private var showQuestionnaire: Bool = false
    @State private var showHardPaywall: Bool = false
    @State private var currentTime: Date = Date()
    @State private var showProgressView: Bool = false
    @State private var showSettingsView: Bool = false
    @State private var showQuickGuide: Bool = false
    @State private var showSplashScreen: Bool = true // Always shows on app launch
    @State private var showAlarm: Bool = false // Alarm view when 15 minutes expire
    @State private var showFeedback: Bool = false // Feedback popup after 3 unlocks
    @State private var showCustomLock: Bool = false // Custom lock view when shield is active
    @State private var showDifficultyInfo: DifficultyLevel? = nil // Difficulty level info popup
    @State private var customLockDismissed: Bool = false // Track if user manually dismissed custom lock view
    
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
            } else if showCustomLock {
                // Custom lock view when shield is active
                CustomLockView(
                    userDataManager: userDataManager,
                    onUnlock: {
                        // On unlock: track session and update state
                        let minutesEarned = unlockDurationMinutes
                        userDataManager.completeSession(minutesEarned: minutesEarned)
                        
                        // Track analytics
                        AnalyticsManager.shared.trackSessionCompleted()
                        
                        // Send feedback to webhook
                        FeedbackService.shared.sendFeedback(sessionCount: userDataManager.totalSessions)
                        
                        // Check if feedback popup should be shown
                        let currentSessionCount = userDataManager.totalSessions
                        debugPrint("📊 Feedback check (CustomLockView): totalSessions = \(currentSessionCount)")
                        checkAndShowFeedbackPopup(sessionCount: currentSessionCount)
                        
                        isUnlockActive = true
                        let end = Date().addingTimeInterval(TimeInterval(minutesEarned * 60))
                        unlockEndsAt = end
                        saveUnlockTime(end)
                        shieldManager.setUnlockEndTime(end)
                        
                        // Cancel old notifications
                        notificationManager.cancelUnlockExpiryNotification()
                        notificationManager.cancelRecurringTimeExpiredNotifications()
                        notificationManager.cancelLockedAppReminders()
                        
                        // Schedule new notification
                        notificationManager.scheduleUnlockExpiryNotification(expiresAt: end)
                        
                        showCustomLock = false
                    },
                    onDismiss: {
                        // User tapped close button - return to home screen
                        showCustomLock = false
                        customLockDismissed = true // Mark as manually dismissed
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            } else {
                mainContent
                    .onAppear {
                        debugPrint("✨ CONTENTVIEW: Main content is now visible")
                        // Restore unlock state and notifications when app starts
                        restoreUnlockState()
                        // Cancel daily recurring notifications since user opened the app
                        notificationManager.cancelDailyRecurringNotifications()
                    }
            }
        }
    }
    
    private var mainContent: some View {
        NavigationView {
            if !localStorage.hasCompletedOnboarding {
                if showOnboarding {
                    // First: Onboarding slides
                    OnboardingView(onNext: {
                        showOnboarding = false
                        showQuestionnaire = true
                    })
                } else if showQuestionnaire {
                    // Second: Extended psychological questionnaire
                    QuestionnaireView(
                        onFinished: { 
                            // After questionnaire, show SOFT paywall (can skip)
                            showQuestionnaire = false
                            showHardPaywall = true
                        }, 
                        shieldManager: shieldManager,
                        localStorage: localStorage,
                        userDataManager: userDataManager
                    )
                } else if showHardPaywall {
                    // Third: SOFT PAYWALL - Can skip with X button
                    // Hard paywall comes later when user tries to unlock apps
                    SoftPaywallView(
                        onSubscribed: {
                            // User subscribed!
                            completeOnboardingFlow()
                        },
                        onSkip: {
                            // User skipped - still complete onboarding, they'll see hard paywall when unlocking
                            completeOnboardingFlow()
                        }
                    )
                }
            } else {
                // Main dashboard with bottom navigation bar
                VStack(spacing: 0) {
                    // Main content
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            dashboardCard
                            readyCard
                            difficultyLevelCard
                            lockedApps
                            progressCard
                        }
                        .padding(20)
                        .padding(.bottom, 20)
                    }
                    
                    // Bottom Navigation Bar - Fixed at bottom
                    customBottomNavigationBar
                }
                .background(AppTheme.background.ignoresSafeArea())
                .sheet(isPresented: $showProgressView) {
                    NavigationView {
                        ProgressView(userDataManager: userDataManager, localStorage: localStorage)
                    }
                }
                .sheet(isPresented: $showSettingsView) {
                    NavigationView {
                        SettingsView(localStorage: localStorage, userDataManager: userDataManager)
                    }
                }
        .sheet(item: $showDifficultyInfo) { level in
            DifficultyLevelInfoView(level: level) {
                showDifficultyInfo = nil
            }
        }
                .fullScreenCover(isPresented: $showQuickGuide) {
                    QuickGuideView(onComplete: {
                        showQuickGuide = false
                    })
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
            
            // Show/hide custom lock view based on shield state
            updateCustomLockView()
            
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
                
                // Cancel ALL old notifications to ensure clean state
                notificationManager.cancelUnlockExpiryNotification()
                notificationManager.cancelRecurringTimeExpiredNotifications()
                notificationManager.cancelLockedAppReminders()
                notificationManager.cancelLockedAppRemindersAfterTap()
                
                showAlarm = true // Show full-screen alarm
            } else {
                // Time still valid - keep notifications running
                debugPrint("⏰ Still unlocked - notifications will continue until time expires")
            }
        }
        .sheet(isPresented: $isRecitationPresented) {
            PracticeSessionView(detector: detector, userDataManager: userDataManager) {
                // On completion: unlock apps based on difficulty level (only if premium)
                guard subscriptionManager.isPremium else {
                    // User is not premium - unlock should not happen
                    // Paywall will be shown in PracticeSessionView
                    return
                }
                
                HapticManager.shared.appsUnlocked()
                let minutesEarned = unlockDurationMinutes
                userDataManager.completeSession(minutesEarned: minutesEarned)
                shieldManager.removeShield()
                isUnlockActive = true
                
                // Hide custom lock view
                showCustomLock = false
                customLockDismissed = false // Reset dismissed flag when unlocking
                
                // Set unlock time based on difficulty level
                let end = Date().addingTimeInterval(TimeInterval(minutesEarned * 60))
                unlockEndsAt = end
                saveUnlockTime(end)
                shieldManager.setUnlockEndTime(end)
                
                // Cancel ALL old notifications before scheduling new ones
                notificationManager.cancelUnlockExpiryNotification()
                notificationManager.cancelRecurringTimeExpiredNotifications()
                notificationManager.cancelLockedAppReminders() // Cancel reminders since apps are now unlocked
                
                // Schedule notification for when time expires (this will also schedule recurring alarms)
                notificationManager.scheduleUnlockExpiryNotification(expiresAt: end)
                
                // Track session completion for analytics
                AnalyticsManager.shared.trackSessionCompleted()
                
                // Get session count AFTER completeSession has incremented it
                let currentSessionCount = userDataManager.totalSessions
                debugPrint("📊 Session completed! Total sessions now: \(currentSessionCount)")
                
                // Send feedback to webhook (first time only, after 3 unlocks)
                FeedbackService.shared.sendFeedback(sessionCount: currentSessionCount)
                
                // Show feedback popup:
                // - First time: after 3 unlocks
                // - Then: every 7 unlocks (10, 17, 24, etc.)
                checkAndShowFeedbackPopup(sessionCount: currentSessionCount)
                
                debugPrint("✅ Apps unlocked for \(userDataManager.difficultyLevel.displayDuration) - shield will auto-apply after timer")
            }
        }
        .overlay {
            if showFeedback {
                FeedbackView(
                    isPresented: $showFeedback,
                    onRate: {
                        // Open App Store rating
                        if let url = URL(string: "https://apps.apple.com/app/id6754699333?action=write-review") {
                            UIApplication.shared.open(url)
                        }
                    },
                    onDismiss: {
                        // User dismissed - mark as dismissed for this milestone
                        UserDefaults.standard.set(true, forKey: "feedback_dismissed")
                        debugPrint("📊 Feedback dismissed by user")
                    }
                )
            }
        }
    }
    
    private var customBottomNavigationBar: some View {
        HStack(spacing: 0) {
            // Progress button (left)
            Button(action: {
                HapticManager.shared.soft()
                showProgressView = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 24, weight: showProgressView ? .semibold : .regular))
                }
                .foregroundColor(showProgressView ? AppTheme.textPrimary : AppTheme.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            
            // Home button (center)
            Button(action: {
                HapticManager.shared.soft()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .semibold))
                }
                .foregroundColor(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            
            // Settings button (right)
            Button(action: {
                HapticManager.shared.soft()
                showSettingsView = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24, weight: showSettingsView ? .semibold : .regular))
                }
                .foregroundColor(showSettingsView ? AppTheme.textPrimary : AppTheme.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
        }
        .background(
            AppTheme.card
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            Rectangle()
                .fill(AppTheme.muted.opacity(0.2))
                .frame(height: 0.5),
            alignment: .top
        )
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stop doomscrolling with Dhikr")
                .font(.title)
                .bold()
            Text("Lock selected apps. Unlock \(userDataManager.difficultyLevel.displayDuration) by reciting 3 times.")
                .foregroundColor(.secondary)
        }
    }

    private var dashboardCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section with gradient
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apps Currently")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textOnDark.opacity(0.8))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(isUnlockActive ? "Unlocked" : "Locked")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textOnDark)
                }
                Spacer()
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(AppTheme.textOnDark.opacity(0.15), lineWidth: 2)
                        .frame(width: 72, height: 72)
                    
                    // Animated pulse effect when locked
                    if !isUnlockActive {
                        Circle()
                            .fill(AppTheme.textOnDark.opacity(0.08))
                            .frame(width: 64, height: 64)
                            .scaleEffect(1.15)
                            .opacity(0.5)
                            .animation(
                                Animation.easeInOut(duration: 1.8)
                                    .repeatForever(autoreverses: true),
                                value: isUnlockActive
                            )
                    }
                    
                    Circle()
                        .fill(AppTheme.textOnDark.opacity(0.18))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: isUnlockActive ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppTheme.textOnDark)
                        .rotationEffect(.degrees(isUnlockActive ? 0 : -5))
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isUnlockActive)
                }
            }
            .padding(22)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.22, green: 0.58, blue: 0.40),
                        Color(red: 0.18, green: 0.50, blue: 0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Bottom status section
            if isUnlockActive, let end = unlockEndsAt {
                let remaining = max(0, Int(end.timeIntervalSince(currentTime)))
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Time Remaining")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(remaining / 60)m \(remaining % 60)s")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                            .monospacedDigit()
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(AppTheme.card)
            } else {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                    }
                    Text("Start dhikr to unlock")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(AppTheme.card)
            }
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: AppTheme.primary.opacity(0.15), radius: 24, y: 12)
    }

    private var readyCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 56, height: 56)
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ready to Unlock?")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Recite dhikr 3 times to unlock for \(userDataManager.difficultyLevel.displayDuration)")
                        .font(.system(size: 14))
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
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(isUnlockActive ? "Already Unlocked" : "Start Dhikr Session")
                    
                    if !isUnlockActive {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isUnlockActive)
            .opacity(isUnlockActive ? 0.6 : 1.0)
            
            // Inspirational quote
            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.accent.opacity(0.6))
                Text("Mindful moments lead to intentional choices")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                    .italic()
            }
            .padding(.top, 2)
        }
        .padding(20)
        .background(AppTheme.card)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.muted.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: 6)
    }
    
    private var difficultyLevelCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(userDataManager.difficultyLevel.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: userDataManager.difficultyLevel.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(userDataManager.difficultyLevel.color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Difficulty")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.3)
                HStack(spacing: 6) {
                    Text(userDataManager.difficultyLevel.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("•")
                        .foregroundColor(AppTheme.textMuted)
                    Text(userDataManager.difficultyLevel.displayDuration)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(userDataManager.difficultyLevel.color)
                }
            }
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.soft()
                showSettingsView = true
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.muted.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 4)
    }

    private var lockedApps: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(shieldManager.isShieldActive ? AppTheme.error.opacity(0.12) : AppTheme.primary.opacity(0.12))
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: shieldManager.isShieldActive ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(shieldManager.isShieldActive ? AppTheme.error : AppTheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Locked Apps")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(shieldManager.isShieldActive ? AppTheme.error : AppTheme.success)
                            .frame(width: 6, height: 6)
                        Text(shieldManager.isShieldActive ? "Locked" : "Unlocked")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        if isUnlockActive {
                            Text("• \(timeRemaining())")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.accent)
                        }
                    }
                }
                
                Spacer()
                
                // Badge with count
                Text("\(shieldManager.selectedApplications.count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary.opacity(0.1))
                    .cornerRadius(10)
            }
            
            // Selection button
            SelectionView(shieldManager: shieldManager)
            
            // App list
            #if canImport(FamilyControls)
            if #available(iOS 16.0, *), !shieldManager.selectedApplications.isEmpty {
                VStack(spacing: 10) {
                    // Info banner
                    HStack(spacing: 8) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textMuted)
                        
                        Text("App icons hidden for privacy")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.muted.opacity(0.5))
                    .cornerRadius(10)
                    
                    // App tiles
                    let tokens = Array(shieldManager.selectedApplications)
                    ForEach(Array(tokens.enumerated()), id: \.element) { index, _ in
                        LockedAppRow(
                            index: index,
                            isLocked: shieldManager.isShieldActive
                        )
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 36))
                        .foregroundColor(AppTheme.textMuted.opacity(0.4))
                    
                    Text("No apps selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            }
            #endif
        }
        .padding(20)
        .background(AppTheme.card)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.muted.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: 6)
    }

    private var progressCard: some View {
        Button(action: { showProgressView = true }) {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack {
                    Text("Today's Progress")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    if userDataManager.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.accent)
                            Text("\(userDataManager.currentStreak)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.accent)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppTheme.accent.opacity(0.12))
                        .cornerRadius(8)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                }
                
                // Stats Row
                HStack(spacing: 16) {
                    // Sessions stat
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: "hands.sparkles.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.primary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(userDataManager.todaySessions)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("sessions")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                    
                    Spacer()
                    
                    // Divider
                    Rectangle()
                        .fill(AppTheme.muted.opacity(0.3))
                        .frame(width: 1, height: 36)
                    
                    Spacer()
                    
                    // Minutes stat
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: "clock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.accent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(userDataManager.todayMinutes)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("minutes")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                }
            }
            .padding(18)
            .background(AppTheme.card)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppTheme.muted.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, y: 5)
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
                Text("Locked by default. Complete recitation to unlock \(userDataManager.difficultyLevel.displayDuration).")
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
        
        // Show custom lock view (only if not manually dismissed)
        if !customLockDismissed {
            showCustomLock = true
        }
        
        // Cancel ALL old notifications first to avoid duplicates
        notificationManager.cancelUnlockExpiryNotification()
        notificationManager.cancelRecurringTimeExpiredNotifications()
        notificationManager.cancelLockedAppReminders()
        notificationManager.cancelLockedAppRemindersAfterTap()
        
        // Schedule clean, consistent locked app reminders
        notificationManager.scheduleLockedAppReminders()
        
        debugPrint("✅ Lock reapplied! Shield active + clean reminder notifications scheduled.")
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
            
            // CRITICAL: If shield is active, ensure clean reminder notifications are scheduled
            // Cancel all old notifications first to avoid duplicates
            if shieldManager.isShieldActive {
                // Cancel all old notifications to ensure clean state
                notificationManager.cancelUnlockExpiryNotification()
                notificationManager.cancelRecurringTimeExpiredNotifications()
                notificationManager.cancelLockedAppReminders()
                notificationManager.cancelLockedAppRemindersAfterTap()
                
                // Schedule fresh, clean reminders
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    debugPrint("📅 Shield is active - scheduling clean reminder notifications")
                    self.notificationManager.scheduleLockedAppReminders()
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
    
    // Update custom lock view visibility
    private func updateCustomLockView() {
        // Don't show custom lock if user manually dismissed it
        if customLockDismissed {
            showCustomLock = false
            return
        }
        
        if shieldManager.isShieldActive && !isUnlockActive {
            showCustomLock = true
        } else {
            showCustomLock = false
            // Reset dismissed flag when shield is removed or unlock is active
            customLockDismissed = false
        }
    }
    
    // Get unlock duration based on difficulty level
    private var unlockDurationMinutes: Int {
        return userDataManager.difficultyLevel.unlockDurationMinutes
    }
    
    private var unlockDurationHours: Int {
        return userDataManager.difficultyLevel.unlockDurationHours
    }
    
    // Complete onboarding flow helper
    private func completeOnboardingFlow() {
        localStorage.completeOnboarding()
        showHardPaywall = false
        
        // Show quick guide after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !localStorage.hasSeenQuickGuide {
                showQuickGuide = true
            }
        }
    }
    
    // Check and show feedback popup if needed
    private func checkAndShowFeedbackPopup(sessionCount: Int) {
        debugPrint("📊 checkAndShowFeedbackPopup: sessionCount = \(sessionCount)")
        
        // First time: after 3 unlocks (only if not dismissed)
        if sessionCount == 3 {
            let isDismissed = UserDefaults.standard.bool(forKey: "feedback_dismissed")
            debugPrint("📊 Session 3: dismissed = \(isDismissed)")
            if !isDismissed {
                debugPrint("📊 ✅ Showing feedback popup for session 3")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.showFeedback = true
                }
                return
            } else {
                debugPrint("📊 ❌ Feedback already dismissed for session 3")
                return
            }
        }
        
        // After that: every 7 unlocks (10, 17, 24, 31, etc.)
        // Check if session count is a milestone: 3, 10, 17, 24, 31, 38, etc.
        // Formula: 3 + (n * 7) where n >= 1
        if sessionCount > 3 {
            let remainder = (sessionCount - 3) % 7
            debugPrint("📊 Session \(sessionCount): remainder = \(remainder)")
            if remainder == 0 {
                // Check if we've already shown feedback for this exact milestone
                let lastShownCount = UserDefaults.standard.integer(forKey: "feedback_last_shown_count")
                debugPrint("📊 Last shown count: \(lastShownCount), current: \(sessionCount)")
                if sessionCount > lastShownCount {
                    // Reset dismissed flag for new milestone
                    UserDefaults.standard.set(false, forKey: "feedback_dismissed")
                    UserDefaults.standard.set(sessionCount, forKey: "feedback_last_shown_count")
                    debugPrint("📊 ✅ Showing feedback popup for milestone \(sessionCount)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.showFeedback = true
                    }
                    return
                } else {
                    debugPrint("📊 ❌ Feedback already shown for milestone \(sessionCount)")
                }
            }
        }
        
        debugPrint("📊 ❌ Not showing feedback (not a milestone or already shown)")
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

