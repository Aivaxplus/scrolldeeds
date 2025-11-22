//
//  DeviceActivityMonitorExtension.swift
//  ScrollDeedsMonitor
//
//  This extension is automatically called by iOS when a DeviceActivitySchedule ends.
//  It applies the shield automatically, even when the app is closed!
//

import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    // This is called when the schedule starts
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        debugPrint("📱 DeviceActivityMonitor: Interval started for \(activity)")
    }
    
    // This is called when the schedule ends - THIS IS WHERE WE APPLY THE SHIELD!
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        debugPrint("🔒🔒🔒 DeviceActivityMonitor: Interval ENDED - APPLYING SHIELD NOW! 🔒🔒🔒")
        
        // Load saved app selection from App Groups
        let defaults = UserDefaults(suiteName: "group.com.scrolldeeds.app")
        guard let data = defaults?.data(forKey: "familyActivitySelection") else {
            debugPrint("⚠️ No saved selection found in App Groups")
            return
        }
        
        do {
            // Decode FamilyActivitySelection
            let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            
            guard !selection.applicationTokens.isEmpty else {
                debugPrint("⚠️ No apps in selection")
                return
            }
            
            // Apply shield using ManagedSettingsStore (same name as main app!)
            let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("scrolldeeds.shield"))
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
            
            // Clear unlock time
            defaults?.removeObject(forKey: "unlockEndTime")
            
            debugPrint("✅✅✅ SHIELD APPLIED AUTOMATICALLY by DeviceActivityMonitor!")
            debugPrint("✅ Applied to \(selection.applicationTokens.count) apps")
            debugPrint("✅ This works even when the app is closed!")
        } catch {
            debugPrint("❌ Failed to apply shield: \(error)")
        }
    }
    
    // This is called periodically while the schedule is active
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        debugPrint("📊 DeviceActivityMonitor: Event reached threshold")
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
