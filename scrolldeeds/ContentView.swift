//
//  ContentView.swift
//  scrolldeeds
//
//  Created by Sabri El makhoukhi on 30/10/2025.
//

import SwiftUI
import UIKit
import Combine
import UserNotifications
#if canImport(DeviceActivity)
import DeviceActivity
#endif

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
    @ObservedObject private var languageManager = LanguageManager.shared
    @StateObject private var detector = RecitationDetector()
    @StateObject private var localStorage = LocalStorageManager.shared
    @ObservedObject private var heartJourney = HeartJourneyManager.shared
    @ObservedObject private var nafsiLives = NafsiLivesManager.shared
    @ObservedObject private var nafsiLocker = NafsiLocker.shared
    @ObservedObject private var fajrAlarm = FajrAlarmManager.shared
    @ObservedObject private var userDataManager = UserDataManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var isRecitationPresented: Bool = false
    @State private var isUnlockActive: Bool = false
    @State private var unlockEndsAt: Date? = nil
    /// Budget (in minutes) earned in the current unlock session — used for display only.
    @State private var unlockBudgetMinutes: Int = 0
    @State private var showOnboarding: Bool = true
    @State private var showQuestionnaire: Bool = false
    @State private var showCommitment: Bool = false
    @State private var showReferralCodeEntry: Bool = false
    @State private var showLifeChange: Bool = false
    @State private var showFirstWin: Bool = false
    @State private var showHardPaywall: Bool = false
    /// Dashboard / lock-screen upgrade. Separate from onboarding `showHardPaywall` so SwiftUI
    /// actually presents a cover (the funnel paywall is not in the tree after onboarding).
    @State private var showUpgradePaywall: Bool = false
    /// Auto-present the lapsed-access paywall once per foreground, never on every state change.
    @State private var autoPresentedUpgradeThisSession: Bool = false
    @State private var currentTime: Date = Date()
    @State private var showSettingsView: Bool = false
    @State private var showSplashScreen: Bool = true // Always shows on app launch
    @State private var showAlarm: Bool = false // Alarm view when 15 minutes expire
    @State private var showFeedback: Bool = false // Feedback popup after 3 unlocks
    @State private var showCustomLock: Bool = false // Custom lock view when shield is active
    @State private var customLockDismissed: Bool = false // Track if user manually dismissed custom lock view
    /// Lock-screen unlock remounts the dashboard at 100%. Play the 0→100 fill once.
    @State private var playHeartUnlockFill = false
    @State private var showForceAppSelection: Bool = false // Force premium users to select apps
    @State private var showQuickGuide: Bool = false // Show quick "How It Works" guide for new premium users
    @State private var showDashboardTutorial: Bool = false
    @State private var tutorialScrollID: String? = nil
    @State private var showInAppFeedback: Bool = false
    @State private var selectedMainTab: MainTab = .deed
    @State private var showFajrSettings: Bool = false
    @State private var showHomeWidgets: Bool = false
    @State private var showLockWidgets: Bool = false
    @State private var showQuranReminders: Bool = false
    @State private var showSavedCards: Bool = false
    @State private var showLockedAppsTool: Bool = false
    @State private var showBuyHearts: Bool = false
    /// Set when a heart purchase should leave the lock page for the dashboard.
    @State private var heartPurchaseDismissesLock: Bool = false
    @State private var showShop: Bool = false
    /// Deed reward currently flying toward the header coins pill.
    @State private var flyingCoins: Int?
    @State private var coinFlightArmed = false
    /// Live frame of the header coins pill, so the welcome chip can land in it.
    @State private var coinsPillFrame: CGRect = .zero
    /// Scroll sits left of Home, so the incoming page travels from that side.
    @State private var mainTabFromLeft = false

    private enum MainTab {
        case feed
        case deed
    }
    
    /// Conversion nudges (re-engagement series, leave-app winback) should still run for users on the **local** 3-day trial.
    /// `hasPremiumAccess` includes that trial and was incorrectly blocking all leave-app / paywall-abandon scheduling.
    private var isEligibleForConversionNotifications: Bool {
        if !localStorage.hasCompletedOnboarding { return true }
        return !subscriptionManager.isPremium && !ReferralManager.shared.hasInfluencerAccess
    }
    
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
            } else if fajrAlarm.isRinging {
                FajrAlarmRingingView()
                    .transition(.opacity)
                    .zIndex(1100)
            } else if showAlarm {
                // Full-screen alarm view - user must acknowledge
                AlarmView {
                    showAlarm = false
                    // Shield is already applied by ShieldManager
                }
                .transition(.opacity)
                .zIndex(1000) // Ensure alarm is on top
            } else if showUpgradePaywall {
                upgradePaywall
                    .transition(.opacity)
                    .zIndex(2000)
            } else {
                // Keep the dashboard mounted under the lock. Replacing it used to
                // rebuild NavigationView, and every sheet (shop, hearts, tools) then
                // stopped presenting. Earn coins survived because it is a cover on this ZStack.
                ZStack {
                    mainContent
                        .onAppear {
                            debugPrint("✨ CONTENTVIEW: Main content is now visible")
                            PostHogManager.shared.screen(AnalyticsScreen.home)
                            restoreUnlockState()
                            notificationManager.cancelDailyRecurringNotifications()

                            if isEligibleForConversionNotifications
                                && localStorage.hasCompletedOnboarding
                                && !shieldManager.hasActiveUnlockSession() {
                                notificationManager.ensureReengagementScheduled(includeImmediateKickoff: false)
                            }

                            refreshAccessAndPresentPaywallIfLapsed()
                            fajrAlarm.checkIfShouldRingOnForeground()
                            NafsiWidgetSettings.shared.publish()
                            enforcePremiumFeatureAccess()
                        }
                    if showCustomLock {
                        CustomLockView(
                            onUnlock: {
                                rewardCoinsForDeed()

                                AnalyticsManager.shared.trackSessionCompleted()
                                PostHogManager.shared.trackDeedSessionCompleted(
                                    minutesEarned: 0,
                                    totalSessions: userDataManager.totalSessions
                                )

                                FeedbackService.shared.sendFeedback(sessionCount: userDataManager.totalSessions)

                                let currentSessionCount = userDataManager.totalSessions
                                debugPrint("📊 Feedback check (CustomLockView): totalSessions = \(currentSessionCount)")
                                checkAndShowFeedbackPopup(sessionCount: currentSessionCount)
                            },
                            onDismiss: {
                                showCustomLock = false
                                customLockDismissed = true
                                maybePlayHeartWelcome()
                            },
                            onRequiresUpgrade: {
                                debugPrint("🚫 Lock screen unlock blocked - no active trial/subscription, showing paywall")
                                presentPostTrialPaywall()
                            },
                            onBuyHearts: {
                                showBuyHearts = true
                            }
                        )
                        .transition(.opacity)
                        .zIndex(999)
                    }
                }
            }
        }
        .sheet(isPresented: $showBuyHearts, onDismiss: {
            heartJourney.presentQueuedSpends()
            // Purchase already removed the lock under this sheet.
            // Closing it must show the dashboard, not the lock page.
            guard heartPurchaseDismissesLock else { return }
            heartPurchaseDismissesLock = false
            showCustomLock = false
            customLockDismissed = true
            showDashboardTab()
        }) {
            BuyHeartsSheet {
                isUnlockActive = shieldManager.hasActiveUnlockSession()
                if isUnlockActive {
                    unlockBudgetMinutes = nafsiLives.minutesRemaining
                }
                if showCustomLock && nafsiLives.hearts > 0 {
                    heartPurchaseDismissesLock = true
                    showCustomLock = false
                    customLockDismissed = true
                    showDashboardTab()
                }
                updateCustomLockView()
            }
        }
        .fullScreenCover(isPresented: $isRecitationPresented) {
            PracticeSessionView(detector: detector) {
                rewardCoinsForDeed()

                AnalyticsManager.shared.trackSessionCompleted()
                let currentSessionCount = userDataManager.totalSessions
                PostHogManager.shared.trackDeedSessionCompleted(
                    minutesEarned: 0,
                    totalSessions: currentSessionCount
                )

                debugPrint("📊 Session completed! Total sessions now: \(currentSessionCount)")
                FeedbackService.shared.sendFeedback(sessionCount: currentSessionCount)
                checkAndShowFeedbackPopup(sessionCount: currentSessionCount)
                debugPrint("✅ Deed rewarded with coins — hearts stay until the user buys them")
            }
        }
        .fullScreenCover(isPresented: $showQuickGuide) {
            QuickGuideView {
                debugPrint("🎯 QuickGuide dismissed - marking as seen")
                LocalStorageManager.shared.hasSeenQuickGuide = true
                showQuickGuide = false
                showDashboardTab()
                // After How-it-works, start live dashboard coach marks once home is visible.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    maybeStartDashboardTutorial()
                }
            }
            .onAppear {
                debugPrint("🎯 ✅ QUICKGUIDE APPEARED SUCCESSFULLY!")
            }
        }
        .fullScreenCover(isPresented: $showReferralCodeEntry) {
            ReferralCodeOnboardingView(
                initialCode: localStorage.referralCode,
                onContinue: { code in
                    showReferralCodeEntry = false
                    showLifeChange = false
                    if ReferralManager.shared.hasInfluencerAccess {
                        // Influencer: skip paywall and grant free access.
                        LocalStorageManager.shared.referralCode = ""
                        showReferralCodeEntry = false
                        // Don't show QuickGuide for influencer users.
                        LocalStorageManager.shared.hasSeenQuickGuide = true
                        showQuickGuide = false
                        
                        // Grant onboarding completion and skip paywall.
                        completeOnboardingFlow()
                        
                        // Go directly to app chooser.
                        showForceAppSelection = true
                        
                        // Stop any paywall-related re-engagement nudges.
                        notificationManager.cancelReengagementNotifications()
                        notificationManager.cancelWelcomeNotifications()
                        notificationManager.cancelPaywallLeaveConversionNudge()
                        return
                    }
                    
                    LocalStorageManager.shared.referralCode = code ?? ""
                    showReferralCodeEntry = false
                    showLifeChange = false
                    advanceAfterCommitment()
                },
                onSkip: {
                    LocalStorageManager.shared.referralCode = ""
                    ReferralManager.shared.clearAll()
                    showReferralCodeEntry = false
                    showLifeChange = false
                    advanceAfterCommitment()
                }
            )
        }
    }
    
    private var onboardingPhaseToken: String {
        if showOnboarding { return "welcome" }
        if showQuestionnaire { return "questionnaire" }
        if showCommitment { return "commitment" }
        if showLifeChange { return "lifeChange" }
        if showFirstWin { return "firstWin" }
        if showHardPaywall { return "paywall" }
        return "none"
    }

    private var mainContent: some View {
        NavigationView {
            if !localStorage.hasCompletedOnboarding {
                ZStack {
                    SDPageBackground()

                    if showOnboarding {
                        OnboardingView(onNext: {
                            // Benefits is now the first questionnaire step (same prayer-lock chrome).
                            withAnimation(AppMotion.funnelHandoff) {
                                showOnboarding = false
                                showQuestionnaire = true
                            }
                        })
                        .transition(.funnelHandoffOut)
                        .zIndex(1)
                    }
                    if showQuestionnaire {
                        QuestionnaireView(
                            onFinished: {
                                debugPrint("🔄 Questionnaire finished, advancing funnel...")
                                let advance = {
                                    withAnimation(AppMotion.funnelHandoff) {
                                        showQuestionnaire = false
                                        if OnboardingFunnelConfig.useConversionPaywall {
                                            showHardPaywall = true
                                        } else if OnboardingFunnelConfig.hideCommitmentBeforePaywall {
                                            showLifeChange = true
                                        } else {
                                            showCommitment = true
                                        }
                                    }
                                }
                                if Thread.isMainThread {
                                    advance()
                                } else {
                                    DispatchQueue.main.async { advance() }
                                }
                            },
                            shieldManager: shieldManager,
                            localStorage: localStorage,
                            userDataManager: userDataManager
                        )
                        .transition(.funnelHandoffOut)
                        .zIndex(2)
                    }
                    if showCommitment {
                        CommitmentView(
                            userName: userDataManager.userName,
                            onComplete: {
                                withAnimation(AppMotion.funnelHandoff) {
                                    showCommitment = false
                                    showLifeChange = true
                                }
                            }
                        )
                        .transition(.funnelHandoffOut)
                        .zIndex(3)
                    }
                    if showLifeChange {
                        OnboardingLifeChangeView(userName: userDataManager.userName) {
                            if OnboardingFunnelConfig.hideReferralCodeScreen {
                                transitionFromLifeChangeToNextStep()
                            } else {
                                showReferralCodeEntry = true
                            }
                        }
                        .transition(.funnelHandoffOut)
                        .zIndex(4)
                    }
                    if showFirstWin {
                        OnboardingFirstWinView(userName: userDataManager.userName) {
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboardingFirstDeed")
                            withAnimation(AppMotion.funnelHandoff) {
                                showFirstWin = false
                            }
                            performSafeTransition()
                        }
                        .transition(.funnelHandoffOut)
                        .zIndex(5)
                    }
                    if showHardPaywall {
                        Group {
                            if OnboardingFunnelConfig.useConversionPaywall {
                                ConversionPaywallView(
                                    onSubscribed: {
                                        handlePaywallSubscribed()
                                    }
                                )
                            } else {
                                HardPaywallView(
                                    onSubscribed: {
                                        handlePaywallSubscribed()
                                    }
                                )
                            }
                        }
                        .transition(.funnelHandoffIn)
                        .zIndex(6)
                    }
                }
                .animation(AppMotion.funnelHandoff, value: onboardingPhaseToken)
            } else {
                    // Main dashboard with bottom navigation bar
                    ZStack {
                        if selectedMainTab == .feed {
                            ScrollSceneBackdrop()
                                .transition(.opacity)
                        }
                        VStack(spacing: 0) {
                            ZStack {
                                switch selectedMainTab {
                                case .feed:
                                    KnowledgeFeedView()
                                        .ignoresSafeArea(edges: .top)
                                        .padding(.bottom, -22)
                                        .transition(mainTabTransition)
                                case .deed:
                                    deedHome
                                        .transition(mainTabTransition)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                            customBottomNavigationBar
                                .zIndex(1)
                        }
                        .background {
                            if selectedMainTab != .feed {
                                AppTheme.background
                                    .ignoresSafeArea()
                            }
                        }
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarHidden(true)
                    }
                    .overlayPreferenceValue(TutorialAnchorPreferenceKey.self) { anchors in
                        Group {
                            if showDashboardTutorial {
                                DashboardTutorialOverlay(
                                    anchors: anchors,
                                    onSkip: { finishDashboardTutorial() },
                                    onFinish: { finishDashboardTutorial() },
                                    onStepChange: { step in
                                        applyTutorialStep(step)
                                    }
                                )
                                .transition(.opacity)
                            }
                        }
                    }
                    .overlayPreferenceValue(HeartXPBarFrameKey.self) { _ in
                        Group {
                            if heartJourney.isPlayingWelcome {
                                HeartWelcomeOverlay(barGlobalFrame: coinsPillFrame)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .onPreferenceChange(CoinsPillFrameKey.self) { coinsPillFrame = $0 }
                    .overlayPreferenceValue(CoinsPillFrameKey.self) { pillFrame in
                        Group {
                            if let flyingCoins {
                                CoinFlightOverlay(amount: flyingCoins, target: pillFrame) {
                                    let gained = heartJourney.claimPendingDeedCoins()
                                    if gained > 0 {
                                        HapticManager.shared.coinsLanded()
                                    }
                                    self.flyingCoins = nil
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .ignoresSafeArea()
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: showDashboardTutorial)
                    .animation(.easeInOut(duration: 0.25), value: heartJourney.isPlayingWelcome)
                    .onAppear {
                        if selectedMainTab == .deed {
                            maybePlayHeartWelcome()
                        }
                        beginCoinFlightIfNeeded()
                    }
                    .onChange(of: selectedMainTab) { tab in
                        if tab == .deed {
                            maybePlayHeartWelcome()
                        }
                    }
                    .sheet(isPresented: $showSettingsView) {
                        NavigationView {
                            SettingsView(localStorage: localStorage)
                        }
                    }
                    .sheet(isPresented: $showFajrSettings) {
                        FajrAlarmSettingsView()
                    }
                    .sheet(isPresented: $showHomeWidgets) {
                        WidgetSettingsPage(surface: .home)
                    }
                    .sheet(isPresented: $showLockWidgets) {
                        WidgetSettingsPage(surface: .lock)
                    }
                    .sheet(isPresented: $showQuranReminders) {
                        QuranReminderSettingsPage()
                    }
                    .sheet(isPresented: $showSavedCards) {
                        SavedDiscoveryView()
                    }
                    .sheet(isPresented: $showLockedAppsTool) {
                        LockedAppsToolPage(shieldManager: shieldManager)
                    }
                    .sheet(isPresented: $showShop, onDismiss: {
                        heartJourney.presentQueuedSpends()
                    }) {
                        NafsiShopView()
                    }
                    .sheet(isPresented: $showInAppFeedback) {
                        InAppFeedbackSheet(source: .dashboard, isPresented: $showInAppFeedback)
                    }
                    .fullScreenCover(isPresented: $showForceAppSelection) {
                        ForceAppSelectionView(
                            shieldManager: shieldManager,
                            onComplete: {
                                debugPrint("🎯 APP SELECTION COMPLETED - User can now start dhikr")
                                showForceAppSelection = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    if !isUnlockActive {
                                        isRecitationPresented = true
                                    }
                                }
                            }
                        )
                    }
            }
        }
        .background(
            // Prevent black flickering by ensuring background covers all edges
            AppTheme.background
                .ignoresSafeArea(.all, edges: .all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        .preferredColorScheme(AppearanceManager.shared.preferredColorScheme)
        .onAppear {
            // Set navigation bar title color to green (for both light and dark mode)
            let appearance = UINavigationBarAppearance()
            // Make navigation bar transparent to prevent black flickering
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor.clear
            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor(AppTheme.primary)
            ]
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor(AppTheme.primary)
            ]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            
            // Don't request permissions here - only at app selection step
            userDataManager.checkDailyReset()
            userDataManager.mergeScrollMinutesFromAppGroup()

            if subscriptionManager.hasTrialExpired && !subscriptionManager.isPremium {
                UserDefaults.standard.set(false, forKey: "hasTrialAccess")
            }
            
            // Restore and reconcile lock state from previous session
            syncLockUI()
            
            // Clear badge when app opens
            notificationManager.clearBadge()
            
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            nafsiLives.reloadFromDefaults()
            nafsiLives.refreshFromUsage(isUnlocked: isUnlockActive)
            if isUnlockActive && nafsiLives.hearts <= 0 && nafsiLives.usageHasEmptiedHearts && !shieldManager.isInUnlockGracePeriod() {
                debugPrint("💔 ContentView: Hearts empty — reapplying lock")
                reapplyLock()
                return
            }
            if #available(iOS 16.0, *) {
                DeviceActivityManager.shared.restartMonitoringIfNeeded()
            }
            // Only re-lock when persisted session truly ended — not during grace or brief sync lag
            if isUnlockActive && !shieldManager.hasActiveUnlockSession() {
                debugPrint("🔒 ContentView: Unlock session ended — syncing UI")
                reapplyLock()
                return
            }
            if shieldManager.hasActiveUnlockSession() && shieldManager.isShieldActive {
                debugPrint("🔓 ContentView: Removing stale shield while session active")
                shieldManager.reconcileShieldState()
            }
            if !isUnlockActive && shieldManager.hasActiveUnlockSession() {
                isUnlockActive = true
                unlockEndsAt = loadUnlockTime()
                if #available(iOS 16.0, *) {
                    let budget = DeviceActivityManager.shared.allowedMinutes
                    if budget > 0 { unlockBudgetMinutes = budget }
                }
                showCustomLock = false
            }
            // 24h safety cap fallback (should rarely trigger if DeviceActivity works)
            if isUnlockActive, let end = unlockEndsAt, Date() >= end {
                debugPrint("⏰ ContentView: 24h safety cap reached — reapplying lock")
                endSafetyCap()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // App going to background - ShieldManager will handle timer via background task
            // Background task will apply shield after 15 minutes
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            autoPresentedUpgradeThisSession = false
            notificationManager.handleAppDidEnterBackground(
                eligibleForConversion: isEligibleForConversionNotifications
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            notificationManager.handleAppDidBecomeActive()
            userDataManager.mergeScrollMinutesFromAppGroup()
            syncLockUI()
            refreshAccessAndPresentPaywallIfLapsed()
        }
        .onChange(of: isRecitationPresented) { presented in
            if presented && !subscriptionManager.hasPremiumAccess && !subscriptionManager.isPremium {
                isRecitationPresented = false
                showUpgradePaywall = true
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
    
    private var deedHome: some View {
        GeometryReader { geo in
            let top = dashboardHeaderTop
            ZStack(alignment: .top) {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            Color.clear
                                .frame(height: top + 42)

                            NafsiMascotView(
                                stage: NafsiStage(rank: heartJourney.rank),
                                animated: true,
                                hearts: nafsiLives.hearts,
                                heartCapacity: nafsiLives.capacity,
                                artworkName: nafsiLocker.characterAsset
                            )
                            .frame(height: 232)
                            .padding(.horizontal, 36)
                            .padding(.bottom, 6)
                            .accessibilityHidden(true)

                            VStack(spacing: 18) {
                                if subscriptionManager.hasLapsedAccess {
                                    accessExpiredNotice
                                }

                                calmCompanionHero

                                GamifiedStreakView(
                                    userDataManager: userDataManager,
                                    practiceSheetPresented: $isRecitationPresented
                                )
                                .id(DashboardTutorialAnchor.week.rawValue)
                                .tutorialAnchor(.week)
                                .tutorialAnchor(.streak)

                                NafsiToolsSection(
                                    premiumLocked: !subscriptionManager.hasPremiumAccess,
                                    tutorialOnLockedAppsTile: DashboardTutorialLayout.isCompactPhone
                                ) { tool in
                                    openNafsiTool(tool)
                                }
                                .dashboardTutorialTarget(
                                    .lockedApps,
                                    active: !DashboardTutorialLayout.isCompactPhone
                                )

                                InAppFeedbackCard(source: .dashboard, isPresented: $showInAppFeedback)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, AppSpacing.xxl)
                        }
                        .frame(width: geo.size.width, alignment: .top)
                        .background(alignment: .top) {
                            NafsiSceneBackdrop(backgroundName: nafsiLocker.backgroundAsset)
                                .frame(maxWidth: .infinity)
                                .frame(height: top + 420)
                        }
                        .background(DashboardScrollClamp())
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .onChange(of: tutorialScrollID) { id in
                        guard let id else { return }
                        let anchor = Self.tutorialScrollAnchor
                        withAnimation(.easeInOut(duration: 0.35)) {
                            proxy.scrollTo(id, anchor: anchor)
                        }
                    }
                }

                logoHeader
                    .padding(.top, top)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    /// The logo sits just under the clock. The geometry inset is 0 once the
    /// scene draws behind the status bar, so the window inset is the real one.
    private var dashboardHeaderTop: CGFloat {
        let windowTop = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .map(\.safeAreaInsets.top)
            .max() ?? 0
        return max(windowTop, 59) + 8
    }

    /// Keeps the dashboard from sliding sideways, and from being pulled down
    /// past the scene so a bare edge appears above it.
    private struct DashboardScrollClamp: UIViewRepresentable {
        func makeUIView(context: Context) -> ClampView {
            let view = ClampView()
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
            return view
        }

        func updateUIView(_ uiView: ClampView, context: Context) {
            uiView.attachIfNeeded()
        }

        final class ClampView: UIView {
            private var observation: NSKeyValueObservation?
            private var locking = false

            override func didMoveToSuperview() {
                super.didMoveToSuperview()
                attachIfNeeded()
            }

            func attachIfNeeded() {
                guard let scroll = enclosingScrollView else { return }
                scroll.bounces = false
                scroll.alwaysBounceVertical = false
                scroll.alwaysBounceHorizontal = false
                scroll.showsHorizontalScrollIndicator = false
                scroll.isDirectionalLockEnabled = true
                scroll.contentInsetAdjustmentBehavior = .never
                scroll.contentInset = .zero
                if observation == nil {
                    observation = scroll.observe(\.contentOffset, options: [.new]) { [weak self] scroll, _ in
                        self?.lock(scroll)
                    }
                }
                lock(scroll)
            }

            private func lock(_ scroll: UIScrollView) {
                guard !locking else { return }
                var offset = scroll.contentOffset
                let clampedX: CGFloat = 0
                let clampedY = max(0, offset.y)
                guard offset.x != clampedX || offset.y != clampedY else { return }
                locking = true
                offset.x = clampedX
                offset.y = clampedY
                scroll.setContentOffset(offset, animated: false)
                locking = false
            }

            override func layoutSubviews() {
                super.layoutSubviews()
                attachIfNeeded()
            }

            override func didMoveToWindow() {
                super.didMoveToWindow()
                attachIfNeeded()
            }

            private var enclosingScrollView: UIScrollView? {
                var view: UIView? = self
                while let current = view {
                    if let scroll = current as? UIScrollView { return scroll }
                    if let match = current.superview?.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                        return match
                    }
                    view = current.superview
                }
                return nil
            }
        }
    }

    /// Hearts, coins, and the two actions under the full-bleed Nafsi scene.
    private var calmCompanionHero: some View {
        VStack(spacing: 14) {
            NafsiCoinsChip(
                coins: heartJourney.coins,
                hearts: nafsiLives.hearts,
                heartCapacity: nafsiLives.capacity,
                minutesRemaining: isUnlockActive ? nafsiLives.minutesRemaining : 0,
                onBuyHearts: {
                    HapticManager.shared.soft()
                    showBuyHearts = true
                }
            )
            .id(DashboardTutorialAnchor.heart.rawValue)
            .tutorialAnchor(.heart)

            dashboardActionTiles
                .id(DashboardTutorialAnchor.shop.rawValue)
                .tutorialAnchor(.shop)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
        .padding(.bottom, 2)
        .onAppear {
            nafsiLives.refreshFromUsage(isUnlocked: isUnlockActive)
        }
        .onChange(of: isUnlockActive) { unlocked in
            nafsiLives.refreshFromUsage(isUnlocked: unlocked)
        }
        .onChange(of: currentTime) { _ in
            nafsiLives.refreshFromUsage(isUnlocked: isUnlockActive)
        }
    }

    private func openNafsiTool(_ tool: NafsiTool) {
        HapticManager.shared.soft()
        if tool.requiresPremium && !subscriptionManager.hasPremiumAccess {
            presentPostTrialPaywall()
            return
        }
        switch tool {
        case .lockedApps:
            showLockedAppsTool = true
        case .homeWidgets:
            showHomeWidgets = true
        case .lockWidgets:
            showLockWidgets = true
        case .fajr:
            showFajrSettings = true
        case .reminders:
            showQuranReminders = true
        case .saved:
            showSavedCards = true
        }
    }

    private var customBottomNavigationBar: some View {
        HStack(alignment: .bottom, spacing: 0) {
            navTabButton(
                systemName: "book.closed.fill",
                title: NSLocalizedString("tab.scroll", comment: "Scroll"),
                selected: selectedMainTab == .feed
            ) {
                HapticManager.shared.buttonTap()
                showMainTab(.feed)
            }
            .tutorialAnchor(.navScroll)

            navUnlockLabel

            navTabButton(
                systemName: "gearshape.fill",
                title: NSLocalizedString("tab.settings", comment: "Settings"),
                selected: showSettingsView
            ) {
                HapticManager.shared.soft()
                showSettingsView = true
            }
            .tutorialAnchor(.navSettings)
        }
        .id(languageManager.languageEpoch)
        .padding(.top, 22)
        .padding(.bottom, 2)
        .overlay(alignment: .top) {
            raisedUnlockTab
                .tutorialAnchor(.navHome)
        }
        .background(alignment: .bottom) {
            ZStack {
                LinearGradient(
                    colors: [
                        AppTheme.card,
                        AppTheme.card.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)

                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.primary.opacity(0.2),
                                    AppTheme.primary.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1.5)
                    Spacer()
                }
            }
            .padding(.top, 22)
            .shadow(color: AppTheme.primary.opacity(0.15), radius: 20, x: 0, y: -5)
        }
        .tutorialAnchor(.navBar)
    }

    private var raisedUnlockTab: some View {
        let selected = selectedMainTab == .deed
        return Button {
            HapticManager.shared.buttonTap()
            showMainTab(.deed)
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryLight, AppTheme.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: AppTheme.primary.opacity(selected ? 0.45 : 0.32), radius: selected ? 14 : 10, y: 5)

                Circle()
                    .stroke(AppTheme.card, lineWidth: 5)
                    .frame(width: 58, height: 58)

                Image(systemName: "house.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(selected ? 1.06 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: selected)
        .accessibilityLabel(NSLocalizedString("tab.unlock", comment: "Home"))
    }

    private var navUnlockLabel: some View {
        Button {
            HapticManager.shared.buttonTap()
            showMainTab(.deed)
        } label: {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }

    private func navTabButton(
        systemName: String,
        title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: selected ? .semibold : .regular))
                Text(title)
                    .font(.system(size: 10, weight: selected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(
                selected
                ? AnyShapeStyle(LinearGradient(
                    colors: [
                        AppTheme.primaryLight,
                        AppTheme.primary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  ))
                : AnyShapeStyle(AppTheme.textMuted)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .scaleEffect(selected ? 1.08 : 1)
            .offset(y: selected ? -1 : 0)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: selected)
        }
        .accessibilityLabel(title)
    }

    // MARK: - Logo Header (ScrollDeeds green branding)
    private var logoHeader: some View {
        SDBrandHeader(
            topPadding: 2,
            bottomPadding: 6
        ) {
            SDCoinsPill(coins: heartJourney.coins)
                .tutorialAnchor(.coins)
        }
    }
    
    /// Remaining budget label: budget minus wall-clock time elapsed since session start.
    /// The DeviceActivityMonitor extension auto-locks accurately when real usage is up;
    /// this label is a display-only approximation.
    private var budgetCountdownLabel: String {
        guard unlockBudgetMinutes > 0 else {
            return NSLocalizedString("dashboard.unlocked", comment: "Unlocked")
        }
        if unlockBudgetMinutes >= 60 {
            return "\(unlockBudgetMinutes / 60)u \(unlockBudgetMinutes % 60)m"
        }
        return "\(unlockBudgetMinutes) min"
    }

    /// Dashboard CTA. TestFlight is not a subscription — if Pro/trial is inactive the
    /// upgrade paywall must appear immediately (it used to set a flag the dashboard never showed).
    private func startDeedFlow() {
        HapticManager.shared.medium()
        if subscriptionManager.hasPremiumAccess {
            presentDeedOrAppPicker()
            return
        }
        presentPostTrialPaywall()
    }

    /// Shared post-trial / lapsed-access entry: sales scroll → pricing (no free days).
    /// Stays on the paywall — never auto-opens deed/unlock/Fajr after a StoreKit refresh.
    /// (Sandbox entitlements were dismissing the paywall and starting a good-deed session.)
    private func presentPostTrialPaywall() {
        debugPrint("🚫 No premium access — presenting upgrade paywall")
        withAnimation(.easeInOut(duration: 0.3)) {
            showSettingsView = false
            showFajrSettings = false
            showCustomLock = false
            showUpgradePaywall = true
        }
    }

    private func presentDeedOrAppPicker() {
        if !shieldManager.hasShieldTargets {
            debugPrint("🎯 No apps selected - showing ForceAppSelectionView first")
            showForceAppSelection = true
        } else {
            isRecitationPresented = true
        }
    }

    @ViewBuilder
    private var upgradePaywall: some View {
        if OnboardingFunnelConfig.useConversionPaywall {
            ConversionPaywallView(
                variant: .postTrial,
                onClose: { dismissUpgradePaywall() },
                onSubscribed: handlePaywallSubscribed
            )
        } else {
            HardPaywallView(onSubscribed: handlePaywallSubscribed)
        }
    }

    private func refreshAccessAndPresentPaywallIfLapsed() {
        Task { @MainActor in
            await subscriptionManager.refreshPremiumStatus()
            enforcePremiumFeatureAccess()
            presentUpgradePaywallIfAccessLapsed()
        }
    }

    /// Fajr + widgets stay premium-only once trial/sub ends.
    private func enforcePremiumFeatureAccess() {
        let hasAccess = subscriptionManager.hasPremiumAccess
        fajrAlarm.enforcePremiumAccess(hasAccess)
        NafsiWidgetSettings.shared.publish()
    }

    private func dismissUpgradePaywall() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showUpgradePaywall = false
        }
        updateCustomLockView()
    }

    /// Access ran out while the user was away: the apps stay shielded, so the paywall is the
    /// first thing they see instead of a dashboard whose only button they cannot use.
    private func presentUpgradePaywallIfAccessLapsed() {
        guard localStorage.hasCompletedOnboarding else { return }
        // Prefer the live Store flag too — covers the beat before entitlements refresh.
        guard !subscriptionManager.hasPremiumAccess, !subscriptionManager.isPremium else { return }
        guard subscriptionManager.hasLapsedAccess else { return }
        guard !autoPresentedUpgradeThisSession, !isUnlockActive else { return }
        guard !showUpgradePaywall, !showHardPaywall, !showQuickGuide,
              !showDashboardTutorial, !showForceAppSelection,
              !isRecitationPresented, !showAlarm else { return }

        autoPresentedUpgradeThisSession = true
        debugPrint("💳 Access lapsed — presenting upgrade paywall on app open")
        withAnimation(.easeInOut(duration: 0.3)) {
            showCustomLock = false
            showUpgradePaywall = true
        }
    }

    // MARK: - Today's deed

    /// Earn coins and the shop, as two equal tiles.
    private var dashboardActionTiles: some View {
        HStack(spacing: 12) {
            dashboardTile(
                title: NSLocalizedString("deed.cta", comment: "Earn coins"),
                imageName: "NafsiTileCoins",
                wash: Color(red: 0.87, green: 0.63, blue: 0.15).opacity(0.16),
                action: startDeedFlow
            )
            dashboardTile(
                title: NSLocalizedString("shop.open", comment: "Shop"),
                imageName: "NafsiTileShop",
                wash: AppTheme.primary.opacity(0.12)
            ) {
                HapticManager.shared.soft()
                showShop = true
            }
        }
    }

    private func dashboardTile(
        title: String,
        imageName: String,
        wash: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(wash)
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                }
                .frame(height: 108)

                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .top)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(NafsiPressStyle())
    }

    /// Trial or paid access ran out — sits under the week streak so the user sees
    /// why unlocking no longer works, with one tap back into the paywall.
    private var accessExpiredNotice: some View {
        AccessExpiredNotice {
            presentPostTrialPaywall()
        }
    }

    /// The 24h wall is a clock reset, not a confiscation. Hearts the user still
    /// has start a fresh usage session. An empty tank stays locked.
    private func endSafetyCap() {
        let kept = nafsiLives.hearts
        reapplyLock(preserveHearts: kept > 0)
        guard kept > 0 else { return }
        let minutes = kept * max(1, nafsiLives.minutesPerHeart)
        guard shieldManager.completeUnlockSession(minutesEarned: minutes) else { return }
        nafsiLives.noteSessionHearts(kept)
        isUnlockActive = true
        unlockEndsAt = loadUnlockTime()
        unlockBudgetMinutes = minutes
        showCustomLock = false
        customLockDismissed = true
    }

    private func reapplyLock(preserveHearts: Bool = false) {
        debugPrint("🔒 Reapplying lock...")

        HapticManager.shared.appsLocked()
        isUnlockActive = false
        unlockEndsAt = nil
        unlockBudgetMinutes = 0
        customLockDismissed = false
        if !preserveHearts {
            nafsiLives.clearOnLock()
        }

        // Stop usage monitoring (extension may have already stopped it)
        if #available(iOS 16.0, *) {
            DeviceActivityManager.shared.stopMonitoring()
        }
        
        // Clear saved unlock session
        shieldManager.clearUnlockSessionMetadata()
        UserDefaults.standard.removeObject(forKey: "unlockEndsAt")
        
        // Cancel any pending notifications from previous lock cycle
        notificationManager.onAppsLocked()
        notificationManager.cancelAllLockRelatedNotifications(force: true)
        
        // Apply shield
        shieldManager.applyShield()
        
        // Show custom lock view (only if not manually dismissed)
        if !customLockDismissed {
            showCustomLock = true
        }
        
        // Schedule clean, consistent locked app reminders
        notificationManager.scheduleLockedAppReminders()
        
        debugPrint("✅ Lock reapplied! Shield active + clean reminder notifications scheduled.")
    }
    
    /// A good deed pays coins only. Hearts stay as they are until the user buys them.
    private func rewardCoinsForDeed() {
        userDataManager.completeSession(minutesEarned: 0)
        userDataManager.clearPendingUnlockMinutes()
        customLockDismissed = true
        showCustomLock = false
        showDashboardTab()
        updateCustomLockView()
        beginCoinFlightIfNeeded()
    }

    /// Sends the deed's coins across the dashboard into the header pill.
    private func beginCoinFlightIfNeeded() {
        let reward = heartJourney.pendingDeedCoins
        guard reward > 0, flyingCoins == nil, !coinFlightArmed else { return }
        coinFlightArmed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            coinFlightArmed = false
            guard heartJourney.pendingDeedCoins > 0, flyingCoins == nil else { return }
            flyingCoins = heartJourney.pendingDeedCoins
        }
    }
    
    // MARK: - Persistent Unlock State
    
    /// Single source of truth with `ShieldManager` (shared / App Group `unlockEndTime`).
    /// Legacy `unlockEndsAt` in standard UserDefaults is migrated on ShieldManager init.
    private func loadUnlockTime() -> Date? {
        shieldManager.getUnlockEndTime()
    }
    
    private func saveUnlockTime(_ date: Date) {
        shieldManager.setUnlockEndTime(date)
        debugPrint("💾 Saved unlock time: \(date)")
    }
    
    private func clearUnlockTime() {
        shieldManager.clearUnlockEndTime()
        UserDefaults.standard.removeObject(forKey: "unlockEndsAt")
        debugPrint("🗑️ Cleared unlock time")
    }
    
    private func restoreUnlockState() {
        if let savedTime = loadUnlockTime(), savedTime > Date() {
            isUnlockActive = true
            unlockEndsAt = savedTime
            if #available(iOS 16.0, *) {
                let budget = DeviceActivityManager.shared.allowedMinutes
                if budget > 0 { unlockBudgetMinutes = budget }
            }
            shieldManager.removeShield()
            notificationManager.purgeStaleLockNotificationsIfUnlocked()
            debugPrint("✅ Restored unlock state — DeviceActivity monitoring active")
        } else if let savedTime = loadUnlockTime(), savedTime <= Date() {
            debugPrint("⏰ Safety cap expired — \(savedTime)")
            endSafetyCap()
        } else if shieldManager.hasActiveUnlockSession() {
            // Usage budget active without wall-clock cap (e.g. after inconsistent extension state)
            isUnlockActive = true
            if #available(iOS 16.0, *) {
                let budget = DeviceActivityManager.shared.allowedMinutes
                if budget > 0 { unlockBudgetMinutes = budget }
                unlockEndsAt = Date().addingTimeInterval(24 * 60 * 60)
                saveUnlockTime(unlockEndsAt!)
            }
            shieldManager.removeShield()
            notificationManager.purgeStaleLockNotificationsIfUnlocked()
            debugPrint("✅ Restored unlock from usage budget")
        } else {
            isUnlockActive = false
            unlockEndsAt = nil
            shieldManager.reconcileShieldState()
            debugPrint("✅ No unlock session — shield is active by default")
        }
    }
    
    /// Reconcile persisted lock state with UI whenever the app returns to foreground.
    private func syncLockUI() {
        restoreUnlockState()
        shieldManager.reconcileShieldState()
        
        if shieldManager.hasActiveUnlockSession() {
            isUnlockActive = true
            if unlockEndsAt == nil {
                unlockEndsAt = loadUnlockTime()
            }
            showCustomLock = false
            notificationManager.purgeStaleLockNotificationsIfUnlocked()
        } else if isUnlockActive && !shieldManager.isInUnlockGracePeriod() {
            reapplyLock()
            return
        }
        
        updateCustomLockView()
    }
    
    private func timeRemaining() -> String {
        guard let end = unlockEndsAt else { return "0s" }
        return formatTimeRemaining(seconds: max(0, Int(end.timeIntervalSince(currentTime))))
    }

    /// Formats remaining seconds as "Xh Ym" when >= 60 min, otherwise "Xm Ys".
    private func formatTimeRemaining(seconds: Int) -> String {
        let s = max(0, seconds)
        if s >= 3600 {
            return String(format: NSLocalizedString("dashboard.time_format_hours", comment: "%dh %dm"), s / 3600, (s % 3600) / 60)
        } else if s >= 60 {
            return String(format: NSLocalizedString("dashboard.time_format", comment: "%dm %ds"), s / 60, s % 60)
        } else {
            return String(format: NSLocalizedString("dashboard.time_format_seconds", comment: "%ds"), s)
        }
    }
    
    // Update custom lock view visibility
    private func updateCustomLockView() {
        if showHardPaywall || showUpgradePaywall {
            showCustomLock = false
            return
        }

        // A heart was just bought from the lock page. Stay on the dashboard
        // until the buy sheet closes — don't put the lock back underneath it.
        if heartPurchaseDismissesLock {
            showCustomLock = false
            return
        }

        // First home visit: dashboard + tutorial first — never cover them with the lock overlay.
        if showQuickGuide || showDashboardTutorial || localStorage.needsDashboardTutorial {
            showCustomLock = false
            return
        }
        
        // Never show the lock screen while an unlock session is active in persisted storage.
        if isUnlockActive || shieldManager.hasActiveUnlockSession() {
            showCustomLock = false
            customLockDismissed = false
            return
        }
        
        if customLockDismissed {
            showCustomLock = false
            return
        }
        
        if shieldManager.isShieldActive {
            showCustomLock = true
        } else {
            showCustomLock = false
            customLockDismissed = false
        }
    }
    
    private var unlockDurationMinutes: Int { userDataManager.unlockDurationMinutes }
    private var unlockDurationHours: Int   { userDataManager.unlockDurationHours }
    
    /// After commitment (and optional referral): first real deed, then hard paywall.
    private func advanceAfterCommitment() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { advanceAfterCommitment() }
            return
        }
        let alreadyDidFirstDeed = UserDefaults.standard.bool(forKey: "hasCompletedOnboardingFirstDeed")
        if OnboardingFunnelConfig.showFirstDeedBeforePaywall, !alreadyDidFirstDeed {
            debugPrint("🔄 Showing first-win deed before paywall")
            withAnimation(.easeInOut(duration: 0.45)) {
                showFirstWin = true
            }
        } else {
            debugPrint("🔄 Skipping first-win → paywall")
            performSafeTransition()
        }
    }

    /// Single animated swap: life-change → paywall loading (or first-win if enabled).
    private func transitionFromLifeChangeToNextStep() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { transitionFromLifeChangeToNextStep() }
            return
        }
        let alreadyDidFirstDeed = UserDefaults.standard.bool(forKey: "hasCompletedOnboardingFirstDeed")
        withAnimation(AppMotion.funnelHandoff) {
            showLifeChange = false
            showQuestionnaire = false
            if OnboardingFunnelConfig.showFirstDeedBeforePaywall, !alreadyDidFirstDeed {
                showFirstWin = true
            } else {
                showHardPaywall = true
            }
        }
    }

    // Smooth transition from questionnaire to paywall (no black screen gap)
    private func performSafeTransition() {
        // Always ensure main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                performSafeTransition()
            }
            return
        }
        
        debugPrint("🔄 Performing safe transition to paywall...")
        
        // Referral → HardPaywall: loading → plan ready → trial reminder → pricing (see HardPaywallView).
        withAnimation(AppMotion.funnelHandoff) {
            showQuestionnaire = false
            showHardPaywall = true
        }
        debugPrint("🔄 Showing hard paywall (full funnel inside HardPaywallView)")
    }
    
    /// Shared post-subscribe path for HardPaywallView and ConversionPaywallView.
    /// Order after purchase (inside paywall): Thank You → apps → difficulty → then here.
    /// Quick Guide is Settings-only — not shown after paywall.
    private func handlePaywallSubscribed() {
        showHardPaywall = false
        showUpgradePaywall = false
        showQuickGuide = false
        LocalStorageManager.shared.hasSeenQuickGuide = true
        showDashboardTab()
        enforcePremiumFeatureAccess()
        let alreadyOnboarded = localStorage.hasCompletedOnboarding
        completeOnboardingFlow()
        // Returning / post-trial subscribers: land on the dashboard. Do not auto-open
        // the deed flow — that re-triggers the upgrade paywall when access is still settling.
        if alreadyOnboarded {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            maybePlayHeartWelcome()
        }
    }

    private func maybePlayHeartWelcome() {
        guard localStorage.hasCompletedOnboarding else { return }
        guard !showQuickGuide, !showHardPaywall, !showUpgradePaywall else { return }
        guard !showDashboardTutorial, !showCustomLock else { return }
        guard selectedMainTab == .deed else { return }
        // The live tour explains the dashboard first. The gift opens after it.
        if localStorage.needsDashboardTutorial {
            maybeStartDashboardTutorial()
            return
        }
        if heartJourney.beginWelcomeIfNeeded() {
            showCustomLock = false
            showDashboardTab()
        }
    }

    private func maybeStartDashboardTutorial() {
        guard localStorage.hasCompletedOnboarding else { return }
        guard localStorage.needsDashboardTutorial else { return }
        guard !showQuickGuide else { return }
        guard !showHardPaywall else { return }
        guard !showUpgradePaywall else { return }
        guard !showDashboardTutorial else { return }
        guard !heartJourney.isPlayingWelcome else { return }
        // Keep lock overlay off so the live dashboard is visible under the tour.
        showCustomLock = false
        showDashboardTab()
        debugPrint("🎯 Starting first-visit dashboard tutorial")
        withAnimation(.easeInOut(duration: 0.3)) {
            showDashboardTutorial = true
        }
    }

    private func showDashboardTab() {
        showMainTab(.deed)
    }

    /// Home and Scroll crossfade with a short slide from the tab you tapped.
    private func showMainTab(_ tab: MainTab) {
        guard selectedMainTab != tab else { return }
        mainTabFromLeft = tab == .feed
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            selectedMainTab = tab
        }
    }

    private var mainTabTransition: AnyTransition {
        let travel: CGFloat = 36
        let insertX = mainTabFromLeft ? -travel : travel
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(x: insertX)),
            removal: .opacity.combined(with: .offset(x: -insertX * 0.55))
        )
    }

    private func finishDashboardTutorial() {
        localStorage.markDashboardTutorialSeen()
        withAnimation(.easeInOut(duration: 0.25)) {
            showDashboardTutorial = false
        }
        tutorialScrollID = nil
        // Stay on the dashboard after the tour — don’t immediately force the lock sheet.
        customLockDismissed = true
        showCustomLock = false
        showDashboardTab()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            maybePlayHeartWelcome()
        }
    }

    private func applyTutorialStep(_ step: DashboardTutorialStep) {
        switch step.anchor {
        case .navScroll:
            showMainTab(.feed)
        case .navBar, .navHome, .streak, .week, .heart, .coins, .shop, .lockedApps, .progress,
             .navPractice, .navProgress, .navSettings, nil:
            showMainTab(.deed)
        }
        scrollDashboardTutorial(to: step)
    }

    /// On a short phone `.center` slides the week strip under the clock and the
    /// tools title under the logo. Park the target just below that header.
    private static var tutorialScrollAnchor: UnitPoint {
        guard DashboardTutorialLayout.isCompactPhone else { return .center }
        let y: CGFloat = UIScreen.main.bounds.height < 700 ? 0.40 : 0.30
        return UnitPoint(x: 0.5, y: y)
    }

    private func scrollDashboardTutorial(to step: DashboardTutorialStep) {
        guard let anchor = step.anchor else {
            tutorialScrollID = DashboardTutorialAnchor.heart.rawValue
            return
        }
        switch anchor {
        case .heart, .shop, .lockedApps, .progress:
            tutorialScrollID = anchor.rawValue
        case .coins:
            tutorialScrollID = DashboardTutorialAnchor.heart.rawValue
        case .navProgress:
            tutorialScrollID = DashboardTutorialAnchor.progress.rawValue
        case .streak, .week:
            if DashboardTutorialLayout.isCompactPhone {
                tutorialScrollID = DashboardTutorialAnchor.week.rawValue
            }
        case .navHome, .navSettings, .navBar, .navScroll, .navPractice:
            break
        }
    }

    // Complete onboarding flow helper
    private func completeOnboardingFlow() {
        localStorage.completeOnboarding()
        showHardPaywall = false
        
        // Cancel re-engagement and welcome notifications when user subscribes
        notificationManager.cancelReengagementNotifications()
        notificationManager.cancelWelcomeNotifications()
        notificationManager.cancelPaywallLeaveConversionNudge()
        debugPrint("🗑️ Cancelled re-engagement and welcome notifications (user subscribed)")

        // ATT deferred from cold start — ask once value is clear (after subscribe/onboarding).
        if OnboardingFunnelConfig.deferATTUntilAfterOnboarding {
            TrackingPermissionManager.requestIfNeeded {
                MetaEventsManager.shared.prepareSession()
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

}

/// Amber dashboard card shown when the trial (or paid access) has lapsed.
struct AccessExpiredNotice: View {
    let onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("access.expired.title", comment: "Your free trial has ended"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(NSLocalizedString("access.expired.body", comment: "You no longer have access. Upgrade to keep unlocking your apps with a good deed."))
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                HapticManager.shared.medium()
                onUpgrade()
            } label: {
                Text(NSLocalizedString("access.expired.cta", comment: "Upgrade"))
            }
            .buttonStyle(PrimaryButtonStyle(verticalPadding: 14))
        }
        .sdSurfaceCard(cornerRadius: AppRadius.lg, padding: 16)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.22), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}

