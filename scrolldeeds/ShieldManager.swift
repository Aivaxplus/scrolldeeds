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

    // Store selected app tokens and apps for UI (categories use tokens from FamilyActivitySelection)
    @Published var selectedApplications: Set<ApplicationToken> = []
    @Published var selectedCategoryTokens: Set<ActivityCategoryToken> = []
    @Published var selectedApps: Set<Application> = []
    @Published var isShieldActive: Bool = false
    
    /// True when something is selected to lock (individual apps and/or whole categories).
    var hasShieldTargets: Bool {
        !selectedApplications.isEmpty || !selectedCategoryTokens.isEmpty
    }
    
    /// For UI counts when showing “X selected” (apps + category picks).
    var pickerSelectionCount: Int {
        selectedApplications.count + selectedCategoryTokens.count
    }
    
    
    // Use App Groups for data sharing (if needed in future)
    private let defaults = UserDefaults(suiteName: "group.com.scrolldeeds.app") ?? UserDefaults.standard
    private let shieldActiveKey = "isShieldActive"
    private let shieldAppliedBuildKey = "shieldAppliedBuild.v5"
    private let selectionKey = "familyActivitySelection"
    private let unlockEndKey = "unlockEndTime"
    private let unlockGracePeriodUntilKey = "unlockGracePeriodUntil"
    private let lastUnlockCompletedAtKey = "lastUnlockCompletedAt"
    
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
        migrateLegacyUnlockEndTimeIfNeeded()
        debugPrint("🔒 ShieldManager init: Loaded \(selectedApplications.count) apps, shield active: \(isShieldActive)")

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

        // reconcile → NotificationManager / DeviceActivityManager → ShieldManager.shared.
        // That re-enters `static let shared` while it is still nil and crashes
        // (EXC_BREAKPOINT / dispatch_once) on the first launch after onboarding.
        DispatchQueue.main.async { [self] in
            self.checkAndApplyShieldIfNeeded()
            self.ensureShieldState()
            self.startContinuousChecking()
        }
    }
    
    @objc private func appDidBecomeActive() {
        // Stop background task since app is now active
        backgroundTimer?.invalidate()
        backgroundTimer = nil
        endBackgroundShieldTask()
        
        debugPrint("📱 App became active — reconciling shield state")
        reconcileShieldState()
        debugPrint("📱 App active - shield check complete. Shield active: \(isShieldActive)")
    }
    
    @objc private func appWillResignActive() {
        debugPrint("📱 ScrollDeeds going to background")
        reconcileShieldState(notifyReminders: false)
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
                    if #available(iOS 16.0, *), self.hasShieldTargets {
                        self.applyPersistedSelectionToShieldStore()
                        self.isShieldActive = true
                        self.defaults.removeObject(forKey: self.unlockEndKey)
                        self.saveLockedApps()
                        debugPrint("✅✅✅ SHIELD APPLIED IN BACKGROUND - Apps are now LOCKED! ✅✅✅")
                        
                        // Verify it was applied
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.applyPersistedSelectionToShieldStore()
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
                if #available(iOS 16.0, *), self.hasShieldTargets {
                    self.applyPersistedSelectionToShieldStore()
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
        reconcileShieldState(notifyReminders: false)
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
        reconcileShieldState()
    }
    
    /// True when the user still has an active unlock session (grace window, 24h cap, and/or usage budget).
    /// A leftover DeviceActivity flag after weeks away must not keep this true forever —
    /// that blocked a new deed and made the dashboard look already unlocked.
    func hasActiveUnlockSession() -> Bool {
        if isInUnlockGracePeriod() {
            return true
        }
        if let unlockEnd = getUnlockEndTime() {
            return unlockEnd > Date()
        }
        if #available(iOS 16.0, *) {
            // Cap missing (crash mid-unlock): honor monitoring only within 24h of session start.
            if DeviceActivityManager.shared.isMonitoring,
               let start = DeviceActivityManager.shared.sessionStartDate,
               Date().timeIntervalSince(start) < 24 * 60 * 60 {
                return true
            }
        }
        return false
    }
    
    /// True during the post-deed grace window — prevents false auto-lock right after unlock.
    func isInUnlockGracePeriod() -> Bool {
        guard let graceEnd = defaults.object(forKey: unlockGracePeriodUntilKey) as? Date else { return false }
        return graceEnd > Date()
    }
    
    /// Atomically start an unlock session after a completed good deed.
    @discardableResult
    func completeUnlockSession(minutesEarned: Int) -> Bool {
        guard minutesEarned > 0 else { return false }
        let now = Date()
        let hardCapEnd = now.addingTimeInterval(24 * 60 * 60)
        // Short grace only — absorbs false DeviceActivity callbacks right after unlock.
        // MUST end before the real usage budget, or the true threshold is swallowed
        // (e.g. 15-min unlock + 15-min grace → apps never auto-lock, no notification).
        let graceSeconds = min(3 * 60, TimeInterval(max(1, minutesEarned - 1) * 60))
        let graceEnd = now.addingTimeInterval(graceSeconds)
        
        defaults.set(now, forKey: lastUnlockCompletedAtKey)
        defaults.set(graceEnd, forKey: unlockGracePeriodUntilKey)
        setUnlockEndTime(hardCapEnd)
        
        if #available(iOS 16.0, *) {
            DeviceActivityManager.shared.persistBudgetBeforeMonitoring(minutes: minutesEarned)
        }
        
        removeShield()
        
        if #available(iOS 16.0, *) {
            DeviceActivityManager.shared.startUsageMonitoring(
                allowedMinutes: minutesEarned,
                extendExistingBudget: false
            )
        }
        
        isShieldActive = false
        saveLockedApps()
        defaults.synchronize()
        debugPrint("✅ Unlock session started — \(minutesEarned) min budget, grace until \(graceEnd)")
        return true
    }
    
    private var hasUnlockSessionMetadata: Bool {
        defaults.object(forKey: unlockEndKey) != nil
            || defaults.object(forKey: unlockGracePeriodUntilKey) != nil
            || defaults.object(forKey: lastUnlockCompletedAtKey) != nil
    }

    /// Clear all unlock-session metadata when intentionally locking.
    func clearUnlockSessionMetadata() {
        clearUnlockEndTime()
        defaults.removeObject(forKey: unlockGracePeriodUntilKey)
        defaults.removeObject(forKey: lastUnlockCompletedAtKey)
    }
    
    /// Single source of truth: align ManagedSettings shield, persisted flags, and notifications.
    func reconcileShieldState(notifyReminders: Bool = true) {
        #if canImport(ManagedSettings)
        guard #available(iOS 16.0, *), hasShieldTargets else { return }
        
        if hasActiveUnlockSession() {
            if isShieldActive || !managedShieldHasNoConfiguration() {
                debugPrint("🔓 Reconcile: active unlock — removing shield")
                clearShieldStoreOnly()
                isShieldActive = false
                saveLockedApps()
            }
            NotificationManager.shared.onAppsUnlocked()
            if #available(iOS 16.0, *) {
                DeviceActivityManager.shared.restartMonitoringIfNeeded()
            }
            return
        }
        
        // Session ended — clear all unlock metadata and stop monitoring.
        // Runs every second, so only touch state when a session actually left something behind.
        if hasUnlockSessionMetadata {
            clearUnlockSessionMetadata()
        }
        if #available(iOS 16.0, *), DeviceActivityManager.shared.isMonitoring {
            DeviceActivityManager.shared.stopMonitoring()
        }
        
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let shieldIsStale = defaults.string(forKey: shieldAppliedBuildKey) != build
        if shieldIsStale, !managedShieldHasNoConfiguration() {
            // iOS keeps rendering the shield it built earlier; re-setting the store after an update
            // makes it ask the shield extension again.
            clearShieldStoreOnly()
        }
        let needsApply = shieldIsStale || !isShieldActive || managedShieldHasNoConfiguration()
        if needsApply {
            debugPrint("🔒 Reconcile: no active unlock — applying shield")
            applyPersistedSelectionToShieldStore()
            isShieldActive = true
            defaults.set(build, forKey: shieldAppliedBuildKey)
            saveLockedApps()
        }
        if notifyReminders {
            NotificationManager.shared.onAppsLocked()
            NotificationManager.shared.scheduleLockedAppReminders()
        }
        #endif
    }
    
    #if canImport(ManagedSettings)
    /// Applies persisted app tokens and category tokens to `ManagedSettingsStore` (shield).
    @available(iOS 16.0, *)
    private func applyPersistedSelectionToShieldStore() {
        if selectedApplications.isEmpty {
            store.shield.applications = nil
        } else {
            store.shield.applications = selectedApplications
        }
        if selectedCategoryTokens.isEmpty {
            store.shield.applicationCategories = nil
        } else {
            store.shield.applicationCategories = .specific(selectedCategoryTokens)
        }
        store.shield.webDomains = nil
    }
    
    @available(iOS 16.0, *)
    private func clearShieldStoreOnly() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
    
    /// Whether the managed shield has nothing applied (apps and categories).
    @available(iOS 16.0, *)
    private func managedShieldHasNoConfiguration() -> Bool {
        store.shield.applications == nil && store.shield.applicationCategories == nil
    }
    #endif
    
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
                    selectedCategoryTokens = selection.categoryTokens
                    
                    debugPrint("✅ Loaded \(selectedApplications.count) app tokens, \(selectedCategoryTokens.count) categories from storage")
                    
                    // CRITICAL: Immediately apply shield if no unlock time or time expired
                    if hasShieldTargets {
                        if let unlockEnd = defaults.object(forKey: unlockEndKey) as? Date {
                            if Date() >= unlockEnd {
                                // Time expired - apply shield immediately
                                #if canImport(ManagedSettings) && canImport(FamilyControls)
                                if #available(iOS 16.0, *) {
                                    applyPersistedSelectionToShieldStore()
                                    isShieldActive = true
                                    debugPrint("🔒 Applied shield immediately after load (time expired)")
                                }
                                #endif
                            } else {
                                // Still unlocked — ensure flag and store match
                                #if canImport(ManagedSettings) && canImport(FamilyControls)
                                if #available(iOS 16.0, *) {
                                    clearShieldStoreOnly()
                                    isShieldActive = false
                                    debugPrint("🔓 Loaded unlock session — shield cleared")
                                }
                                #endif
                            }
                        } else if !hasActiveUnlockSession() {
                            // No unlock time - apply shield by default
                            #if canImport(ManagedSettings) && canImport(FamilyControls)
                            if #available(iOS 16.0, *) {
                                applyPersistedSelectionToShieldStore()
                                isShieldActive = true
                                debugPrint("🔒 Applied shield immediately after load (default)")
                            }
                            #endif
                        } else {
                            #if canImport(ManagedSettings) && canImport(FamilyControls)
                            if #available(iOS 16.0, *) {
                                clearShieldStoreOnly()
                                isShieldActive = false
                                debugPrint("🔓 Loaded usage-budget unlock — shield cleared")
                            }
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
                selection.categoryTokens = selectedCategoryTokens
                
                // Encode and save
                let data = try JSONEncoder().encode(selection)
                defaults.set(data, forKey: selectionKey)
                
                debugPrint("💾 Saved \(selectedApplications.count) app tokens, \(selectedCategoryTokens.count) categories")
            } catch {
                debugPrint("❌ Failed to encode selection: \(error)")
            }
        }
        #endif
    }

    func updateSelection(apps: Set<ApplicationToken>) {
        var wrapped = FamilyActivitySelection()
        wrapped.applicationTokens = apps
        if #available(iOS 16.0, *) {
            updateSelection(from: wrapped)
        } else {
            selectedApplications = apps
            saveLockedApps()
        }
    }

    func updateSelection(apps: Set<Application>) {
        var wrapped = FamilyActivitySelection()
        wrapped.applicationTokens = Set(apps.compactMap { $0.token })
        if #available(iOS 16.0, *) {
            updateSelection(from: wrapped)
            selectedApps = apps
            saveLockedApps()
        } else {
            selectedApps = apps
            selectedApplications = wrapped.applicationTokens
            saveLockedApps()
        }
    }
    
    /// The picker binding starts empty. Seed it from the saved lock so Cancel
    /// does not look like “the user removed every app”.
    @available(iOS 16.0, *)
    func currentFamilySelection() -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()
        #if canImport(FamilyControls)
        selection.applicationTokens = selectedApplications
        selection.categoryTokens = selectedCategoryTokens
        #endif
        return selection
    }

    /// Ignore a dismiss that would wipe an existing lock with an empty selection.
    @available(iOS 16.0, *)
    func commitPickerSelection(_ selection: FamilyActivitySelection) {
        #if canImport(FamilyControls)
        let empty = selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty
        if empty && hasShieldTargets {
            debugPrint("⚠️ Picker dismissed empty — keeping the current lock")
            return
        }
        updateSelection(from: selection)
        #endif
    }

    /// Full picker output: preserves **all** app tokens and **category** tokens (required for “whole category” / multi-app picks).
    @available(iOS 16.0, *)
    func updateSelection(from selection: FamilyActivitySelection) {
        #if canImport(FamilyControls)
        selectedApps = selection.applications
        selectedApplications = selection.applicationTokens
        selectedCategoryTokens = selection.categoryTokens
        
        debugPrint("📱 UPDATE SELECTION (full picker): \(selectedApplications.count) app tokens, \(selectedCategoryTokens.count) categories")
        saveLockedApps()
        
        #if canImport(ManagedSettings)
        guard hasShieldTargets else {
            clearShieldStoreOnly()
            isShieldActive = false
            saveLockedApps()
            debugPrint("✅ Selection cleared — shield cleared")
            return
        }
        
        if let unlockEnd = defaults.object(forKey: unlockEndKey) as? Date {
            if Date() >= unlockEnd {
                applyPersistedSelectionToShieldStore()
                isShieldActive = true
                saveLockedApps()
                debugPrint("✅ Shield applied after selection update (time expired)")
            } else {
                clearShieldStoreOnly()
                isShieldActive = false
                saveLockedApps()
                debugPrint("✅ Shield removed after selection update (still unlocked)")
            }
        } else {
            applyPersistedSelectionToShieldStore()
            isShieldActive = true
            saveLockedApps()
            debugPrint("✅ Shield applied after selection update (default)")
        }
        #endif
        #endif
    }

    func applyShield() {
        // Stop DeviceActivity usage monitoring when locking (extension may have already done this)
        clearUnlockSessionMetadata()
        if #available(iOS 16.0, *) {
            DeviceActivityManager.shared.stopMonitoring()
        }

        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *) {
            debugPrint("🔒 APPLYING Shield — \(selectedApplications.count) app tokens, \(selectedCategoryTokens.count) categories")

            guard hasShieldTargets else {
                debugPrint("⚠️ applyShield: nothing selected")
                return
            }
            applyPersistedSelectionToShieldStore()
            isShieldActive = true
            saveLockedApps()

            if !hasActiveUnlockSession() {
                NotificationManager.shared.onAppsLocked()
                NotificationManager.shared.scheduleLockedAppReminders()
            }

            debugPrint("✅ Shield APPLIED — isShieldActive = \(isShieldActive)")
        }
        #else
        isShieldActive = true
        saveLockedApps()
        if !hasActiveUnlockSession() {
            NotificationManager.shared.onAppsLocked()
            NotificationManager.shared.scheduleLockedAppReminders()
        }
        debugPrint("⚠️ ManagedSettings not available (simulator?), but marking as active")
        #endif
    }

    func removeShield() {
        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *) {
            debugPrint("🔓 REMOVING Shield from all apps and categories...")
            clearShieldStoreOnly()
            isShieldActive = false
            saveLockedApps()
            
            NotificationManager.shared.onAppsUnlocked()
            
            debugPrint("✅ Shield SUCCESSFULLY REMOVED!")
        }
        #else
        isShieldActive = false
        saveLockedApps()
        NotificationManager.shared.onAppsUnlocked()
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
        
        if hasActiveUnlockSession() {
            debugPrint("⏳ Ignoring stale expiry — unlock session still active")
            NotificationManager.shared.onAppsUnlocked()
            reconcileShieldState(notifyReminders: false)
            return
        }
        
        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *), hasShieldTargets {
            debugPrint("⏰ CONFIRMED: No active unlock — forcing shield application")
            applyPersistedSelectionToShieldStore()
            isShieldActive = true
            clearUnlockSessionMetadata()
            saveLockedApps()
            if !hasActiveUnlockSession() {
                NotificationManager.shared.onAppsLocked()
                NotificationManager.shared.scheduleLockedAppReminders()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                #if canImport(ManagedSettings)
                if #available(iOS 16.0, *) {
                    self.applyPersistedSelectionToShieldStore()
                    self.isShieldActive = true
                    self.saveLockedApps()
                }
                #endif
            }
        } else {
            debugPrint("⚠️ Cannot apply shield: No selection (apps or categories)")
        }
        #endif
    }
    
    /// ContentView used to save only `UserDefaults.standard` key `unlockEndsAt` (Double) while the shield
    /// timer reads `unlockEndTime` in the shared defaults — subscribers saw unlock UI but the shield kept re-applying.
    private func migrateLegacyUnlockEndTimeIfNeeded() {
        if defaults.object(forKey: unlockEndKey) as? Date != nil { return }
        if let ts = UserDefaults.standard.object(forKey: "unlockEndsAt") as? Double {
            let date = Date(timeIntervalSince1970: ts)
            if date > Date() {
                defaults.set(date, forKey: unlockEndKey)
                debugPrint("✅ Migrated legacy unlockEndsAt → shared unlockEndTime")
            }
            UserDefaults.standard.removeObject(forKey: "unlockEndsAt")
            return
        }
        if let date = UserDefaults.standard.object(forKey: "unlockEndTime") as? Date {
            if date > Date() {
                defaults.set(date, forKey: unlockEndKey)
                debugPrint("✅ Migrated legacy standard unlockEndTime → shared unlockEndTime")
            }
            UserDefaults.standard.removeObject(forKey: "unlockEndTime")
        }
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
    
    func getUnlockGracePeriodEnd() -> Date? {
        defaults.object(forKey: unlockGracePeriodUntilKey) as? Date
    }
}
