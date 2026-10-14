//
//  SubscriptionManager.swift
//  scrolldeeds
//
//  Manages in-app purchases using RevenueCat
//

import Foundation
import RevenueCat
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPremium: Bool = false
    @Published var offerings: Offerings?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var customerInfo: CustomerInfo?
    
    private var cancellables = Set<AnyCancellable>()
    
    // Entitlement ID - moet overeenkomen met RevenueCat dashboard
    private let entitlementID = "Scrolldeeds Pro"
    
    private init() {
        // RevenueCat wordt geïnitialiseerd in scrolldeedsApp.swift
        // Hier luisteren we alleen naar updates
        setupListener()
        checkPremiumStatus()
        loadTrialStatus()
    }

    private func loadTrialStatus() {
        trialExpiryDate = UserDefaults.standard.object(forKey: "trialExpiryDate") as? Date
        if let expiry = trialExpiryDate {
            isTrialActive = Date() <= expiry
        } else {
            isTrialActive = false
        }
        recordLocalTrialLapseIfNeeded()
    }
    
    // MARK: - Setup Listener
    
    private func setupListener() {
        // Listen for customer info updates
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            Task { @MainActor in
                if let error = error {
                    debugPrint("❌ Error getting customer info: \(error)")
                } else {
                    self?.updatePremiumStatus(customerInfo: customerInfo)
                }
            }
        }
    }
    
    // MARK: - Customer Info
    
    /// Get current customer info
    func getCustomerInfo() async throws -> CustomerInfo {
        let customerInfo = try await Purchases.shared.customerInfo()
        await MainActor.run {
            self.customerInfo = customerInfo
        }
        return customerInfo
    }
    
    /// Get active subscriptions
    func getActiveSubscriptions() -> [String] {
        guard let customerInfo = customerInfo else { return [] }
        return Array(customerInfo.activeSubscriptions)
    }
    
    /// Get all purchased product identifiers
    func getAllPurchasedProductIdentifiers() -> [String] {
        guard let customerInfo = customerInfo else { return [] }
        return Array(customerInfo.allPurchasedProductIdentifiers)
    }
    
    /// Check if user has specific entitlement
    func hasEntitlement(_ entitlementID: String) -> Bool {
        guard let customerInfo = customerInfo else { return false }
        return customerInfo.entitlements[entitlementID]?.isActive == true
    }
    
    /// Get entitlement expiration date
    func getEntitlementExpirationDate(_ entitlementID: String) -> Date? {
        guard let customerInfo = customerInfo else { return nil }
        return customerInfo.entitlements[entitlementID]?.expirationDate
    }
    
    // MARK: - Load Offerings
    
    func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Force refresh from server (bypass cache)
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            
            debugPrint("✅ Loaded offerings: \(offerings.all.count) total offerings")
            if let current = offerings.current {
                debugPrint("📦 Current offering has \(current.availablePackages.count) packages:")
                for package in current.availablePackages {
                    debugPrint("  - \(package.identifier): \(package.storeProduct.productIdentifier)")
                }
            }
            let refId = ReferralManager.shared.offeringIdentifier
            if let ref = offerings.all[refId] {
                debugPrint("📦 Referral offering `\(refId)` has \(ref.availablePackages.count) packages:")
                for package in ref.availablePackages {
                    debugPrint("  - \(package.identifier): \(package.storeProduct.productIdentifier)")
                }
            } else if let fallback = offerings.all["referral_15"] {
                debugPrint("📦 Fallback offering `referral_15` has \(fallback.availablePackages.count) packages")
            } else {
                debugPrint("⚠️ No referral_15 offering found in RevenueCat")
            }
        } catch {
            errorMessage = "Failed to load offerings: \(error.localizedDescription)"
            debugPrint("❌ Error loading offerings: \(error)")
        }
    }
    
    /// Paywall packages for **yearly + monthly**: when a referral code is active, uses RevenueCat offering `referral_15` (e.g. App Store products `yearly_referral` & `monthly_referral`). Weekly is not discounted — use `standardPaywallOffering()` for that. If `referral_15` is missing, falls back to `current`.
    func resolvedPaywallOffering() -> Offering? {
        guard let offerings = offerings else { return nil }
        if ReferralManager.shared.hasActiveReferral {
            let id = ReferralManager.shared.offeringIdentifier
            if let referral = offerings.all[id] {
                return referral
            }
            debugPrint("⚠️ Referral active, but offering `\(id)` not found. Falling back to default offering.")
        }
        return offerings.current
    }

    /// Default storefront offering (`current`). Use for weekly / downsell while referral users buy discounted yearly & monthly from `resolvedPaywallOffering()`.
    func standardPaywallOffering() -> Offering? {
        offerings?.current
    }

    /// Yearly + monthly without an intro offer. Used by the classic paywall when
    /// those packages actually attach to StoreKit. Empty offerings (typical when
    /// running from Xcode with `Products.storekit`) fall back to `current`.
    func referralPaywallOffering() -> Offering? {
        guard let offerings else { return nil }
        let id = ReferralManager.shared.offeringIdentifier
        if let referral = offerings.all[id], !referral.availablePackages.isEmpty {
            return referral
        }
        if let fallback = offerings.all["referral_15"], !fallback.availablePackages.isEmpty {
            return fallback
        }
        debugPrint("⚠️ referral offering empty or missing — falling back to current")
        return offerings.current
    }
    
    // MARK: - Purchase
    
    func purchase(_ package: Package) async throws {
        do {
            let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)

            if userCancelled {
                throw SubscriptionError.userCancelled
            }

            updatePremiumStatus(customerInfo: customerInfo)
            debugPrint("✅ Purchase successful: \(package.storeProduct.productIdentifier)")
            MetaEventsManager.shared.trackPurchase(package: package)

            // Send referral webhook only after confirmed payment and only if a
            // referral code was active (hasActiveReferral or influencer code).
            let referralManager = ReferralManager.shared
            if referralManager.hasActiveReferral || referralManager.hasInfluencerAccess {
                let plan: String
                switch package.packageType {
                case .weekly:                           plan = "weekly"
                case .monthly, .twoMonth, .threeMonth:  plan = "monthly"
                case .annual, .sixMonth:                plan = "yearly"
                default:                                plan = package.storeProduct.productIdentifier
                }
                referralManager.sendPurchaseWebhook(plan: plan)
                debugPrint("📤 Referral purchase webhook sent (plan: \(plan))")
            }
        } catch {
            if case SubscriptionError.userCancelled = error {
                throw error
            }
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updatePremiumStatus(customerInfo: customerInfo)
            debugPrint("✅ Purchases restored")
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            debugPrint("❌ Error restoring purchases: \(error)")
        }
    }
    
    // MARK: - Check Premium Status
    
    func checkPremiumStatus() {
        Task { await refreshPremiumStatus() }
    }

    /// Awaitable refresh so a long-idle launch can pick up a lapsed or restored subscription
    /// before the deed CTA decides to open practice vs paywall.
    @discardableResult
    func refreshPremiumStatus() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updatePremiumStatus(customerInfo: customerInfo)
        } catch {
            debugPrint("❌ Error checking premium status: \(error)")
        }
        recordLocalTrialLapseIfNeeded()
        return hasPremiumAccess
    }
    
    /// Premium access: active subscription, active 3-day app trial, or influencer access.
    var hasPremiumAccess: Bool {
        if ReferralManager.shared.hasInfluencerAccess {
            debugPrint("✅ User has premium access via INFLUENCER code")
            return true
        }
        if let expiry = trialExpiryDate, Date() <= expiry {
            debugPrint("✅ User has premium access via FREE TRIAL")
            return true
        }
        if trialExpiryDate != nil, let expiry = trialExpiryDate, Date() > expiry, !isPremium {
            debugPrint("🚫 Trial expired - user must subscribe to continue")
            return false
        }
        return isPremium
    }

    // MARK: - Local 3-day trial (app-side; complements Store intro offers)

    @Published var isTrialActive: Bool = false
    @Published var trialExpiryDate: Date?

    var hasTrialExpired: Bool {
        guard let expiryDate = trialExpiryDate else { return false }
        return Date() > expiryDate
    }

    /// The 3-day free trial may be granted only once per install. Persisted so an expired
    /// trial can never be re-granted (which would let users bypass the paywall forever).
    private let hasEverStartedTrialKey = "hasEverStartedTrial"

    var hasEverStartedTrial: Bool {
        UserDefaults.standard.bool(forKey: hasEverStartedTrialKey)
    }

    /// True only when the user has never used the trial and is not already premium.
    var canStartTrial: Bool {
        !hasEverStartedTrial && !isPremium
    }

    func startFreeTrial(durationDays: Int = 3) {
        // One-time only: never re-grant a trial (prevents bypassing the paywall after expiry).
        guard canStartTrial else {
            debugPrint("⛔️ startFreeTrial ignored — trial already used or user is premium")
            return
        }
        let expiryDate = Calendar.current.date(byAdding: .day, value: durationDays, to: Date()) ?? Date()
        trialExpiryDate = expiryDate
        isTrialActive = true
        UserDefaults.standard.set(expiryDate, forKey: "trialExpiryDate")
        UserDefaults.standard.set(true, forKey: "isTrialActive")
        UserDefaults.standard.set(true, forKey: hasEverStartedTrialKey)
        NotificationManager.shared.cancelLeaveAppNonSubscriberWinback()
        NotificationManager.shared.cancelPaywallLeaveConversionNudge()
        MetaEventsManager.shared.trackAppTrialStarted()
        debugPrint("✅ Free trial started, expires: \(expiryDate)")
    }

    private func clearLocalTrialState() {
        trialExpiryDate = nil
        isTrialActive = false
        UserDefaults.standard.removeObject(forKey: "trialExpiryDate")
        UserDefaults.standard.removeObject(forKey: "isTrialActive")
        UserDefaults.standard.removeObject(forKey: "trial_reminder_scheduled_date")
        UserDefaults.standard.removeObject(forKey: "trial_reminder_hours_before")
    }

    private func updatePremiumStatus(customerInfo: CustomerInfo?) {
        guard let customerInfo = customerInfo else {
            isPremium = false
            self.customerInfo = nil
            return
        }
        
        // Store customer info
        self.customerInfo = customerInfo
        
        // Check if user has premium entitlement
        let entitlement = customerInfo.entitlements[entitlementID]
        isPremium = entitlement?.isActive == true

        if isPremium {
            clearLocalTrialState()
            NotificationManager.shared.cancelTrialExpiryNotification()
            NotificationManager.shared.cancelTrialEndingReminder()
            NotificationManager.shared.cancelLeaveAppNonSubscriberWinback()
            NotificationManager.shared.cancelReengagementNotifications()
        }

        syncAccessLifecycleNotifications(entitlement: entitlement)

        if isPremium {
            if let expirationDate = customerInfo.entitlements[entitlementID]?.expirationDate {
                debugPrint("📊 Premium status: Active (expires: \(expirationDate))")
            } else {
                debugPrint("📊 Premium status: Active (lifetime)")
            }
        } else {
            debugPrint("📊 Premium status: Inactive")
        }
    }

    // MARK: - Access lifecycle (trial ending → lapse → win-back)

    private var lastKnownAccessKey: String { "lastKnownPremiumAccess" }
    private var accessLapsedAtKey: String { "accessLapsedAt" }

    /// The moment a paid or trial entitlement ran out without renewing. `nil` while access is live
    /// or for users who never had access at all.
    var accessLapsedAt: Date? {
        guard !isPremium else { return nil }
        return UserDefaults.standard.object(forKey: accessLapsedAtKey) as? Date
    }

    /// Drives the "your access has ended" state on the dashboard and lock screen.
    /// Store entitlements set `accessLapsedAt` via RevenueCat. A local 3-day app
    /// trial that already expired must also count — otherwise old installs never
    /// see the expired banner or the auto paywall.
    var hasLapsedAccess: Bool {
        return !hasPremiumAccess && (accessLapsedAt != nil || hasTrialExpired)
    }

    private func recordLocalTrialLapseIfNeeded() {
        guard hasTrialExpired, !isPremium, let expiry = trialExpiryDate else { return }
        let defaults = UserDefaults.standard
        if defaults.object(forKey: accessLapsedAtKey) == nil {
            defaults.set(expiry, forKey: accessLapsedAtKey)
        }
    }

    /// Keeps the trial-ending reminders and the win-back series in sync with the real
    /// entitlement, so a lapse is never silent even if the user does not open the app.
    private func syncAccessLifecycleNotifications(entitlement: EntitlementInfo?) {
        let defaults = UserDefaults.standard
        let notifications = NotificationManager.shared

        if let entitlement, entitlement.isActive {
            defaults.set(true, forKey: lastKnownAccessKey)
            defaults.removeObject(forKey: accessLapsedAtKey)

            // Lifetime access, or a renewal is already scheduled — nothing to warn about.
            // Reminding an auto-renewing subscriber only invites a cancellation.
            guard let expiry = entitlement.expirationDate, !entitlement.willRenew else {
                notifications.cancelStoreTrialReminders()
                notifications.cancelSubscriptionWinbackSeries()
                return
            }

            if entitlement.periodType == .trial || entitlement.periodType == .intro {
                notifications.scheduleStoreTrialEndingReminders(expiresAt: expiry)
            } else {
                notifications.cancelStoreTrialReminders()
            }
            notifications.scheduleSubscriptionWinbackSeries(anchor: expiry)
            return
        }

        notifications.cancelStoreTrialReminders()

        // Only people who actually had access get win-back copy about what they lost.
        let previouslyHadAccess = defaults.bool(forKey: lastKnownAccessKey)
        guard previouslyHadAccess || entitlement?.expirationDate != nil else { return }

        // Anchor once, so relaunching the app never restarts the series.
        let anchor: Date
        if let stored = defaults.object(forKey: accessLapsedAtKey) as? Date {
            anchor = stored
        } else {
            anchor = entitlement?.expirationDate ?? Date()
            defaults.set(anchor, forKey: accessLapsedAtKey)
            debugPrint("📉 Access lapsed at \(anchor) — scheduling win-back series")
        }
        defaults.set(false, forKey: lastKnownAccessKey)
        notifications.scheduleSubscriptionWinbackSeries(anchor: anchor)
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case userCancelled
    case pending
    case failedVerification
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending"
        case .failedVerification:
            return "Transaction verification failed"
        case .unknown:
            return "Unknown error occurred"
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

