# RevenueCat Setup - Volgende Stappen

## ✅ Wat is al gedaan:
- Code is aangepast voor RevenueCat
- SubscriptionManager gebruikt RevenueCat
- PaywallView gebruikt RevenueCat Packages

## 📋 Wat je NU moet doen:

### Stap 1: RevenueCat SDK Toevoegen in Xcode

1. **Open je project in Xcode**
   - Open `scrolldeeds.xcodeproj`

2. **Voeg Swift Package toe:**
   - Klik op je project in de navigator (bovenaan links)
   - Selecteer je target: `scrolldeeds`
   - Ga naar tab: **"Package Dependencies"**
   - Klik op **"+"** knop (linksonder)

3. **Voeg RevenueCat toe:**
   - In het zoekveld, plak deze URL:
     ```
     https://github.com/RevenueCat/purchases-ios-spm.git
     ```
   - Klik **"Add Package"**
   - Selecteer **"RevenueCat"** (niet RevenueCatHybrid)
   - Zorg dat **"scrolldeeds"** target is aangevinkt
   - Klik **"Add Package"**

4. **Verify:**
   - Check of `RevenueCat` verschijnt onder "Package Dependencies"
   - Als het er staat, is het goed geïnstalleerd ✅

---

### Stap 2: API Key Toevoegen

1. **Open:** `scrolldeeds/scrolldeedsApp.swift`

2. **Vervang regel 37:**
   ```swift
   let revenueCatAPIKey = "pk_test_xxxxxxxxxxxxx" // VERVANG MET JE ECHTE KEY!
   ```
   
   **Met:**
   ```swift
   let revenueCatAPIKey = "test_RtMCUxaPxJRUnsyRrYNIdJBZ0jW"
   ```

3. **Save** het bestand (Cmd+S)

---

### Stap 3: Products in RevenueCat Dashboard Configureren

1. **Ga naar RevenueCat Dashboard:**
   - Login op [app.revenuecat.com](https://app.revenuecat.com)
   - Selecteer project: **Scrolldeeds**

2. **Voeg Products toe:**
   - Ga naar **"Products"** in linker menu
   - Klik **"+ New"** of **"Add Product"**
   
   **Product 1:**
   - Product ID: `com.scrolldeeds.premium.monthly`
   - Type: `Subscription`
   - Store Product ID: `com.scrolldeeds.premium.monthly`
   - Klik **"Save"**
   
   **Product 2:**
   - Product ID: `com.scrolldeeds.premium.yearly`
   - Type: `Subscription`
   - Store Product ID: `com.scrolldeeds.premium.yearly`
   - Klik **"Save"**

3. **Maak Entitlement:**
   - Ga naar **"Entitlements"** in linker menu
   - Klik **"+ New"** of **"Add Entitlement"**
   - **Entitlement ID:** `premium`
   - **Description:** `Premium access to all features`
   - **Koppel products:**
     - Voeg `com.scrolldeeds.premium.monthly` toe
     - Voeg `com.scrolldeeds.premium.yearly` toe
   - Klik **"Save"**

---

### Stap 4: Testen

1. **Build & Run:**
   - In Xcode: Cmd+B (build)
   - Als er errors zijn, laat het weten!

2. **Test Paywall:**
   - Open de app
   - Probeer een dhikr sessie te starten
   - Paywall zou moeten verschijnen
   - Check of packages laden (maandelijkse en jaarlijkse opties)

3. **Check Console:**
   - In Xcode, open de console (Cmd+Shift+Y)
   - Zoek naar: `✅ RevenueCat initialized`
   - Zoek naar: `✅ Loaded offerings`

---

## ⚠️ Belangrijk:

- **Product IDs** moeten exact overeenkomen tussen:
  - App Store Connect
  - RevenueCat Dashboard
  - Je code

- **App Store Connect:** Products moeten nog steeds in App Store Connect staan (blijft hetzelfde)

---

## 🆘 Troubleshooting:

### SDK niet gevonden?
- Check of package correct is toegevoegd
- Clean build folder: **Product → Clean Build Folder** (Cmd+Shift+K)
- Rebuild project: **Product → Build** (Cmd+B)

### API Key error?
- Check of je de juiste key gebruikt (test key voor nu)
- Check of key begint met `test_` of `pk_`

### Products niet laden?
- Check of Product IDs exact overeenkomen
- Check of products in App Store Connect staan
- Check RevenueCat dashboard → Products

---

**Laat weten als je klaar bent of als er problemen zijn!** 🚀

