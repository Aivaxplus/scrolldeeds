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
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            debugPrint("✅ Loaded offerings: \(offerings.all.count) packages available")
        } catch {
            errorMessage = "Failed to load offerings: \(error.localizedDescription)"
            debugPrint("❌ Error loading offerings: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ package: Package) async throws {
        do {
            let (transaction, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
            
            if userCancelled {
                throw SubscriptionError.userCancelled
            }
            
            updatePremiumStatus(customerInfo: customerInfo)
            
            debugPrint("✅ Purchase successful: \(package.storeProduct.productIdentifier)")
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
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                updatePremiumStatus(customerInfo: customerInfo)
            } catch {
                debugPrint("❌ Error checking premium status: \(error)")
            }
        }
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
        isPremium = customerInfo.entitlements[entitlementID]?.isActive == true
        
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

