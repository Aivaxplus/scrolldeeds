//
//  scrolldeedsApp.swift
//  scrolldeeds
//
//  Created by Sabri El makhoukhi on 30/10/2025.
//

import SwiftUI
import BackgroundTasks

@main
struct scrolldeedsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// AppDelegate to handle notifications and background tasks
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Ensure ShieldManager is initialized
        _ = ShieldManager.shared
        
        // Register background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.scrolldeeds.app.shieldCheck", using: nil) { task in
            self.handleShieldCheckTask(task: task as! BGProcessingTask)
        }
        
        return true
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
        
        // Set expiration handler
        task.expirationHandler = {
            debugPrint("⚠️ BGTask expired")
            task.setTaskCompleted(success: false)
        }
        
        // CRITICAL: Force apply shield - this runs even when app is completely closed!
        debugPrint("⏰⏰⏰ FORCING shield application from background task!")
        ShieldManager.shared.forceApplyShieldOnExpiry()
        ShieldManager.shared.checkAndApplyShieldIfNeeded()
        
        // Verify shield was applied
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ShieldManager.shared.forceApplyShieldOnExpiry() // Double-check
            task.setTaskCompleted(success: true)
            debugPrint("✅ BGTask completed - shield should be applied")
        }
    }
    
    // Handle notification when app is in background
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Check if this is a shield application notification
        if userInfo["apply_shield"] as? Bool == true {
            ShieldManager.shared.forceApplyShieldOnExpiry()
        }
        completionHandler(.newData)
    }
    
    // Called when app enters background - schedule background task
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Check if there's an active unlock timer
        if let unlockEnd = UserDefaults.standard.object(forKey: "unlockEndTime") as? Date {
            let now = Date()
            if now < unlockEnd {
                // Timer still running - schedule BGTask for when it expires
                let request = BGProcessingTaskRequest(identifier: "com.scrolldeeds.app.shieldCheck")
                request.requiresNetworkConnectivity = false
                request.requiresExternalPower = false
                request.earliestBeginDate = unlockEnd // Run exactly when timer expires
                
                do {
                    try BGTaskScheduler.shared.submit(request)
                    debugPrint("✅ BGTask scheduled for timer expiry: \(unlockEnd)")
                } catch {
                    debugPrint("❌ Failed to schedule BGTask: \(error)")
                }
            } else {
                // Timer already expired - apply shield immediately
                ShieldManager.shared.forceApplyShieldOnExpiry()
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
