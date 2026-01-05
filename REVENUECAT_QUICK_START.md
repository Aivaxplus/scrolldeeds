# RevenueCat Quick Start - ScrollDeeds ✅

## 🎉 Wat is al gedaan:

### ✅ Code Implementation
1. **SubscriptionManager.swift** - Volledig geïmplementeerd met:
   - Entitlement checking voor "Scrolldeeds Pro"
   - Customer info retrieval
   - Purchase handling
   - Restore purchases
   - Error handling

2. **RevenueCatDelegate.swift** - Automatische updates bij purchase/restore

3. **PaywallView.swift** - Al aangepast voor RevenueCat Packages

4. **CustomerCenterView.swift** - Nieuw! Voor subscription management

5. **SettingsView.swift** - Link naar Customer Center toegevoegd

6. **scrolldeedsApp.swift** - RevenueCat geïnitialiseerd met jouw API key

---

## 📋 Wat je nog moet doen:

### Stap 1: SDK Installeren (5 minuten)

1. Open Xcode
2. Klik op je project (bovenaan)
3. Selecteer target: `scrolldeeds`
4. Ga naar "Package Dependencies"
5. Klik "+"
6. Plak: `https://github.com/RevenueCat/purchases-ios-spm.git`
7. Selecteer "RevenueCat"
8. Klik "Add Package"

---

### Stap 2: Products Configureren in RevenueCat (10 minuten)

1. Ga naar [app.revenuecat.com](https://app.revenuecat.com)
2. Selecteer project: **Scrolldeeds**

#### Products Toevoegen:
- **Product 1:**
  - Product ID: `com.scrolldeeds.premium.monthly`
  - Store Product ID: `com.scrolldeeds.premium.monthly`
  - Type: `Subscription`

- **Product 2:**
  - Product ID: `com.scrolldeeds.premium.yearly`
  - Store Product ID: `com.scrolldeeds.premium.yearly`
  - Type: `Subscription`

#### Entitlement Maken:
- **Entitlement ID:** `Scrolldeeds Pro` (exact zoals in code!)
- Koppel beide products aan dit entitlement

#### Offering Maken (optioneel):
- **Offering ID:** `default`
- Voeg beide packages toe

---

### Stap 3: Testen (5 minuten)

1. Build app: `Cmd+B`
2. Run app
3. Test paywall (start een dhikr sessie)
4. Check console voor:
   - `✅ RevenueCat initialized`
   - `✅ Loaded offerings`
   - `📊 Premium status: Active/Inactive`

---

## 🔑 Belangrijke Details:

### Entitlement ID
- **In Code:** `"Scrolldeeds Pro"`
- **In RevenueCat:** Moet exact hetzelfde zijn: `Scrolldeeds Pro`

### API Key
- **Huidig:** `test_RtMCUxaPxJRUnsyRrYNIdJBZOjW` (test key)
- **Voor Productie:** Vervang met `pk_live_...` key

### Product IDs
Moeten exact overeenkomen:
- ✅ App Store Connect: `com.scrolldeeds.premium.monthly`
- ✅ RevenueCat: `com.scrolldeeds.premium.monthly`
- ✅ Code: `com.scrolldeeds.premium.monthly`

---

## 📱 Gebruik in App:

### Check Premium Status
```swift
if subscriptionManager.isPremium {
    // Premium features
}
```

### Show Paywall
```swift
.sheet(isPresented: $showPaywall) {
    PaywallView()
}
```

### Show Customer Center
- Ga naar Settings → "Manage Subscription"
- Of gebruik: `CustomerCenterView()`

---

## 📚 Volledige Documentatie:

Zie `REVENUECAT_COMPLETE_INTEGRATION.md` voor:
- Complete setup guide
- Best practices
- Error handling
- Troubleshooting
- Testing guide

---

## ✅ Checklist:

- [ ] SDK geïnstalleerd via Swift Package Manager
- [ ] Products toegevoegd in RevenueCat dashboard
- [ ] Entitlement "Scrolldeeds Pro" gemaakt
- [ ] Products gekoppeld aan entitlement
- [ ] App gebuild en getest
- [ ] Paywall werkt
- [ ] Customer Center werkt

---

**Klaar! Je RevenueCat integratie is compleet! 🚀**

Voor vragen, check `REVENUECAT_COMPLETE_INTEGRATION.md` of RevenueCat documentatie.

