//
//  scrolldeedsApp.swift
//  scrolldeeds
//
//  Created by Sabri El makhoukhi on 30/10/2025.
//

import SwiftUI
import UIKit
import Combine
import BackgroundTasks
import RevenueCat
import PostHog
import FacebookCore

// Routes a URL from AppDelegate → SwiftUI's active window, bypassing the
// UIApplication.shared.open reliability issues in iOS 18 AppDelegate callbacks.
@MainActor
final class QuickLinkRouter: ObservableObject {
    static let shared = QuickLinkRouter()
    @Published var pendingURL: URL?
    private init() {}
}

@main
struct scrolldeedsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Changing language used to persist `AppleLanguages`. Only wipe the key —
        // do not construct LanguageManager / ContentView here. That ran during
        // SwiftUI scene connect and crashed after: dashboard → change language → kill → reopen.
        LanguageManager.clearSystemLanguageOverride()
    }

    var body: some Scene {
        WindowGroup {
            SceneRootView()
        }
    }
}

/// Holds off `ContentView` (and every singleton it touches) until the scene
/// finished connecting. Creating those objects inside `App.body` raced
/// `AppSceneDelegate.responds(to:)` after an in-app language change.
private struct SceneRootView: View {
    @State private var isSceneReady = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            if isSceneReady {
                ContentView()
                    .syncAppearanceWithWindows()
                    .onReceive(QuickLinkRouter.shared.$pendingURL.compactMap { $0 }) { url in
                        QuickLinkRouter.shared.pendingURL = nil
                        UIApplication.shared.open(url, options: [:]) { success in
                            debugPrint("🔗 Quick link open \(url.absoluteString) → \(success)")
                        }
                    }
            }
        }
        .onAppear {
            // Two turns of the main queue: `willConnect` must finish first.
            // A single async can still run inside AppSceneDelegate.responds(to:).
            DispatchQueue.main.async {
                DispatchQueue.main.async {
                    isSceneReady = true
                }
            }
        }
    }
}

// AppDelegate to handle notifications and background tasks
class AppDelegate: NSObject, UIApplicationDelegate {
    private var pendingShortcutItem: UIApplicationShortcutItem?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        LanguageManager.clearSystemLanguageOverride()

        // Meta (Facebook) SDK — App Events, attribution, deep links
        #if DEBUG
        Settings.shared.enableLoggingBehavior(.appEvents)
        Settings.shared.enableLoggingBehavior(.networkRequests)
        #endif
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        // Do not touch ShieldManager here — its timer and @Published state
        // during scene connect crashed the next launch after a language change.

        // Initialize RevenueCat
        // Productie API Key voor Scrolldeeds (App Store)
        let revenueCatAPIKey = "appl_wfLidJYoHXcwgXbFKMDBZGNfxGH"
        Purchases.configure(withAPIKey: revenueCatAPIKey)
        
        // Configure RevenueCat with best practices
        Purchases.shared.delegate = RevenueCatDelegate.shared
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif
        
        // Force clear offerings cache (temporary - remove after testing)
        #if DEBUG
        debugPrint("🗑️ Clearing RevenueCat cache...")
        Purchases.shared.invalidateCustomerInfoCache()
        #endif
        
        // Initialize PostHog (API key from Info.plist)
        let posthogKey = Bundle.main.infoDictionary?["PostHogAPIKey"] as? String ?? "phc_qEYE2b7DNFVSmjyZk6lKwRx1uuSrUktpSo4tmUeK0Vq"
        let posthogHost = "https://eu.i.posthog.com"
        let config = PostHogConfig(apiKey: posthogKey, host: posthogHost)
        // Autocapture reports the UIViewController class name, which for SwiftUI is always
        // `UIHostingController<...>`. We send readable screen names ourselves instead.
        config.captureScreenViews = false
        PostHogSDK.shared.setup(config)
        
        // Track app launch for analytics
        PostHogManager.shared.identifyCurrentUser()
        AnalyticsManager.shared.trackAppLaunch()
        PostHogManager.shared.trackAppLaunch()
        PostHogManager.shared.beginSession()
        PostHogSDK.shared.reloadFeatureFlags {
            Task { @MainActor in
                PaywallExperiment.shared.resolve()
            }
        }
        
        // Register background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.scrolldeeds.app.shieldCheck", using: nil) { task in
            self.handleShieldCheckTask(task: task as! BGProcessingTask)
        }
        
        // Shortcuts are applied in `applicationDidBecomeActive` so launch does not
        // touch localization / LanguageManager during scene connect.

        // Cold launch via Home Screen quick action:
        // Return FALSE when a shortcut triggered this launch — this tells iOS that WE handle
        // the shortcut ourselves (via pendingShortcutItem + applicationDidBecomeActive),
        // so the system will NOT additionally call performActionFor.
        // If we returned true, iOS would call performActionFor *as well*, causing a double-fire
        // where both handlers race to open Safari and cancel each other out on iOS 18.
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            pendingShortcutItem = shortcutItem
            return false
        }

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }

    // Do NOT implement `configurationForConnecting`. Returning any UISceneConfiguration
    // from AppDelegate in a SwiftUI `@main` app can recurse in AppSceneDelegate.responds(to:)
    // and crash on launch (EXC_BAD_ACCESS). Shortcuts still arrive via
    // `didFinishLaunchingWithOptions` and `performActionFor`.

    // MARK: - Home Screen Quick Actions

    private func setupHomeScreenQuickActions(_ application: UIApplication) {
        // Altijd tonen: links openen Safari naar uitleg op de site (ook voor premium / influencer).
        // iOS toont de `shortcutItems` dynamisch in (in deze case) omgekeerde volgorde.
        // Gewenste weergave (boven → onder): Shaytaan → betaling → waarom verlaten.
        let shortcutItems: [UIApplicationShortcutItem] = [
            // We zetten ze daarom bewust achterstevoren in de array.
            UIApplicationShortcutItem(
                type: "com.scrolldeeds.delete.reason",
                localizedTitle: NSLocalizedString("quickaction.delete.reason_title", comment: "Why are you deleting ScrollDeeds?"),
                localizedSubtitle: NSLocalizedString("quickaction.delete.reason_subtitle", comment: "Tell us what is making you leave"),
                icon: UIApplicationShortcutIcon(systemImageName: "questionmark.bubble.fill"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: "com.scrolldeeds.delete.money",
                localizedTitle: NSLocalizedString("quickaction.delete.money_title", comment: "Why ScrollDeeds requires payment"),
                localizedSubtitle: NSLocalizedString("quickaction.delete.money_subtitle", comment: "Understand why the app is paid"),
                icon: UIApplicationShortcutIcon(systemImageName: "dollarsign.circle.fill"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: "com.scrolldeeds.delete.shaytaan",
                localizedTitle: NSLocalizedString("quickaction.delete.shaytaan_title", comment: "Pause before deleting"),
                localizedSubtitle: NSLocalizedString("quickaction.delete.shaytaan_subtitle", comment: "Reflect before leaving"),
                icon: UIApplicationShortcutIcon(systemImageName: "exclamationmark.triangle.fill"),
                userInfo: nil
            ),
            // Let op: we houden het aantal items bewust beperkt tot 3 voor de quick action lijst.
        ]

        application.shortcutItems = shortcutItems
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        setupHomeScreenQuickActions(application)
        PostHogManager.shared.beginSession()

        // CRO: defer ATT until after onboarding so cold-start users aren't hit with a
        // permission dialog before any value. Returning users still get the prompt here.
        let shouldRequestATTNow: Bool = {
            if OnboardingFunnelConfig.deferATTUntilAfterOnboarding {
                return LocalStorageManager.shared.hasCompletedOnboarding
            }
            return true
        }()

        if shouldRequestATTNow {
            TrackingPermissionManager.requestIfNeeded {
                MetaEventsManager.shared.prepareSession()
                AppEvents.shared.activateApp()
                #if DEBUG
                AppEvents.shared.flush()
                debugPrint("📊 Meta AppEvents flushed — check Xcode console for FBSDK network logs")
                #endif
            }
        } else {
            MetaEventsManager.shared.prepareSession()
            AppEvents.shared.activateApp()
            #if DEBUG
            AppEvents.shared.flush()
            debugPrint("📊 Meta AppEvents activated without ATT (deferred until onboarding completes)")
            #endif
        }
        guard let shortcutItem = pendingShortcutItem else { return }
        pendingShortcutItem = nil
        guard let url = ScrollDeedsQuickLinkHandler.url(for: shortcutItem) else { return }
        // Cold-start path: give the SwiftUI window time to render and subscribe to
        // QuickLinkRouter.$pendingURL before we publish the URL.
        // 0.5 s is enough on all devices.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            QuickLinkRouter.shared.pendingURL = url
        }
    }

    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        // Warm-start path (app was in the background).
        // Cold starts return false from didFinishLaunchingWithOptions so iOS never calls
        // this for cold starts — no double-fire risk.
        pendingShortcutItem = nil
        guard let url = ScrollDeedsQuickLinkHandler.url(for: shortcutItem) else {
            completionHandler(false)
            return
        }
        // The SwiftUI window is already active — publish immediately.
        // QuickLinkRouter's onReceive fires on the next render cycle, which is the
        // safe moment to call UIApplication.shared.open.
        QuickLinkRouter.shared.pendingURL = url
        completionHandler(true)
    }
    
    // Schedule background task
    func scheduleShieldCheckTask() {
        let request = BGProcessingTaskRequest(identifier: "com.scrolldeeds.app.shieldCheck")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1) // Run in 1 second
        
        do {
            try BGTaskScheduler.shared.submit(request)
            debugPrint("✅ Background task scheduled for shield check")
        } catch {
            debugPrint("❌ Failed to schedule background task: \(error)")
        }
    }
    
    // Handle background task - THIS RUNS EVEN WHEN APP IS CLOSED!
    func handleShieldCheckTask(task: BGProcessingTask) {
        debugPrint("🔒🔒🔒 BGTaskScheduler task EXECUTED - App is woken up!")
        
        task.expirationHandler = {
            debugPrint("⚠️ BGTask expired")
            task.setTaskCompleted(success: false)
        }
        
        if ShieldManager.shared.hasActiveUnlockSession() {
            debugPrint("⏳ BGTask: unlock session still active — skipping forced lock")
            task.setTaskCompleted(success: true)
            return
        }
        
        debugPrint("⏰ BGTask: no active unlock — reconciling shield state")
        ShieldManager.shared.reconcileShieldState()
        task.setTaskCompleted(success: true)
        debugPrint("✅ BGTask completed")
    }
    
    // Handle notification when app is in background
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Check if this is a shield application notification
        if userInfo["apply_shield"] as? Bool == true,
           !ShieldManager.shared.hasActiveUnlockSession() {
            ShieldManager.shared.forceApplyShieldOnExpiry()
        }
        completionHandler(.newData)
    }
    
    // Called when app enters background - schedule background task
    func applicationDidEnterBackground(_ application: UIApplication) {
        PostHogManager.shared.endSession()

        if let unlockEnd = ShieldManager.shared.getUnlockEndTime() {
            let now = Date()
            if now < unlockEnd && ShieldManager.shared.hasActiveUnlockSession() {
                // Only schedule BGTask for the 24h safety cap — usage-based lock is handled by the extension
                let request = BGProcessingTaskRequest(identifier: "com.scrolldeeds.app.shieldCheck")
                request.requiresNetworkConnectivity = false
                request.requiresExternalPower = false
                request.earliestBeginDate = unlockEnd
                
                do {
                    try BGTaskScheduler.shared.submit(request)
                    debugPrint("✅ BGTask scheduled for safety cap expiry: \(unlockEnd)")
                } catch {
                    debugPrint("❌ Failed to schedule BGTask: \(error)")
                }
            } else if !ShieldManager.shared.hasActiveUnlockSession() {
                ShieldManager.shared.reconcileShieldState()
            }
        }
    }
}

#if DEBUG
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#else
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // No-op in production
}
#endif
