//
//  TrackingPermissionManager.swift
//  scrolldeeds
//
//  App Tracking Transparency — required for Meta App Events on iOS 14+.
//

import AppTrackingTransparency

enum TrackingPermissionManager {
    private static var hasStartedRequest = false

    /// FBSDK v17+ reads `ATTrackingManager.trackingAuthorizationStatus` automatically (iOS 17+).
    /// No manual `isAdvertiserTrackingEnabled` setter needed.
    static func syncAdvertiserTrackingEnabled() {
        guard #available(iOS 14, *) else { return }
        #if DEBUG
        let authorized = ATTrackingManager.trackingAuthorizationStatus == .authorized
        debugPrint("📊 Meta ATT authorized: \(authorized)")
        #endif
    }

    /// Requests the ATT prompt once, then runs `completion` so Meta can read the final status.
    static func requestIfNeeded(completion: @escaping () -> Void) {
        guard #available(iOS 14, *) else {
            syncAdvertiserTrackingEnabled()
            completion()
            return
        }

        let status = ATTrackingManager.trackingAuthorizationStatus
        guard status == .notDetermined else {
            syncAdvertiserTrackingEnabled()
            completion()
            return
        }

        guard !hasStartedRequest else {
            syncAdvertiserTrackingEnabled()
            completion()
            return
        }
        hasStartedRequest = true

        // Brief delay so the prompt appears after the first screen is visible.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { newStatus in
                #if DEBUG
                debugPrint("📊 ATT status: \(newStatus.rawValue)")
                #endif
                DispatchQueue.main.async {
                    syncAdvertiserTrackingEnabled()
                    completion()
                }
            }
        }
    }
}

#if DEBUG
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#endif
