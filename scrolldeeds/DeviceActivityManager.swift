//
//  DeviceActivityManager.swift
//  scrolldeeds
//
//  Manages DeviceActivity-based usage monitoring.
//  Instead of a wall-clock timer, this tracks ACTUAL screen time spent on the
//  selected apps and triggers auto-lock via the DeviceActivityMonitorExtension
//  when the earned usage budget is consumed — even when the main app is closed.
//
//  Intermediate progress events (every 5 minutes) write spent minutes into the
//  App Group so the heart can darken as real usage accumulates. Only the final
//  threshold event locks apps — lock behaviour is unchanged.
//

import Foundation

#if canImport(DeviceActivity)
import DeviceActivity
#endif

#if canImport(FamilyControls)
import FamilyControls
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif

// MARK: - Debug Helper
#if DEBUG
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#else
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#endif

@available(iOS 16.0, *)
final class DeviceActivityManager {
    static let shared = DeviceActivityManager()

    #if canImport(DeviceActivity)
    private let center = DeviceActivityCenter()
    #endif

    private let defaults = UserDefaults(suiteName: "group.com.scrolldeeds.app") ?? UserDefaults.standard

    // Keys shared with the DeviceActivityMonitorExtension via App Group
    static let activityName = DeviceActivityName("scrolldeeds.usage.session")
    static let eventName    = DeviceActivityEvent.Name("scrolldeeds.usage.threshold")
    static let progressEventPrefix = "scrolldeeds.usage.progress."

    private let allowedMinutesKey  = "deviceActivityAllowedMinutes"
    private let sessionStartKey    = "deviceActivitySessionStart"
    private let needsRestartKey    = "deviceActivityNeedsRestart"
    private let spentMinutesKey    = "deviceActivitySpentMinutes"

    /// How often the extension reports monitored usage for the heart (minutes).
    private let progressStepMinutes = 5

    private init() {}

    // MARK: - Public API

    /// Zero spent minutes and store the new budget before hearts are published.
    /// Buying or refilling must not inherit the previous session's usage.
    func prepareFreshBudget(minutes: Int) {
        guard minutes > 0 else { return }
        defaults.set(minutes, forKey: allowedMinutesKey)
        defaults.set(0, forKey: spentMinutesKey)
    }

    /// Persist budget in shared storage BEFORE touching the framework so unlock state survives start failures.
    func persistBudgetBeforeMonitoring(minutes: Int) {
        guard minutes > 0 else { return }
        defaults.set(minutes, forKey: allowedMinutesKey)
        defaults.set(Date(), forKey: sessionStartKey)
        defaults.set(0, forKey: spentMinutesKey)
    }

    /// Start monitoring actual screen time on the selected apps.
    func startUsageMonitoring(allowedMinutes: Int, extendExistingBudget: Bool = false) {
        let priorCap: Int = {
            guard extendExistingBudget,
                  defaults.object(forKey: allowedMinutesKey) != nil else { return 0 }
            return max(0, defaults.integer(forKey: allowedMinutesKey))
        }()

        let totalMinutes = priorCap > 0 ? priorCap + allowedMinutes : allowedMinutes

        guard totalMinutes > 0 else {
            debugPrint("⚠️ DeviceActivityManager: total minutes is 0, skipping")
            return
        }

        #if canImport(FamilyControls) && canImport(DeviceActivity)
        guard let selectionData = defaults.data(forKey: "familyActivitySelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData),
              (!selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty) else {
            debugPrint("⚠️ DeviceActivityManager: No apps/categories selected, cannot start monitoring")
            return
        }
        #endif

        // Persist only once we know there is something to watch. Otherwise a
        // failed start would zero spent minutes and look like a fresh unlock.
        persistBudgetBeforeMonitoring(minutes: totalMinutes)
        defaults.removeObject(forKey: needsRestartKey)

        #if canImport(FamilyControls) && canImport(DeviceActivity)

        // Stop prior session without clearing persisted budget keys.
        stopMonitoringFrameworkOnly()

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0,  minute: 0),
            intervalEnd:   DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let events = makeEvents(
            totalMinutes: totalMinutes,
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens
        )

        do {
            try center.startMonitoring(
                Self.activityName,
                during: schedule,
                events: events
            )
            let stackNote = priorCap > 0 ? " (stacked \(priorCap) + \(allowedMinutes))" : ""
            debugPrint("✅ DeviceActivityManager: Monitoring started — \(totalMinutes) min budget, \(events.count) event(s)\(stackNote)")
        } catch {
            debugPrint("❌ DeviceActivityManager: Failed to start monitoring: \(error) — budget kept in storage")
        }
        #else
        debugPrint("⚠️ DeviceActivityManager: DeviceActivity/FamilyControls not available (simulator?)")
        #endif
    }

    /// Re-start monitoring after the extension skipped a false threshold during the unlock grace window.
    func restartMonitoringIfNeeded() {
        guard defaults.bool(forKey: needsRestartKey) else { return }
        if let grace = defaults.object(forKey: "unlockGracePeriodUntil") as? Date, grace > Date() {
            return
        }
        let budget = defaults.integer(forKey: allowedMinutesKey)
        let spent = defaults.integer(forKey: spentMinutesKey)
        let remaining = max(0, budget - spent)
        guard remaining > 0 else {
            defaults.removeObject(forKey: needsRestartKey)
            return
        }
        guard ShieldManager.shared.hasActiveUnlockSession() else {
            defaults.removeObject(forKey: needsRestartKey)
            return
        }
        debugPrint("🔄 DeviceActivityManager: Restarting monitoring after grace-period skip — \(remaining) min left")
        defaults.removeObject(forKey: needsRestartKey)
        startUsageMonitoring(allowedMinutes: remaining, extendExistingBudget: false)
    }

    /// Stop monitoring and clear session keys (called when apps are manually locked or session ends).
    /// Commits real spent minutes into today's heart scroll total before clearing.
    func stopMonitoring() {
        let spent = spentMinutes
        let allowed = allowedMinutes
        let start = sessionStartDate
        UserDataManager.commitSessionScrollInAppGroup(
            spentMinutes: spent,
            allowedMinutes: allowed,
            sessionStart: start,
            treatAsFullBudget: false
        )
        UserDataManager.shared.mergeScrollMinutesFromAppGroup()

        stopMonitoringFrameworkOnly()
        defaults.removeObject(forKey: allowedMinutesKey)
        defaults.removeObject(forKey: sessionStartKey)
        defaults.removeObject(forKey: needsRestartKey)
        defaults.removeObject(forKey: spentMinutesKey)
        debugPrint("⏹ DeviceActivityManager: Monitoring stopped (committed \(spent) scroll min)")
    }

    private func stopMonitoringFrameworkOnly() {
        #if canImport(DeviceActivity)
        center.stopMonitoring([Self.activityName])
        #endif
    }

    // MARK: - Event construction

    #if canImport(DeviceActivity) && canImport(FamilyControls)
    private func makeEvents(
        totalMinutes: Int,
        applications: Set<ApplicationToken>,
        categories: Set<ActivityCategoryToken>,
        webDomains: Set<WebDomainToken>
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        // Intermediate milestones — report real monitored usage without locking.
        var minute = progressStepMinutes
        while minute < totalMinutes {
            let name = DeviceActivityEvent.Name("\(Self.progressEventPrefix)\(minute)")
            events[name] = makeEvent(
                thresholdMinutes: minute,
                applications: applications,
                categories: categories,
                webDomains: webDomains
            )
            minute += progressStepMinutes
        }

        // Final threshold — this is what locks the apps.
        events[Self.eventName] = makeEvent(
            thresholdMinutes: totalMinutes,
            applications: applications,
            categories: categories,
            webDomains: webDomains
        )
        return events
    }

    private func makeEvent(
        thresholdMinutes: Int,
        applications: Set<ApplicationToken>,
        categories: Set<ActivityCategoryToken>,
        webDomains: Set<WebDomainToken>
    ) -> DeviceActivityEvent {
        if #available(iOS 17.4, *) {
            return DeviceActivityEvent(
                applications: applications,
                categories: categories,
                webDomains: webDomains,
                threshold: DateComponents(minute: thresholdMinutes),
                includesPastActivity: false
            )
        } else {
            return DeviceActivityEvent(
                applications: applications,
                categories: categories,
                webDomains: webDomains,
                threshold: DateComponents(minute: thresholdMinutes)
            )
        }
    }
    #endif

    // MARK: - State Accessors

    var allowedMinutes: Int {
        defaults.integer(forKey: allowedMinutesKey)
    }

    var isMonitoring: Bool {
        defaults.object(forKey: allowedMinutesKey) != nil
    }

    var sessionStartDate: Date? {
        defaults.object(forKey: sessionStartKey) as? Date
    }

    /// Minutes of the current unlock budget that DeviceActivity has already
    /// reported as spent on the selected apps (via progress milestones).
    var spentMinutes: Int {
        max(0, defaults.integer(forKey: spentMinutesKey))
    }

    /// Written by the monitor extension when a progress milestone is reached.
    static func recordSpentMinutes(_ minutes: Int, defaults: UserDefaults? = nil) {
        let store = defaults ?? UserDefaults(suiteName: "group.com.scrolldeeds.app") ?? .standard
        let previous = store.integer(forKey: "deviceActivitySpentMinutes")
        let next = max(previous, minutes)
        store.set(next, forKey: "deviceActivitySpentMinutes")
    }
}
