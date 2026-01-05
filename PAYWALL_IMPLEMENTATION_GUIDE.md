# Paywall Implementation Guide - ScrollDeeds

## 📋 Overzicht

Deze gids helpt je stap-voor-stap een paywall te implementeren in ScrollDeeds met StoreKit 2.

---

## Stap 1: StoreKit 2 Setup in Xcode

### 1.1 StoreKit Configuration File aanmaken

1. **In Xcode:**
   - Klik rechts op `scrolldeeds` folder
   - Selecteer "New File..."
   - Kies "StoreKit Configuration File"
   - Noem het: `Products.storekit`
   - Sla op in `scrolldeeds` folder

2. **Configureer Products:**
   - Klik op `Products.storekit` in Xcode
   - Klik op "+" om producten toe te voegen
   - Voeg toe:
     - **Product ID:** `com.scrolldeeds.premium.monthly`
     - **Type:** Auto-Renewable Subscription
     - **Price:** €4.99
     - **Display Name:** ScrollDeeds Premium Monthly
     
     - **Product ID:** `com.scrolldeeds.premium.yearly`
     - **Type:** Auto-Renewable Subscription
     - **Price:** €39.99
     - **Display Name:** ScrollDeeds Premium Yearly

### 1.2 StoreKit Configuration toevoegen aan Scheme

1. **Edit Scheme:**
   - Klik op je scheme (naast de play button)
   - Kies "Edit Scheme..."
   - Ga naar "Run" → "Options"
   - Bij "StoreKit Configuration" selecteer `Products.storekit`

---

## Stap 2: SubscriptionManager Class Maken

Maak een nieuw bestand: `SubscriptionManager.swift`

```swift
//
//  SubscriptionManager.swift
//  scrolldeeds
//
//  Manages in-app purchases and subscription status
//

import Foundation
import StoreKit
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPremium: Bool = false
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    // Product IDs
    private let monthlyProductID = "com.scrolldeeds.premium.monthly"
    private let yearlyProductID = "com.scrolldeeds.premium.yearly"
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products and check subscription status
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = [monthlyProductID, yearlyProductID]
            products = try await Product.products(for: productIDs)
            debugPrint("✅ Loaded \(products.count) products")
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            debugPrint("❌ Error loading products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            
            // Update premium status
            await checkSubscriptionStatus()
            
            return transaction
        case .userCancelled:
            throw SubscriptionError.userCancelled
        case .pending:
            throw SubscriptionError.pending
        @unknown default:
            throw SubscriptionError.unknown
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            debugPrint("✅ Purchases restored")
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            debugPrint("❌ Error restoring purchases: \(error)")
        }
    }
    
    // MARK: - Check Subscription Status
    
    func checkSubscriptionStatus() async {
        var isCurrentlyPremium = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if transaction is for our premium products
                if transaction.productID == monthlyProductID || transaction.productID == yearlyProductID {
                    isCurrentlyPremium = true
                    purchasedProductIDs.insert(transaction.productID)
                }
            } catch {
                debugPrint("❌ Failed to verify transaction: \(error)")
            }
        }
        
        isPremium = isCurrentlyPremium
        debugPrint("📊 Premium status: \(isPremium)")
    }
    
    // MARK: - Transaction Verification
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Listen for Transactions
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts(transaction)
                    await transaction.finish()
                } catch {
                    debugPrint("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func updatePurchasedProducts(_ transaction: Transaction) async {
        if transaction.productID == monthlyProductID || transaction.productID == yearlyProductID {
            await checkSubscriptionStatus()
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
```

---

## Stap 3: PaywallView UI Maken

Maak een nieuw bestand: `PaywallView.swift`

```swift
//
//  PaywallView.swift
//  scrolldeeds
//
//  Beautiful paywall view for premium subscription
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.primary)
                        
                        Text("Unlock Premium")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("Get the most out of ScrollDeeds")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 40)
                    
                    // Features
                    VStack(spacing: 20) {
                        FeatureRow(
                            icon: "bolt.fill",
                            title: "All Difficulty Levels",
                            description: "Access Easy, Medium, Hard, and Extreme modes"
                        )
                        
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Advanced Analytics",
                            description: "Track your progress with detailed insights"
                        )
                        
                        FeatureRow(
                            icon: "infinity",
                            title: "Unlimited Sessions",
                            description: "No limits on your mindful practice"
                        )
                        
                        FeatureRow(
                            icon: "bell.badge.fill",
                            title: "Priority Support",
                            description: "Get help when you need it"
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Products
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        VStack(spacing: 16) {
                            ForEach(subscriptionManager.products, id: \.id) { product in
                                ProductButton(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    onTap: {
                                        selectedProduct = product
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Purchase Button
                    Button(action: {
                        purchaseSelectedProduct()
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Start Premium")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            selectedProduct != nil ? AppTheme.primary : AppTheme.textMuted
                        )
                        .cornerRadius(16)
                    }
                    .disabled(selectedProduct == nil || isPurchasing || subscriptionManager.isLoading)
                    .padding(.horizontal, 24)
                    
                    // Restore Purchases
                    Button(action: {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.bottom, 20)
                    
                    // Terms
                    VStack(spacing: 8) {
                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textMuted)
                            .multilineTextAlignment(.center)
                        
                        Text("Subscription auto-renews unless cancelled 24 hours before renewal")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            
            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(subscriptionManager.errorMessage ?? "An error occurred")
        }
        .onAppear {
            // Select yearly by default
            if let yearly = subscriptionManager.products.first(where: { $0.id.contains("yearly") }) {
                selectedProduct = yearly
            } else if let first = subscriptionManager.products.first {
                selectedProduct = first
            }
        }
    }
    
    private func purchaseSelectedProduct() {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        
        Task {
            do {
                _ = try await subscriptionManager.purchase(product)
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
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(AppTheme.card)
        .cornerRadius(16)
    }
}

// MARK: - Product Button

struct ProductButton: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if let price = product.displayPrice {
                        Text(price)
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.primary)
                } else {
                    Circle()
                        .strokeBorder(AppTheme.textMuted, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(20)
            .background(
                isSelected ? AppTheme.primary.opacity(0.1) : AppTheme.card
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? AppTheme.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

#Preview {
    PaywallView()
}
```

---

## Stap 4: Feature Gating Implementeren

### 4.1 Difficulty Levels Gaten

In `SettingsView.swift` of waar difficulty levels worden geselecteerd:

```swift
@StateObject private var subscriptionManager = SubscriptionManager.shared

// In de difficulty level selector:
if !subscriptionManager.isPremium && (level == .hard || level == .extreme) {
    // Show paywall instead of allowing selection
    Button(action: {
        showPaywall = true
    }) {
        // Locked difficulty level UI
    }
} else {
    // Allow selection
}
```

### 4.2 Paywall Trigger in ContentView

Voeg toe aan `ContentView.swift`:

```swift
@StateObject private var subscriptionManager = SubscriptionManager.shared
@State private var showPaywall = false

// In body, voeg toe:
.sheet(isPresented: $showPaywall) {
    PaywallView()
}
```

---

## Stap 5: App Store Connect Configuratie

### 5.1 In-App Purchases Aanmaken

1. **Ga naar App Store Connect:**
   - Login op [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Selecteer je app: ScrollDeeds
   - Ga naar "Features" → "In-App Purchases"

2. **Maak Subscription Group:**
   - Klik "+" om een nieuwe subscription group te maken
   - Noem het: "ScrollDeeds Premium"

3. **Voeg Monthly Subscription toe:**
   - Klik "+" → "Auto-Renewable Subscription"
   - **Reference Name:** Premium Monthly
   - **Product ID:** `com.scrolldeeds.premium.monthly`
   - **Subscription Group:** ScrollDeeds Premium
   - **Subscription Duration:** 1 Month
   - **Price:** €4.99
   - **Display Name:** ScrollDeeds Premium Monthly
   - **Description:** Unlock all premium features with monthly subscription

4. **Voeg Yearly Subscription toe:**
   - Klik "+" → "Auto-Renewable Subscription"
   - **Reference Name:** Premium Yearly
   - **Product ID:** `com.scrolldeeds.premium.yearly`
   - **Subscription Group:** ScrollDeeds Premium
   - **Subscription Duration:** 1 Year
   - **Price:** €39.99
   - **Display Name:** ScrollDeeds Premium Yearly
   - **Description:** Unlock all premium features with yearly subscription (Save 33%)

5. **Configureer Subscription Benefits:**
   - Bij elke subscription, voeg "Subscription Benefits" toe
   - Beschrijf wat premium users krijgen

### 5.2 Privacy & Terms

1. **Privacy Policy URL:**
   - Zorg dat je Privacy Policy URL hebt
   - Voeg toe in App Store Connect

2. **Terms of Service:**
   - Zorg dat je Terms of Service URL hebt
   - Voeg toe in App Store Connect

---

## Stap 6: Testen

### 6.1 Test Accounts

1. **Maak Test Account in App Store Connect:**
   - Ga naar "Users and Access" → "Sandbox Testers"
   - Klik "+" om test account toe te voegen
   - Gebruik een uniek email (niet je echte Apple ID)

2. **Test in Simulator/Device:**
   - Log uit van je echte Apple ID
   - Gebruik de test account
   - Test purchases werken nu zonder echte betaling

### 6.2 Test Scenarios

- ✅ Load products
- ✅ Purchase monthly subscription
- ✅ Purchase yearly subscription
- ✅ Restore purchases
- ✅ Cancel subscription
- ✅ Feature gating werkt correct

---

## Stap 7: Paywall Triggers

### 7.1 Wanneer Paywall Tonen

1. **Na onboarding** (soft paywall)
2. **Bij premium feature access** (hard paywall)
3. **In settings** (upgrade button)

### 7.2 Implementatie Voorbeelden

```swift
// In SettingsView
Button("Upgrade to Premium") {
    showPaywall = true
}

// In Difficulty Level Selector
if level == .hard || level == .extreme {
    if !subscriptionManager.isPremium {
        showPaywall = true
        return
    }
}
```

---

## ✅ Checklist

- [ ] StoreKit Configuration File aangemaakt
- [ ] SubscriptionManager class geïmplementeerd
- [ ] PaywallView UI gemaakt
- [ ] Feature gating geïmplementeerd
- [ ] Products aangemaakt in App Store Connect
- [ ] Test accounts aangemaakt
- [ ] Getest in simulator/device
- [ ] Privacy Policy & Terms toegevoegd

---

## 🚀 Volgende Stappen

1. Test alles grondig
2. Submit app met paywall
3. Monitor subscription metrics in App Store Connect
4. Iterate op basis van user feedback

---

## 📝 Notities

- StoreKit 2 is gratis te gebruiken
- Apple neemt 30% (eerste jaar) / 15% (na eerste jaar) commission
- Test altijd met sandbox accounts
- Zorg voor duidelijke value proposition in paywall

