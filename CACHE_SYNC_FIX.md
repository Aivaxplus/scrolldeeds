# 🔄 Cache & Sync Fix: Apple Pay toont nog "1 maand"

## ✅ Wat al goed is:
- ✅ App Store Connect → **"Free for the first 3 days"** (correct!)
- ✅ `Products.storekit` → **P3D** (3 dagen)
- ✅ Alle localized strings → **"3 dagen"**

## ❌ Probleem:
Apple Pay popup toont nog steeds **"1 maand"** in plaats van **"3 dagen"**

## 🔧 Oplossing: Cache & Sync

### **Stap 1: RevenueCat Cache Invalideren (Al in code ✅)**

In `scrolldeedsApp.swift` staat al:
```swift
#if DEBUG
debugPrint("🗑️ Clearing RevenueCat cache...")
Purchases.shared.invalidateCustomerInfoCache()
#endif
```

Dit werkt alleen in **DEBUG mode**. Voor testing:

### **Stap 2: Force Clear Cache in App**

1. **Delete app volledig van device/simulator:**
   - Long press app icon → Delete App
   - OF: Settings → General → iPhone Storage → ScrollDeeds → Delete App

2. **Clear Simulator Data (als je simulator gebruikt):**
   ```bash
   # In Terminal:
   xcrun simctl erase all
   ```

3. **Restart device/simulator**

4. **Reinstall app**

### **Stap 3: RevenueCat Dashboard Check**

1. **Ga naar RevenueCat Dashboard:**
   - https://app.revenuecat.com
   - Login → Selecteer project

2. **Ga naar Products:**
   - Klik "Products" → Zoek "Premium Yearly"
   - Check "Introductory Offer"
   - **Als het nog "1 Month" zegt:**
     - Klik "Sync from App Store"
     - Wacht 2-3 minuten
     - Refresh pagina

3. **Force Sync:**
   - Klik "Sync Products" button
   - Wacht 1-2 minuten

### **Stap 4: Test met Nieuwe Sandbox Account**

**BELANGRIJK:** Apple's StoreKit cache't trial periode per account!

1. **Delete oude sandbox account:**
   - Settings → App Store → Sandbox Account
   - Delete account

2. **Maak NIEUWE sandbox account:**
   - Test de purchase flow
   - Apple Pay popup zou nu "3 dagen" moeten tonen

### **Stap 5: Wacht op Apple's Sync**

Soms duurt het **1-2 uur** voordat Apple's servers de wijziging hebben verwerkt:

- App Store Connect wijziging → Apple's servers (1-2 uur)
- Apple's servers → StoreKit (real-time, maar kan gecached zijn)
- StoreKit → Apple Pay popup (direct, maar gebruikt cache)

**Test na 1-2 uur opnieuw!**

---

## 🎯 Quick Fix Checklist:

- [ ] App volledig verwijderd van device
- [ ] Simulator data gewist (als simulator gebruikt)
- [ ] Device/simulator gerestart
- [ ] App opnieuw geïnstalleerd
- [ ] RevenueCat dashboard → "Sync from App Store" geklikt
- [ ] Nieuwe sandbox test account gemaakt
- [ ] Test purchase flow → Check Apple Pay popup
- [ ] Als nog steeds "1 maand": Wacht 1-2 uur en test opnieuw

---

## ⚠️ Waarom dit gebeurt:

**Apple's StoreKit cache't trial periode per:**
- Device
- Sandbox account
- App installatie

**Oplossing:**
- Nieuwe sandbox account = nieuwe cache = correcte trial periode
- OF wacht tot cache expired (kan 1-2 uur duren)

---

## 🔍 Debug: Check wat StoreKit ziet

Als je wilt checken wat StoreKit daadwerkelijk ziet, voeg dit toe in `HardPaywallView.swift`:

```swift
if let yearly = yearlyPackage {
    let product = yearly.storeProduct
    if let introOffer = product.subscription?.introductoryOffer {
        debugPrint("📊 StoreKit Introductory Offer:")
        debugPrint("   Period: \(introOffer.subscriptionPeriod)")
        debugPrint("   Price: \(introOffer.price)")
    }
}
```

Dit toont wat StoreKit daadwerkelijk ziet van App Store Connect.

---

**Het belangrijkste:** Als App Store Connect al op "3 dagen" staat, dan **zal het werken** - het is alleen een kwestie van cache clearing en wachten op sync! 🎉
