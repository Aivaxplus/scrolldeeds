//
//  MetaEventsManager.swift
//  scrolldeeds
//
//  Meta (Facebook) App Events — install attribution + conversion tracking for ads.
//

import Foundation
import FacebookCore
import RevenueCat

final class MetaEventsManager {
    static let shared = MetaEventsManager()

    private init() {}

    /// Sync ATT status, anonymous user id, then activate app session (call before `activateApp`).
    func prepareSession() {
        TrackingPermissionManager.syncAdvertiserTrackingEnabled()
        AppEvents.shared.userID = UserDataManager.shared.userID
    }

    // MARK: - Funnel

    func trackOnboardingCompleted() {
        AppEvents.shared.logEvent(
            .completedRegistration,
            parameters: [
                .registrationMethod: "onboarding"
            ]
        )
        flush()
    }

    func trackPaywallViewed() {
        AppEvents.shared.logEvent(
            .viewedContent,
            parameters: [
                .contentType: "paywall"
            ]
        )
        flush()
    }

    func trackInitiatedCheckout(productId: String, plan: String) {
        AppEvents.shared.logEvent(
            .initiatedCheckout,
            parameters: [
                .contentID: productId,
                .contentType: plan
            ]
        )
        flush()
    }

    /// Local 3-day app trial (not a StoreKit purchase).
    func trackAppTrialStarted(plan: String = "app_free_trial_3d") {
        AppEvents.shared.logEvent(
            .startTrial,
            parameters: [
                .contentID: plan,
                .contentType: "subscription"
            ]
        )
        flush()
    }

    // MARK: - Revenue

    func trackPurchase(package: Package) {
        let product = package.storeProduct
        let amount = NSDecimalNumber(decimal: product.price).doubleValue
        let currency = product.currencyCode ?? "EUR"
        let productId = product.productIdentifier
        let plan = planLabel(for: package)

        let baseParams: [AppEvents.ParameterName: Any] = [
            .contentID: productId,
            .contentType: "subscription",
            .currency: currency
        ]

        let introIsFree = product.introductoryDiscount.map {
            NSDecimalNumber(decimal: $0.price).doubleValue == 0
        } ?? false

        if amount == 0 || introIsFree {
            AppEvents.shared.logEvent(.startTrial, parameters: baseParams)
        } else {
            AppEvents.shared.logEvent(.subscribe, valueToSum: amount, parameters: baseParams)
            AppEvents.shared.logPurchase(
                amount: amount,
                currency: currency,
                parameters: [
                    .contentID: productId,
                    .contentType: plan
                ]
            )
        }
        flush()
    }

    // MARK: - Helpers

    private func planLabel(for package: Package) -> String {
        switch package.packageType {
        case .weekly:
            return "weekly"
        case .monthly, .twoMonth, .threeMonth:
            return "monthly"
        case .annual, .sixMonth:
            return "yearly"
        default:
            return package.storeProduct.productIdentifier
        }
    }

    private func flush() {
        AppEvents.shared.flush()
    }
}

#if DEBUG
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#endif
