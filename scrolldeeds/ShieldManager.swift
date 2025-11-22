//
//  ShieldManager.swift
//  scrolldeeds
//
//  Applies and removes app shields using Managed Settings.
//  All data stored locally using UserDefaults
//

import Foundation
import Combine
import UIKit
import BackgroundTasks

#if canImport(ManagedSettings)
import ManagedSettings
#endif

#if canImport(FamilyControls)
import FamilyControls
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

final class ShieldManager: ObservableObject {
    // Singleton to ensure timer keeps running
    static let shared = ShieldManager()
    
    // Background Task Identifier
    private static let backgroundTaskIdentifier = "com.scrolldeeds.app.shieldCheck"
    
    #if canImport(ManagedSettings)
    // Use a NAMED store so it persists across app lifecycles
    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("scrolldeeds.shield"))
    #endif

    // Store selected app tokens and apps for UI
    @Published var selectedApplications: Set<ApplicationToken> = []
    @Published var selectedApps: Set<Application> = []
    @Published var isShieldActive: Bool = false
    
    
    // Use App Groups for data sharing (if needed in future)
    private let defaults = UserDefaults(suiteName: "group.com.scrolldeeds.app") ?? UserDefaults.standard
    private let shieldActiveKey = "isShieldActive"
    private let selectionKey = "familyActivitySelection"
    private let unlockEndKey = "unlockEndTime"
    
    // Timer to check shield status every 1 second
    private var checkTimer: Timer?
    
    // Pre-emptive shield timer - applies shield 10 seconds before expiry
    private var preemptiveShieldTimer: Timer?
    
    // Background Task handle
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // Background timer
    private var backgroundTimer: Timer?
    
    private init() {
        loadLockedApps()
        debugPrint("🔒 ShieldManager init: Loaded \(selectedApplications.count) apps, shield active: \(isShieldActive)")
        
        // CRITICAL: Check if unlock period expired while app was closed
        checkAndApplyShieldIfNeeded()
        
        // CRITICAL: Ensure shield state is correct immediately
        ensureShieldState()
        
        // Start continuous checking timer
        startContinuousChecking()
        
        // Listen for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        // Stop background task since app is now active
        backgroundTimer?.invalidate()
        backgroundTimer = nil
        endBackgroundShieldTask()
        
        // CRITICAL: When user opens app, check if 15 minutes expired
        // If yes, STOP THE ALARM and apply shield immediately
        debugPrint("📱 App became active - Checking if 15 minutes expired")
        
        // Check if unlock time expired
        if let unlockEnd = defaults.object(forKey: unlockEndKey) as? Date {
            let now = Date()
            if now >= unlockEnd {
                // 15 minutes expired - STOP ALARM and APPLY SHIELD IMMEDIATELY
                debugPrint("⏰⏰⏰ 15 minutes expired - User opened app, STOPPING ALARM and APPLYING shield NOW!")
                
                // Stop all recurring alarm notifications
                NotificationManager.shared.cancelRecurringTimeExpiredNotifications()
                NotificationManager.shared.cancelUnlockExpiryNotification()
                debugPrint("🔕 ALARM STOPPED - User opened the app")
                
                // Apply shield immediately
                forceApplyShieldOnExpiry()
            } else {
                // Time still valid - shield should be off
                let remaining = Int(unlockEnd.timeIntervalSince(now))
                debugPrint("⏰ Still unlocked: \(remaining/60)m \(remaining%60)s remaining")
                checkAndApplyShieldIfNeeded()
            }
        } else {
            // No unlock time - shield should be active
            debugPrint("🔒 No unlock session - shield should be active")
            checkAndApplyShieldIfNeeded()
        }
        
        ensureShieldState()
        
        // CRITICAL: If shield is active, ensure reminder notifications are scheduled
        // This fixes the issue where notifications stop after app restart or long periods
        if isShieldActive {
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let hasReminderNotifications = requests.contains { $0.identifier.starts(with: "locked_app_reminder_") }
                if !hasReminderNotifications {
                    DispatchQueue.main.async {
                        debugPrint("📅 Shield is active but no reminders found - re-scheduling now!")
                        NotificationManager.shared.scheduleLockedAppReminders()
                    }
                }
            }
        }
        
        debugPrint("📱 App active - shield check complete. Shield active: \(isShieldActive)")
    }
    
    @objc private func appWillResignActive() {
        // SIMPLE APPROACH: Just log that app is going to background
        // Shield will be applied when user opens app again (if 15 minutes expired)
        debugPrint("📱 ScrollDeeds going to background")
        
        // If timer already expired, apply shield now
        if let unlockEnd = defaults.object(forKey: unlockEndKey) as? Date {
            let now = Date()
            if now >= unlockEnd {
                // Time already expired - apply shield before going to background
                debugPrint("⏰ Timer expired - applying shield before going to background")
                forceApplyShieldOnExpiry()
            } else {
                // Timer still running - notification will remind user to open app
                let remaining = Int(unlockEnd.timeIntervalSince(now))
                debugPrint("⏰ Timer still running: \(remaining/60)m \(remaining%60)s - notification will remind user")
            }
        } else {
            // No unlock time - shield should be active
            debugPrint("🔒 No unlock time - ensuring shield is active")
            #if canImport(ManagedSettings)
            if #available(iOS 16.0, *), !selectedApplications.isEmpty {
                store.shield.applications = selectedApplications
                store.shield.applicationCategories = nil
                store.shield.webDomains = nil
                isShieldActive = true
                saveLockedApps()
                debugPrint("✅ Shield ACTIVE - Apps locked")
            }
            #endif
        }
    }
    
    // MARK: - Background Task for Automatic Shield Application
    
    private func startBackgroundShieldTask() {
        // End any existing background task
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // Start new background task
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "ShieldCheck") { [weak self] in
            // This is called when iOS is about to end the background task
            debugPrint("⏰ Background task about to expire, ending...")
            self?.endBackgroundShieldTask()
        }
        
        guard backgroundTask != .invalid else {
            debugPrint("⚠️ Could not start background task")
            return
        }
        
        debugPrint("✅ Background task started: \(backgroundTask.rawValue)")
        
        // Invalidate any existing background timer
        backgroundTimer?.invalidate()
        
        // Start a timer that checks every second when time expires
        var checkCount = 0
        let maxChecks = 1200 // Check for up to 20 minutes (covers 15 minute unlock + margin)
        
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            checkCount += 1
            
            // Check remaining background time
            let remainingBackgroundTime = UIApplication.shared.backgroundTimeRemaining
            if remainingBackgroundTime < 1 {
                debugPrint("⏰ Background time almost expired (\(remainingBackgroundTime)) - ending task")
                timer.invalidate()
                self.backgroundTimer = nil
                self.endBackgroundShieldTask()
                return
            }
            
            // Check if unlock time expired
            if let unlockEnd = self.defaults.object(forKey: self.unlockEndKey) as? Date {
                let now = Date()
                if now >= unlockEnd {
                    // TIME EXPIRED - APPLY SHIELD IMMEDIATELY
                    debugPrint("⏰⏰⏰ BACKGROUND: Unlock time EXPIRED - APPLYING SHIELD NOW! ⏰⏰⏰")
                    
                    #if canImport(ManagedSettings)
                    if #available(iOS 16.0, *), !self.selectedApplications.isEmpty {
                        self.store.shield.applications = self.selectedApplications
                        self.store.shield.applicationCategories = nil
                        self.store.shield.webDomains = nil
                        self.isShieldActive = true
                        self.defaults.removeObject(forKey: self.unlockEndKey)
                        self.saveLockedApps()
                        debugPrint("✅✅✅ SHIELD APPLIED IN BACKGROUND - Apps are now LOCKED! ✅✅✅")
                        
                        // Verify it was applied
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if self.store.shield.applications != self.selectedApplications {
                                debugPrint("⚠️ Verification: Reapplying shield...")
                                self.store.shield.applications = self.selectedApplications
                                self.store.shield.applicationCategories = nil
                                self.store.shield.webDomains = nil
                            }
                        }
                    }
                    #endif
                    
                    // Stop timer and end background task
                    timer.invalidate()
                    self.backgroundTimer = nil
                    self.endBackgroundShieldTask()
                    return
                } else {
                    let remaining = Int(unlockEnd.timeIntervalSince(now))
                    if checkCount % 60 == 0 { // Log every minute
                        debugPrint("⏰ Background: \(remaining/60)m \(remaining%60)s remaining until lock (task running: \(checkCount)s)")
                    }
                }
            } else {
                // No unlock time - shield should be active
                debugPrint("🔒 Background: No unlock time - ensuring shield is active")
                #if canImport(ManagedSettings)
                if #available(iOS 16.0, *), !self.selectedApplications.isEmpty {
                    self.store.shield.applications = self.selectedApplications
                    self.isShieldActive = true
                    self.saveLockedApps()
                }
                #endif
                timer.invalidate()
                self.backgroundTimer = nil
                self.endBackgroundShieldTask()
                return
            }
            
            // Stop after max checks (safety limit)
            if checkCount >= maxChecks {
                debugPrint("⏰ Background task ending (max checks reached: \(checkCount))")
                timer.invalidate()
                self.backgroundTimer = nil
                self.endBackgroundShieldTask()
            }
        }
        
        // Add timer to RunLoop to keep it alive
        if let timer = backgroundTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func endBackgroundShieldTask() {
        if backgroundTask != .invalid {
            debugPrint("🔚 Ending background task: \(backgroundTask.rawValue)")
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func ensureShieldState() {
        // CRITICAL: Always ensure shield state matches unlock status
        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *), !selectedApplications.isEmpty {
            if let unlockEnd = defaults.object(forKey: unlockEndKey) as? Date {
                if Date() >= unlockEnd {
                    // Time expired - shield MUST be on
                    if !isShieldActive || store.shield.applications == nil {
                        debugPrint("🔒 CRITICAL: Time expired but shield not active - APPLYING NOW!")
                        store.shield.applications = selectedApplications
                        store.shield.applicationCategories = nil
                        isShieldActive = true
                        saveLockedApps()
                    }
                } else {
                    // Still unlocked - shield MUST be off
                    if isShieldActive || store.shield.applications != nil {
                        debugPrint("🔓 CRITICAL: Still unlocked but shield active - REMOVING NOW!")
                        store.shield.applications = nil
                        store.shield.applicationCategories = nil
                        isShieldActive = false
                        saveLockedApps()
                    }
                }
            } else {
                // No unlock time - if shield should be active, ensure it is
                if isShieldActive && store.shield.applications != selectedApplications {
                    debugPrint("🔒 CRITICAL: Shield should be active but not set - APPLYING NOW!")
                    store.shield.applications = selectedApplications
                    store.shield.applicationCategories = nil
                    saveLockedApps()
                }
            }
        }
        #endif
    }
    
    private func startContinuousChecking() {
        // Check every 1 second if shield needs to be applied
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkAndApplyShieldIfNeeded()
        }
        // Add to all run loop modes to keep it alive
        if let timer = checkTimer {
            RunLoop.main.add(timer, forMode: .common)
            RunLoop.main.add(timer, forMode: .tracking)
            RunLoop.main.add(timer, forMode: .default)
        }
        debugPrint("⏰ Started continuous shield checking (every 1 second) - AUTO LOCK ACTIVE!")
    }
    
    
    deinit {
        checkTimer?.invalidate()
        backgroundTimer?.invalidate()
        endBackgroundShieldTask()
    }
    
    // Public so AppDelegate can call it from background tasks
    func checkAndApplyShieldIfNeeded() {
        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *), !selectedApplications.isEmpty {
            // Check if there's an unlock end time
            if let unlockEnd = defaults.object(forKey: unlockEndKey) as? Date {
                let now = Date()
                if now >= unlockEnd {
                    // 15 minutes expired - shield MUST be active
                    debugPrint("⏰⏰⏰ TIMER EXPIRED: 15 minutes passed - APPLYING shield NOW!")
                    debugPrint("⏰ Expired at: \(unlockEnd), Current: \(now)")
                    
                    store.shield.applications = selectedApplications
                    store.shield.applicationCategories = nil
                    store.shield.webDomains = nil
                    isShieldActive = true
                    defaults.removeObject(forKey: unlockEndKey)
                    saveLockedApps()
                    
                    // Schedule reminder notifications to encourage user to do dhikr
                    NotificationManager.shared.scheduleLockedAppReminders()
                    
                    debugPrint("✅ Shield APPLIED - Apps are NOW LOCKED!")
                    
                    // Double-check to ensure shield is applied
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        guard let self = self else { return }
                        #if canImport(ManagedSettings)
                        if #available(iOS 16.0, *) {
                            if self.store.shield.applications != self.selectedApplications {
                                debugPrint("⚠️ Shield not set, reapplying...")
                                self.store.shield.applications = self.selectedApplications
                                self.store.shield.applicationCategories = nil
                                self.store.shield.webDomains = nil
                                self.isShieldActive = true
                                self.saveLockedApps()
                            }
                        }
                        #endif
                    }
                } else {
                    // Still in 15 minute unlock period - shield MUST be OFF
                    let remaining = Int(unlockEnd.timeIntervalSince(now))
                    if store.shield.applications != nil {
                        let minutes = remaining / 60
                        let seconds = remaining % 60
                        debugPrint("⏰ Still unlocked for \(minutes)m \(seconds)s - shield should be off")
                        // Shield is already removed, but ensure it stays off
                    }
                }
            } else {
                // No unlock time - shield MUST be active
                if store.shield.applications != selectedApplications {
                    debugPrint("🔒 No unlock session - applying shield")
                    store.shield.applications = selectedApplications
                    store.shield.applicationCategories = nil
                    store.shield.webDomains = nil
                    isShieldActive = true
                    saveLockedApps()
                    
                    // Schedule reminder notifications to encourage user to do dhikr
                    NotificationManager.shared.scheduleLockedAppReminders()
                    
                    debugPrint("✅ Shield ACTIVE - Apps locked")
                }
            }
        }
        #endif
    }
    
    private func loadLockedApps() {
        // Load shield active state
        isShieldActive = defaults.bool(forKey: shieldActiveKey)
        
        // Try to load saved FamilyActivitySelection
        #if canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            if let data = defaults.data(forKey: selectionKey) {
                do {
                    // Decode FamilyActivitySelection
                    let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
                    
                    // Extract apps and tokens
                    selectedApps = selection.applications
                    selectedApplications = selection.applicationTokens
                    
                    debugPrint("✅ Loaded \(selectedApplications.count) apps from storage")
                    debugPrint("📱 Apps loaded: \(selectedApplications)")
                    
                    // CRITICAL: Immediately apply shield if no unlock time or time expired
                    if !selectedApplications.isEmpty {
                        if let unlockEnd = defaults.object(forKey: unlockEndKey) as? Date {
                            if Date() >= unlockEnd {
                                // Time expired - apply shield immediately
                                #if canImport(ManagedSettings)
                                store.shield.applications = selectedApplications
                                isShieldActive = true
                                debugPrint("🔒 Applied shield immediately after load (time expired)")
                                #endif
                            }
                        } else {
                            // No unlock time - apply shield by default
                            #if canImport(ManagedSettings)
                            store.shield.applications = selectedApplications
                            isShieldActive = true
                            debugPrint("🔒 Applied shield immediately after load (default)")
                            #endif
                        }
                    }
                } catch {
                    debugPrint("⚠️ Failed to decode selection: \(error)")
                }
            } else {
                debugPrint("⚠️ No saved selection found in storage")
            }
        }
        #endif
    }
    
    private func saveLockedApps() {
        // Save shield state
        defaults.set(isShieldActive, forKey: shieldActiveKey)
        
        // Save FamilyActivitySelection (this IS Codable!)
        #if canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            do {
                // Create FamilyActivitySelection from our current selection
                var selection = FamilyActivitySelection()
                selection.applicationTokens = selectedApplications
                
                // Encode and save
                let data = try JSONEncoder().encode(selection)
                defaults.set(data, forKey: selectionKey)
                
                debugPrint("💾 Saved \(selectedApplications.count) apps to storage")
            } catch {
                debugPrint("❌ Failed to encode selection: \(error)")
            }
        }
        #endif
    }

    func updateSelection(apps: Set<ApplicationToken>) {
        selectedApplications = apps
        saveLockedApps()
    }

    func updateSelection(apps: Set<Application>) {
        selectedApps = apps
        selectedApplications = Set(apps.compactMap { $0.token })
        debugPrint("📱 UPDATE SELECTION: \(selectedApplications.count) apps selected")
        saveLockedApps()
        
        // CRITICAL: Ensure shield is applied if it should be active
        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *), !selectedApplications.isEmpty {
            // If unlock time expired or no unlock time, apply shield immediately
            if let unlockEnd = defaults.object(forKey: unlockEndKey) as? Date {
                if Date() >= unlockEnd {
                    // Time expired - apply shield
                    store.shield.applications = selectedApplications
                    isShieldActive = true
                    saveLockedApps()
                    debugPrint("✅ Shield applied after selection update (time expired)")
                } else {
                    // Still unlocked - remove shield
                    store.shield.applications = nil
                    isShieldActive = false
                    saveLockedApps()
                    debugPrint("✅ Shield removed after selection update (still unlocked)")
                }
            } else {
                // No unlock time - apply shield by default
                store.shield.applications = selectedApplications
                isShieldActive = true
                saveLockedApps()
                debugPrint("✅ Shield applied after selection update (default)")
            }
        }
        #endif
    }

    func applyShield() {
        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *) {
            debugPrint("🔒 APPLYING Shield to \(selectedApplications.count) apps...")
            debugPrint("🔒 Apps to lock: \(selectedApplications)")
            
            // Apply the shield directly
            store.shield.applications = selectedApplications
            isShieldActive = true
            saveLockedApps()
            
            // Schedule reminder notifications to encourage user to do dhikr
            NotificationManager.shared.scheduleLockedAppReminders()
            
            debugPrint("✅ Shield SUCCESSFULLY APPLIED!")
            debugPrint("✅ isShieldActive = \(isShieldActive)")
            debugPrint("✅ Store applications count: \(store.shield.applications?.count ?? 0)")
        }
        #else
        isShieldActive = true
        saveLockedApps()
        // Schedule reminder notifications even in simulator
        NotificationManager.shared.scheduleLockedAppReminders()
        debugPrint("⚠️ ManagedSettings not available (simulator?), but marking as active")
        #endif
    }

    func removeShield() {
        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *) {
            debugPrint("🔓 REMOVING Shield from all apps...")
            store.shield.applications = nil
            isShieldActive = false
            saveLockedApps()
            
            // Cancel reminder notifications since apps are now unlocked
            NotificationManager.shared.cancelLockedAppReminders()
            
            debugPrint("✅ Shield SUCCESSFULLY REMOVED!")
        }
        #else
        isShieldActive = false
        saveLockedApps()
        // Cancel reminder notifications
        NotificationManager.shared.cancelLockedAppReminders()
        debugPrint("⚠️ ManagedSettings not available (simulator?), but marking as inactive")
        #endif
    }
    
    // Force check and reapply - call this regularly
    func forceCheckAndReapply() {
        checkAndApplyShieldIfNeeded()
    }
    
    // CRITICAL: Force apply shield when unlock time expires (called by notification)
    func forceApplyShieldOnExpiry() {
        debugPrint("🔒🔒🔒 FORCE APPLY SHIELD ON EXPIRY CALLED 🔒🔒🔒")
        
        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *), !selectedApplications.isEmpty {
            // Check if unlock time has expired
            if let unlockEnd = defaults.object(forKey: unlockEndKey) as? Date {
                let now = Date()
                if now >= unlockEnd {
                    debugPrint("⏰ CONFIRMED: Unlock time expired - FORCING shield application")
                    debugPrint("⏰ Expired at: \(unlockEnd), Current: \(now)")
                    
                    // FORCE APPLY - Multiple attempts to ensure it sticks
                    store.shield.applications = selectedApplications
                    store.shield.applicationCategories = nil
                    store.shield.webDomains = nil
                    isShieldActive = true
                    
                    // Clear unlock time
                    defaults.removeObject(forKey: unlockEndKey)
                    saveLockedApps()
                    
                    // Schedule reminder notifications to encourage user to do dhikr
                    NotificationManager.shared.scheduleLockedAppReminders()
                    
                    debugPrint("✅ Shield FORCE APPLIED - Attempt 1")
                    debugPrint("✅ Shield applications: \(store.shield.applications?.count ?? 0)")
                    
                    // Retry after short delay to ensure it sticks (iOS sometimes needs this)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        guard let self = self else { return }
                        #if canImport(ManagedSettings)
                        if #available(iOS 16.0, *) {
                            self.store.shield.applications = self.selectedApplications
                            self.store.shield.applicationCategories = nil
                            self.store.shield.webDomains = nil
                            self.isShieldActive = true
                            self.saveLockedApps()
                            debugPrint("✅ Shield FORCE APPLIED - Attempt 2 (retry)")
                        }
                        #endif
                    }
                    
                    // Final retry after longer delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        guard let self = self else { return }
                        #if canImport(ManagedSettings)
                        if #available(iOS 16.0, *) {
                            if self.store.shield.applications != self.selectedApplications {
                                debugPrint("⚠️ WARNING: Shield still not set after 1s, final retry...")
                                self.store.shield.applications = self.selectedApplications
                                self.store.shield.applicationCategories = nil
                                self.store.shield.webDomains = nil
                                self.isShieldActive = true
                                self.saveLockedApps()
                                debugPrint("✅ Shield FORCE APPLIED - Attempt 3 (final retry)")
                            } else {
                                debugPrint("✅ Shield confirmed active after retry")
                            }
                        }
                        #endif
                    }
                } else {
                    let remaining = Int(unlockEnd.timeIntervalSince(now))
                    debugPrint("⏰ Unlock time NOT expired yet - \(remaining) seconds remaining")
                }
            } else {
                // No unlock time - shield should be active by default
                debugPrint("🔒 No unlock time found - applying shield by default")
                store.shield.applications = selectedApplications
                store.shield.applicationCategories = nil
                store.shield.webDomains = nil
                isShieldActive = true
                saveLockedApps()
                debugPrint("✅ Shield applied (default)")
            }
        } else {
            debugPrint("⚠️ Cannot apply shield: No selected applications")
        }
        #endif
    }
    
    // MARK: - Unlock Time Management
    
    func setUnlockEndTime(_ date: Date) {
        defaults.set(date, forKey: unlockEndKey)
        debugPrint("⏰ Set unlock end time to: \(date)")
        debugPrint("📱 Notification will remind user to open app after 15 minutes")
    }
    
    // DeviceActivitySchedule removed - using simple notification approach
    // User gets notification after 15 minutes and must open app to lock
    
    func clearUnlockEndTime() {
        defaults.removeObject(forKey: unlockEndKey)
        debugPrint("⏰ Cleared unlock end time")
    }
    
    func getUnlockEndTime() -> Date? {
        return defaults.object(forKey: unlockEndKey) as? Date
    }
}


