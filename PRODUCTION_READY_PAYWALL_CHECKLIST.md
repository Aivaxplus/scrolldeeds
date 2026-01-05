# Production Ready Checklist - ScrollDeeds met Paywall

## 📋 Complete Checklist voor Productie Release

---

## ✅ Stap 1: Code & Testing (Lokaal)

### 1.1 StoreKit Configuration
- [x] `Products.storekit` aangemaakt
- [x] Premium Monthly: €6.99 toegevoegd
- [x] Premium Yearly: €69.99 toegevoegd
- [x] Introductory Offer: 1 maand gratis voor yearly
- [x] StoreKit Configuration gekoppeld aan Scheme

### 1.2 Code Bestanden
- [x] `SubscriptionManager.swift` aangemaakt
- [x] `PaywallView.swift` aangemaakt
- [x] Paywall geïntegreerd in `PracticeSessionView`
- [x] Feature gating geïmplementeerd
- [x] Premium check in `ContentView` en `CustomLockView`

### 1.3 Testen in Simulator
- [ ] Run app in simulator
- [ ] Test eerste dhikr → paywall verschijnt
- [ ] Test product loading (zou 2 producten moeten tonen)
- [ ] Test purchase flow (met sandbox account)
- [ ] Test restore purchases
- [ ] Test premium unlock na purchase
- [ ] Test dat niet-premium gebruikers niet kunnen unlocken

---

## ✅ Stap 2: App Store Connect Setup

### 2.1 Banking & Tax (KRITIEK!)
1. **Login op App Store Connect:**
   - Ga naar [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Login met je Apple Developer account

2. **Agreements, Tax, and Banking:**
   - Klik op je naam rechtsboven
   - Kies "Agreements, Tax, and Banking"
   - Zorg dat je "Paid Apps Agreement" hebt geaccepteerd

3. **Banking Setup:**
   - Klik "Set Up" bij "Banking"
   - Voeg je bankrekening toe:
     - IBAN (International Bank Account Number)
     - BIC/SWIFT code
     - Bank naam
     - Rekeninghouder naam
   - Klik "Save"
   - Wacht op validatie (kan 1-3 dagen duren)

4. **Tax Information:**
   - Klik "Set Up" bij "Tax Information"
   - Als je in België/Nederland bent:
     - Selecteer je land
     - Vul je belastingnummer in
     - Geen US belasting nodig
   - Klik "Save"

### 2.2 In-App Purchases Aanmaken

1. **Ga naar je App:**
   - Selecteer "ScrollDeeds" in App Store Connect
   - Ga naar "Features" → "In-App Purchases"

2. **Maak Subscription Group:**
   - Klik "+" → "Create Subscription Group"
   - Naam: `ScrollDeeds Premium`
   - Klik "Create"

3. **Voeg Monthly Subscription toe:**
   - Klik "+" → "Auto-Renewable Subscription"
   - **Reference Name:** `Premium Monthly`
   - **Product ID:** `com.scrolldeeds.premium.monthly` (MOET EXACT ZELFDE ZIJN!)
   - **Subscription Group:** ScrollDeeds Premium
   - **Subscription Duration:** 1 Month
   - **Price:** €6.99
   - **Display Name:** `ScrollDeeds Premium Monthly`
   - **Description:** `Unlock all premium features with monthly subscription. Access all difficulty levels and unlock your apps with dhikr.`
   - Klik "Create"

4. **Voeg Yearly Subscription toe:**
   - Klik "+" → "Auto-Renewable Subscription"
   - **Reference Name:** `Premium Yearly`
   - **Product ID:** `com.scrolldeeds.premium.yearly` (MOET EXACT ZELFDE ZIJN!)
   - **Subscription Group:** ScrollDeeds Premium
   - **Subscription Duration:** 1 Year
   - **Price:** €69.99
   - **Display Name:** `ScrollDeeds Premium Yearly`
   - **Description:** `Unlock all premium features with yearly subscription. Save 1 month free! Access all difficulty levels and unlock your apps with dhikr.`
   - Klik "Create"

5. **Voeg Introductory Offer toe (Yearly):**
   - Klik op "Premium Yearly" subscription
   - Scroll naar "Introductory Offers"
   - Klik "+" → "Free Trial"
   - **Duration:** 1 Month
   - **Price:** €0.00 (automatisch)
   - **Eligibility:** All New Subscribers
   - Klik "Create"

### 2.3 Subscription Benefits (Optioneel maar Aanbevolen)
- Bij elke subscription, voeg "Subscription Benefits" toe:
  - "Unlock all difficulty levels"
  - "Unlimited dhikr sessions"
  - "Unlock apps with dhikr practice"

---

## ✅ Stap 3: Privacy & Legal

### 3.1 Privacy Policy
- [ ] Zorg dat je Privacy Policy URL werkt
- [ ] Update Privacy Policy met subscription informatie
- [ ] Voeg toe: "We use StoreKit for in-app purchases"

### 3.2 Terms of Service
- [ ] Zorg dat je Terms of Service URL werkt
- [ ] Update Terms met subscription voorwaarden
- [ ] Voeg toe: "Subscriptions auto-renew unless cancelled"

### 3.3 App Privacy Details
- [ ] Ga naar App Store Connect → App Privacy
- [ ] Voeg toe: "Purchases" → "In-App Purchases"
- [ ] Beschrijf wat je verzamelt (subscription status)

---

## ✅ Stap 4: Build & Upload

### 4.1 Version & Build Number
- [ ] Update versie nummer in Xcode:
  - Marketing Version: `1.1` (of hoger)
  - Build Number: verhoog (bijv. `9` → `10`)

### 4.2 Archive & Upload
1. **In Xcode:**
   - Selecteer "Any iOS Device" als target
   - Product → Archive
   - Wacht tot archive klaar is

2. **Upload naar App Store Connect:**
   - Klik "Distribute App"
   - Kies "App Store Connect"
   - Kies "Upload"
   - Volg de wizard
   - Wacht tot upload compleet is (5-15 minuten)

### 4.3 Processing
- [ ] Wacht tot Apple processing klaar is (15 min - 2 uur)
- [ ] Check App Store Connect → TestFlight → Builds
- [ ] Zorg dat build "Ready to Submit" is

---

## ✅ Stap 5: App Store Listing

### 5.1 App Information
- [ ] Update app description met premium features
- [ ] Update keywords (voeg "premium", "subscription" toe)
- [ ] Update promotional text (optioneel)

### 5.2 Pricing & Availability
- [ ] Zorg dat app gratis is (of betaald, jouw keuze)
- [ ] Selecteer beschikbare landen

### 5.3 App Review Information
- [ ] Test Account: voeg sandbox test account toe
- [ ] Notes: leg uit hoe paywall werkt
   - "Paywall appears after first dhikr completion"
   - "Users can test with sandbox account: [email]"

---

## ✅ Stap 6: Final Checks

### 6.1 Code Checks
- [ ] Geen debug prints in production (of alleen belangrijke)
- [ ] Alle error handling werkt
- [ ] Premium status wordt correct gecheckt
- [ ] Restore purchases werkt

### 6.2 UI/UX Checks
- [ ] Paywall ziet er professioneel uit
- [ ] Consistent met app stijl
- [ ] Alle teksten zijn correct
- [ ] Prijzen kloppen (€6.99 en €69.99)

### 6.3 Functionality Checks
- [ ] Paywall verschijnt na eerste dhikr
- [ ] Niet-premium gebruikers kunnen niet unlocken
- [ ] Premium gebruikers kunnen wel unlocken
- [ ] Purchase flow werkt
- [ ] Restore purchases werkt

---

## ✅ Stap 7: Submit voor Review

### 7.1 Build Selecteren
- [ ] Ga naar "App Store" tab in App Store Connect
- [ ] Kies je nieuwe build (met paywall)
- [ ] Klik "Submit for Review"

### 7.2 Review Notes
Voeg toe aan "Notes for Review":
```
Paywall Implementation:
- Paywall appears after user completes first dhikr session
- Users must subscribe to unlock apps
- Test with sandbox account: [jouw test email]
- Monthly: €6.99, Yearly: €69.99 with 1 month free trial
```

### 7.3 Submit
- [ ] Check alle informatie
- [ ] Accepteer export compliance (als nodig)
- [ ] Klik "Submit"
- [ ] Wacht op review (1-3 dagen)

---

## 🚨 Belangrijke Notities

### Product IDs MOETEN exact overeenkomen!
- Code: `com.scrolldeeds.premium.monthly`
- App Store Connect: `com.scrolldeeds.premium.monthly`
- **EXACT ZELFDE!** (geen spaties, hoofdletters, etc.)

### Banking Setup
- **KRITIEK:** Zonder banking setup krijg je GEEN betalingen
- Setup kan 1-3 dagen duren voor validatie
- Zorg dat je IBAN en BIC correct zijn

### Test Accounts
- Maak sandbox test accounts in App Store Connect
- Gebruik deze om purchases te testen
- Log uit van je echte Apple ID in simulator/device

### Belastingen
- Jij bent verantwoordelijk voor je eigen belastingen
- Apple geeft je maandelijks een overzicht
- Houd rekening met lokale belastingwetten

---

## 📊 Na Release

### Monitoring
- [ ] Check App Store Connect → Sales and Trends
- [ ] Monitor subscription metrics
- [ ] Check user feedback
- [ ] Monitor crash reports

### Updates
- [ ] Iterate op basis van feedback
- [ ] A/B test verschillende prijzen (optioneel)
- [ ] Voeg nieuwe premium features toe

---

## ✅ Quick Start Checklist

**Voor je begint:**
1. [ ] Banking setup in App Store Connect
2. [ ] Tax information ingevuld
3. [ ] In-App Purchases aangemaakt
4. [ ] Product IDs exact hetzelfde als in code
5. [ ] Test met sandbox account
6. [ ] Build gemaakt en geüpload
7. [ ] Submit voor review

---

## 🆘 Troubleshooting

### Paywall verschijnt niet?
- Check of `SubscriptionManager.shared.loadProducts()` wordt aangeroepen
- Check of Product IDs exact overeenkomen
- Check console voor errors

### Purchase werkt niet?
- Zorg dat je sandbox test account gebruikt
- Log uit van echte Apple ID
- Check of banking setup compleet is

### Geen betalingen ontvangen?
- Check banking setup status
- Check of minimum uitbetaling bereikt is (€10)
- Check payment schedule in App Store Connect

---

**Laat weten als je hulp nodig hebt bij een specifieke stap!**

