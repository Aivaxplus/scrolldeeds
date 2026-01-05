# RevenueCat Setup Guide - ScrollDeeds

## 📋 Overzicht

RevenueCat maakt subscription management makkelijker. Deze gids helpt je RevenueCat te integreren in ScrollDeeds.

---

## Stap 1: RevenueCat Account Aanmaken

### 1.1 Account Registreren
1. Ga naar [app.revenuecat.com](https://app.revenuecat.com)
2. Klik "Sign Up" of "Get Started"
3. Maak een gratis account aan
4. Bevestig je email

### 1.2 Project Aanmaken
1. Na login, klik "New Project"
2. Project Name: `ScrollDeeds`
3. Platform: `iOS`
4. Klik "Create Project"

---

## Stap 2: RevenueCat SDK Toevoegen aan Xcode

### 2.1 Swift Package Manager
1. **In Xcode:**
   - Open je project: `scrolldeeds.xcodeproj`
   - Klik op je project in de navigator (bovenaan)
   - Selecteer je target: `scrolldeeds`
   - Ga naar "Package Dependencies" tab

2. **Voeg Package toe:**
   - Klik op "+" knop
   - In het zoekveld, typ: `https://github.com/RevenueCat/purchases-ios`
   - Klik "Add Package"
   - Selecteer "RevenueCat" (niet RevenueCatHybrid)
   - Klik "Add Package"
   - Zorg dat "scrolldeeds" target is aangevinkt
   - Klik "Add Package"

### 2.2 Verify Installation
- Check of `RevenueCat` verschijnt onder "Package Dependencies"
- Als het er staat, is het goed geïnstalleerd

---

## Stap 3: RevenueCat API Key Ophalen

### 3.1 In RevenueCat Dashboard
1. Login op [app.revenuecat.com](https://app.revenuecat.com)
2. Selecteer je project: `ScrollDeeds`
3. Ga naar "Project Settings" (tandwiel icoon linksonder)
4. Klik op "API Keys" tab
5. Kopieer de "Public API Key" (begint meestal met `pk_`)

### 3.2 Noteer de Key
- Sla deze key ergens op (je hebt hem nodig in de code)
- Bijvoorbeeld: `pk_test_xxxxxxxxxxxxx` of `pk_live_xxxxxxxxxxxxx`

---

## Stap 4: Products Aanmaken in RevenueCat

### 4.1 Products Toevoegen
1. In RevenueCat Dashboard:
   - Ga naar "Products" in het linker menu
   - Klik "+ New" of "Add Product"

2. **Voeg Monthly toe:**
   - Product ID: `com.scrolldeeds.premium.monthly`
   - Type: `Subscription`
   - Store Product ID: `com.scrolldeeds.premium.monthly` (moet exact overeenkomen met App Store Connect)
   - Klik "Save"

3. **Voeg Yearly toe:**
   - Product ID: `com.scrolldeeds.premium.yearly`
   - Type: `Subscription`
   - Store Product ID: `com.scrolldeeds.premium.yearly`
   - Klik "Save"

### 4.2 Entitlements Aanmaken
1. Ga naar "Entitlements" in het linker menu
2. Klik "+ New" of "Add Entitlement"
3. **Entitlement ID:** `premium`
4. **Description:** `Premium access to all features`
5. Koppel products:
   - Voeg `com.scrolldeeds.premium.monthly` toe
   - Voeg `com.scrolldeeds.premium.yearly` toe
6. Klik "Save"

---

## Stap 5: Code Aanpassen

### 5.1 Update SubscriptionManager.swift

Vervang de hele `SubscriptionManager.swift` met RevenueCat versie:

```swift
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
    
    private var cancellables = Set<AnyCancellable>()
    
    // Entitlement ID - moet overeenkomen met RevenueCat
    private let entitlementID = "premium"
    
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
                self?.updatePremiumStatus(customerInfo: customerInfo)
            }
        }
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
            return
        }
        
        // Check if user has premium entitlement
        isPremium = customerInfo.entitlements[entitlementID]?.isActive == true
        debugPrint("📊 Premium status: \(isPremium)")
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
```

### 5.2 Update scrolldeedsApp.swift

Voeg RevenueCat initialisatie toe:

```swift
import RevenueCat

// In AppDelegate, voeg toe aan didFinishLaunchingWithOptions:

// Initialize RevenueCat
let apiKey = "pk_test_xxxxxxxxxxxxx" // Vervang met je RevenueCat API Key
Purchases.configure(withAPIKey: apiKey)

// Set user ID (optioneel, maar aanbevolen)
// Purchases.shared.logIn("user_id") // Als je user IDs gebruikt
```

### 5.3 Update PaywallView.swift

Vervang de product loading logica:

```swift
// In PaywallView, vervang:
ForEach(subscriptionManager.products, id: \.id) { product in

// Met:
if let currentOffering = subscriptionManager.offerings?.current {
    ForEach(currentOffering.availablePackages, id: \.identifier) { package in
        ProductButton(
            package: package,
            isSelected: selectedPackage?.identifier == package.identifier,
            onTap: {
                selectedPackage = package
            }
        )
    }
}
```

En update de purchase functie:

```swift
private func purchaseSelectedProduct() {
    guard let package = selectedPackage else { return }
    
    isPurchasing = true
    
    Task {
        do {
            try await subscriptionManager.purchase(package)
            dismiss()
        } catch {
            if case SubscriptionError.userCancelled = error {
                // User cancelled - don't show error
            } else {
                showError = true
            }
        }
        
        isPurchasing = false
    }
}
```

---

## Stap 6: App Store Connect (Blijft hetzelfde!)

- Products moeten nog steeds in App Store Connect staan
- Banking & Tax setup blijft hetzelfde
- RevenueCat gebruikt dezelfde Product IDs

---

## Stap 7: Testen

### 7.1 Sandbox Testing
1. Maak sandbox test account in App Store Connect
2. Log uit van echte Apple ID in simulator
3. Run app
4. Test purchase flow

### 7.2 RevenueCat Dashboard
- Check "Customers" tab voor test purchases
- Check "Revenue" tab voor metrics
- Check "Events" tab voor real-time events

---

## ✅ Voordelen van RevenueCat

1. **Makkelijker management** - Dashboard voor alles
2. **Analytics** - Ingebouwde revenue tracking
3. **Cross-platform** - Werkt op iOS, Android, Web
4. **Webhooks** - Automatische server notifications
5. **A/B Testing** - Test verschillende paywalls
6. **Customer Support** - Makkelijker support geven

---

## 🆘 Troubleshooting

### SDK niet gevonden?
- Check of package correct is toegevoegd
- Clean build folder (Cmd+Shift+K)
- Rebuild project

### API Key error?
- Check of je de juiste key gebruikt (public key, niet secret)
- Check of key begint met `pk_`

### Products niet laden?
- Check of Product IDs exact overeenkomen
- Check of products in App Store Connect staan
- Check RevenueCat dashboard → Products

---

**Laat weten als je hulp nodig hebt bij een specifieke stap!**

