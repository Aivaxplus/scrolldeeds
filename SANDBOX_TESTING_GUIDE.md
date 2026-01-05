# Sandbox Testing Guide - RevenueCat Purchases

## 🔍 **Waarom werkt de Purchase Button niet?**

### Mogelijke Oorzaken:

1. **Geen Sandbox Account ingelogd**
   - Je moet uitgelogd zijn van je echte Apple ID
   - Je moet ingelogd zijn met een Sandbox Test Account

2. **Geen Packages geladen**
   - RevenueCat heeft geen offerings/packages geladen
   - Check of `subscriptionManager.offerings?.current` niet nil is

3. **Geen Package geselecteerd**
   - `selectedPackage` is nil
   - Button is disabled als er geen package geselecteerd is

4. **RevenueCat niet correct geconfigureerd**
   - API key is incorrect
   - Products zijn niet gesynchroniseerd in RevenueCat dashboard

---

## ✅ **Stap-voor-Stap: Sandbox Testing Setup**

### Stap 1: Maak Sandbox Test Account

1. Ga naar: https://appstoreconnect.apple.com
2. Klik op **"Users and Access"** (bovenaan)
3. Klik op **"Sandbox Testers"** tab
4. Klik **"+"** om nieuwe tester toe te voegen
5. Vul in:
   - **First Name:** Test
   - **Last Name:** User
   - **Email:** Een email die je nog niet gebruikt (bijv. `test.scrolldeeds@example.com`)
   - **Password:** Minimaal 8 karakters
   - **Country/Region:** Nederland/België
6. Klik **"Invite"**
7. Check je email en accepteer de uitnodiging

### Stap 2: Log uit van je echte Apple ID

**Op iPhone/iPad:**
1. Ga naar **Settings** → **App Store**
2. Klik op je Apple ID (bovenaan)
3. Klik **"Sign Out"**
4. Bevestig

**In Simulator:**
1. Ga naar **Settings** → **App Store**
2. Klik op je Apple ID
3. Klik **"Sign Out"**

### Stap 3: Test Purchase in App

1. Open je app
2. Ga naar de paywall (druk op mic knop)
3. Wanneer je een purchase probeert te maken:
   - Je krijgt een popup: **"Sign In to the iTunes Store"**
   - Gebruik je **Sandbox Test Account** email en password
   - Klik **"Sign In"**
4. Bevestig de purchase
5. Purchase zou moeten werken!

---

## 🐛 **Debugging: Check of alles werkt**

### 1. Check of Packages geladen zijn

Voeg debug logging toe in `PaywallView.swift`:

```swift
.onAppear {
    Task {
        await subscriptionManager.loadOfferings()
        
        // DEBUG: Check of offerings geladen zijn
        if let currentOffering = subscriptionManager.offerings?.current {
            debugPrint("✅ Offerings geladen: \(currentOffering.availablePackages.count) packages")
            for package in currentOffering.availablePackages {
                debugPrint("  - Package: \(package.identifier), Product: \(package.storeProduct.productIdentifier)")
            }
        } else {
            debugPrint("❌ Geen offerings gevonden!")
        }
        
        // Select yearly by default
        if let currentOffering = subscriptionManager.offerings?.current {
            if let yearly = currentOffering.availablePackages.first(where: { $0.identifier.contains("yearly") || $0.storeProduct.productIdentifier.contains("yearly") }) {
                selectedPackage = yearly
                debugPrint("✅ Yearly package geselecteerd: \(yearly.storeProduct.productIdentifier)")
            } else if let first = currentOffering.availablePackages.first {
                selectedPackage = first
                debugPrint("✅ Eerste package geselecteerd: \(first.storeProduct.productIdentifier)")
            }
        }
    }
}
```

### 2. Check of Button Enabled is

Voeg debug info toe aan de button:

```swift
Button(action: {
    debugPrint("🔘 Purchase button tapped")
    debugPrint("  - selectedPackage: \(selectedPackage?.identifier ?? "nil")")
    debugPrint("  - isPurchasing: \(isPurchasing)")
    debugPrint("  - isLoading: \(subscriptionManager.isLoading)")
    
    HapticManager.shared.medium()
    purchaseSelectedProduct()
}) {
    // ... button content ...
}
.disabled(selectedPackage == nil || isPurchasing || subscriptionManager.isLoading)
.onTapGesture {
    if selectedPackage == nil {
        debugPrint("⚠️ Button disabled: No package selected")
    }
    if isPurchasing {
        debugPrint("⚠️ Button disabled: Already purchasing")
    }
    if subscriptionManager.isLoading {
        debugPrint("⚠️ Button disabled: Loading")
    }
}
```

### 3. Check RevenueCat Configuration

In `scrolldeedsApp.swift`, check of de API key correct is:

```swift
let revenueCatAPIKey = "appl_wfLidJYoHXcwgXbFKMDBZGNfxGH" // Productie key
Purchases.configure(withAPIKey: revenueCatAPIKey)
Purchases.logLevel = .debug // Zet op .debug voor meer logging
```

### 4. Check RevenueCat Dashboard

1. Ga naar: https://app.revenuecat.com
2. Selecteer je app: **ScrollDeeds**
3. Ga naar **"Products"**
4. Check of je products zichtbaar zijn:
   - `com.scrolldeeds.premium.monthly`
   - `com.scrolldeeds.premium.yearly`
5. Check of ze **"Active"** status hebben

---

## 🔧 **Veelvoorkomende Problemen & Oplossingen**

### Probleem 1: "No packages available"

**Oorzaak:** RevenueCat heeft geen offerings geladen

**Oplossing:**
1. Check RevenueCat Dashboard → **"Offerings"**
2. Zorg dat je een **"Default"** offering hebt
3. Zorg dat je packages gekoppeld zijn aan de offering
4. Check of Product IDs exact overeenkomen:
   - RevenueCat: `com.scrolldeeds.premium.monthly`
   - App Store Connect: `com.scrolldeeds.premium.monthly`
   - Code: `com.scrolldeeds.premium.monthly`

### Probleem 2: Button is disabled

**Oorzaak:** `selectedPackage` is nil

**Oplossing:**
1. Check of packages geladen zijn (zie debug logging hierboven)
2. Check of `onAppear` correct een package selecteert
3. Voeg fallback toe:

```swift
.onAppear {
    Task {
        await subscriptionManager.loadOfferings()
        
        // Select package
        if let currentOffering = subscriptionManager.offerings?.current {
            if let yearly = currentOffering.availablePackages.first(where: { $0.identifier.contains("yearly") }) {
                selectedPackage = yearly
            } else if let first = currentOffering.availablePackages.first {
                selectedPackage = first
            }
        }
        
        // Fallback: als nog steeds nil, selecteer eerste package
        if selectedPackage == nil {
            debugPrint("⚠️ Geen package geselecteerd - check RevenueCat configuratie")
        }
    }
}
```

### Probleem 3: "Purchase failed" error

**Oorzaak:** Sandbox account niet correct ingelogd

**Oplossing:**
1. Log uit van je echte Apple ID
2. Log in met Sandbox Test Account
3. Probeer opnieuw

### Probleem 4: "Product not available" error

**Oorzaak:** Product ID komt niet overeen

**Oplossing:**
1. Check Product IDs in:
   - RevenueCat Dashboard → Products
   - App Store Connect → Subscriptions
   - Code (SubscriptionManager, PaywallView)
2. Zorg dat ze **EXACT** hetzelfde zijn (geen spaties, hoofdletters, etc.)

---

## 📊 **Debug Checklist**

Voordat je test, check:

- [ ] Sandbox Test Account aangemaakt in App Store Connect
- [ ] Uitgelogd van echte Apple ID (Settings → App Store)
- [ ] RevenueCat API key correct geconfigureerd
- [ ] Products gesynchroniseerd in RevenueCat Dashboard
- [ ] Offerings geconfigureerd in RevenueCat Dashboard
- [ ] Product IDs komen exact overeen (RevenueCat, App Store Connect, Code)
- [ ] App is gebuild en gerund op device/simulator
- [ ] Debug logging toegevoegd om te zien wat er gebeurt

---

## 🚀 **Test Flow**

1. **Open app** → Paywall verschijnt
2. **Check console** → Zie je "✅ Offerings geladen"?
3. **Check paywall** → Zie je packages (Monthly & Yearly)?
4. **Selecteer package** → Is button enabled?
5. **Klik "Start Premium"** → Krijg je "Sign In" popup?
6. **Log in met Sandbox Account** → Purchase voltooid?
7. **Check premium status** → Is `subscriptionManager.isPremium` true?

---

## 💡 **Tips**

- Gebruik **.debug** log level in RevenueCat voor meer informatie
- Check **Xcode Console** voor debug prints
- Test op **echte device** (niet alleen simulator) voor beste resultaten
- Sandbox purchases zijn **gratis** - je wordt niet echt belast
- Sandbox purchases **verlopen automatisch** na test periode

---

**Laat weten als je nog steeds problemen hebt!**

