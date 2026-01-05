//
//  RevenueCatDelegate.swift
//  scrolldeeds
//
//  Handles RevenueCat delegate callbacks for customer info updates
//

import Foundation
import RevenueCat

class RevenueCatDelegate: NSObject, PurchasesDelegate {
    static let shared = RevenueCatDelegate()
    
    private override init() {
        super.init()
    }
    
    // Called when customer info is updated (e.g., after purchase, restore, etc.)
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            // Update subscription status
            SubscriptionManager.shared.checkPremiumStatus()
            debugPrint("🔄 RevenueCat: Customer info updated")
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

