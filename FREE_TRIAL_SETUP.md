# Free Trial Setup Guide

## ✅ Wat is geïmplementeerd in de code:

### 1. UI Component
- "Not sure yet? Enable free trial" kader op de paywall
- Checkbox om trial te activeren
- Premium styling met gouden accenten
- Automatische highlight wanneer geselecteerd

### 2. Trial Logic
- **Trial duur**: 1 dag (24 uur)
- **Trial tracking**: `UserDefaults` keys:
  - `freeTrialStartDate` - Wanneer trial begon
  - `freeTrialEndDate` - Wanneer trial afloopt
  - `isOnFreeTrial` - Boolean flag
  - `hasTrialAccess` - Toegang tijdens trial

### 3. Access Control
- `SubscriptionManager.hasPremiumAccess` - Checked trial OF subscription
- Alle premium checks gebruiken nu `hasPremiumAccess` in plaats van `isPremium`
- Na trial expiry: gebruiker MOET betalen om verder te gaan

### 4. Notifications
- **Trial expiry notification** wordt gescheduled bij trial start
- Notification 24 uur na trial start
- Bericht: "Je 1-daagse gratis proefperiode is afgelopen. Abonneer nu om door te gaan."

### 5. Analytics Tracking
- `trackFreeTrialStarted()` event
- Mixpanel tracking met trial duur en geselecteerd package

---

## 🔧 App Store Connect Configuratie (JIJ MOET DIT DOEN):

### Voor ALLE 3 subscriptions (Yearly, Monthly, Weekly):

#### 1. Ga naar App Store Connect
- Ga naar je app → **Subscriptions**
- Klik op **Premium Yearly**

#### 2. Voeg Introductory Offer toe
- Scroll naar **"Introductory Offers"**
- Klik **"+ Add"**

#### 3. Kies "Free Trial"
- **Type**: Free Trial
- **Duration**: 1 Day (1 dag)
- **Eligibility**: 
  - ✅ New subscribers only
  - ✅ Expired subscribers
  - ✅ Previous subscribers (optioneel)

#### 4. Save

#### 5. Herhaal voor Monthly en Weekly
- Doe exact hetzelfde voor **Premium Monthly**
- En voor **Premium Weekly**

---

## 📱 App Store Connect - Subscription Details:

### Yearly Subscription
- **Product ID**: `com.scrolldeeds.premium.yearly`
- **Duration**: 1 Year
- **Free Trial**: 1 Day
- **Price**: €69.99/year

### Monthly Subscription
- **Product ID**: `com.scrolldeeds.premium.monthly`
- **Duration**: 1 Month
- **Free Trial**: 1 Day
- **Price**: €6.99/month

### Weekly Subscription
- **Product ID**: `com.scrolldeeds.app.premium.weekly`
- **Duration**: 7 Days
- **Free Trial**: 1 Day
- **Price**: jouw prijs/week

---

## 🔄 RevenueCat Configuratie:

### Products
Alle 3 producten moeten "Active" zijn met "1 Entitlement"

### Offerings
**default** offering moet hebben:
1. `$rc_annual` → Premium Yearly
2. `$rc_monthly` → Premium Monthly  
3. `$rc_weekly` → Premium Weekly

---

## 🎯 Hoe het werkt voor gebruikers:

### Scenario 1: User kiest Free Trial
1. User vinkt "Not sure yet? Enable free trial" aan
2. Klikt op subscribe button
3. Trial start direct (geen betaling)
4. User krijgt 24 uur premium toegang
5. Na 24 uur: notification + access geblokkeerd
6. User MOET betalen om verder te gaan

### Scenario 2: User betaalt direct
1. User laat checkbox leeg
2. Klikt op subscribe button
3. Normale purchase flow
4. Direct premium toegang (geen trial)

---

## ⚠️ Belangrijk:

### Apple's Trial Requirements:
- **Elke user kan maar 1x** een free trial krijgen per subscription group
- Apple's StoreKit handelt dit automatisch af
- Je hoeft GEEN code te schrijven om dit te voorkomen

### Testing:
- In **Sandbox**: Je kunt trial meerdere keren testen
- Delete account in Settings → App Store → Sandbox Account
- Nieuwe sandbox test account om opnieuw te testen

---

## 🚀 Next Steps:

1. ✅ Code is klaar
2. ⏳ **NU DOEN**: Voeg 1-day free trial toe in App Store Connect (zie boven)
3. ⏳ Wacht op Apple's goedkeuring (24-48 uur)
4. ✅ RevenueCat sync't automatisch
5. ✅ Test met sandbox account

Na goedkeuring werkt alles automatisch! 🎉
