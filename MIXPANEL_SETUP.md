# 📊 Mixpanel Setup Guide

## Stap 1: Mixpanel Account Aanmaken

1. Ga naar [mixpanel.com](https://mixpanel.com)
2. Maak een gratis account aan
3. Maak een nieuw project (bijv. "ScrollDeeds")
4. Kopieer je **Project Token** (je vindt dit in: Settings → Project Settings → Project Token)

---

## Stap 2: Mixpanel SDK Toevoegen via Swift Package Manager

### In Xcode:

1. **Open je project** in Xcode
2. **Klik op je project** in de navigator (bovenaan)
3. **Selecteer je target** (scrolldeeds)
4. Ga naar **"Package Dependencies"** tab
5. Klik op **"+"** om een nieuwe package toe te voegen
6. **Plak deze URL:**
   ```
   https://github.com/mixpanel/mixpanel-swift
   ```
7. Klik **"Add Package"**
8. Selecteer **"Mixpanel"** en klik **"Add Package"**
9. Zorg dat **"Mixpanel"** is aangevinkt bij je target

---

## Stap 3: Mixpanel Token Toevoegen aan Info.plist

1. **Open `Info.plist`** in Xcode
2. **Voeg een nieuwe key toe:**
   - Key: `MixpanelToken`
   - Type: `String`
   - Value: `JE_MIXPANEL_PROJECT_TOKEN_HIER`

**Voorbeeld:**
```xml
<key>MixpanelToken</key>
<string>abc123def456ghi789</string>
```

**⚠️ BELANGRIJK:** 
- Vervang `JE_MIXPANEL_PROJECT_TOKEN_HIER` met je echte Mixpanel Project Token
- Deze token is uniek per Mixpanel project

---

## Stap 4: Testen

1. **Build en run** je app
2. **Check de console** voor:
   ```
   ✅ Mixpanel initialized with token
   ```
3. **Ga naar Mixpanel Dashboard** → Live View
4. Je zou events moeten zien binnenkomen!

---

## 📊 Automatisch Getrackte Events

De volgende events worden automatisch getrackt:

### App Lifecycle
- ✅ `App Launched` - Bij app start
- ✅ `App Opened` - Bij elke app open

### Onboarding
- ✅ `Onboarding Started`
- ✅ `Onboarding Step Viewed`
- ✅ `Onboarding Answer`
- ✅ `Onboarding Commitment`
- ✅ `Onboarding Apps Selected`
- ✅ `Onboarding Difficulty Selected`
- ✅ `Onboarding Completed`
- ✅ `Onboarding Abandoned`

### Paywall
- ✅ `Paywall Shown`
- ✅ `Paywall Dismissed`
- ✅ `Purchase Attempted`
- ✅ `Purchase Completed`
- ✅ `Purchase Failed`

### Sessions
- ✅ `Session Started`
- ✅ `Session Completed`
- ✅ `Unlock Activated`
- ✅ `Unlock Expired`

### Engagement
- ✅ `Streak Updated`
- ✅ `Progress Viewed`
- ✅ `Settings Opened`
- ✅ `Difficulty Changed`

### Subscription
- ✅ `Subscription Cancelled`
- ✅ `Subscription Expired`
- ✅ `Subscription Restored`

---

## 👤 User Properties

De volgende user properties worden automatisch ingesteld:

- `age_group` - Leeftijdsgroep van gebruiker
- `referral_source` - Waar gebruiker van gehoord heeft
- `is_premium` - Of gebruiker premium heeft
- `difficulty_level` - Geselecteerde moeilijkheidsgraad
- `total_sessions` - Totaal aantal sessies
- `current_streak` - Huidige streak
- `platform` - "iOS"
- `app_version` - App versie

---

## 🎯 Belangrijke Mixpanel Features

### 1. **Funnels** (Conversie Tracking)
- Ga naar Mixpanel → Funnels
- Maak een funnel voor onboarding → paywall → purchase
- Zie waar gebruikers afhaken

### 2. **Retention** (Hoeveel gebruikers terugkomen)
- Ga naar Mixpanel → Retention
- Zie dag 1, 7, 30 retention rates

### 3. **Insights** (Event Analysis)
- Ga naar Mixpanel → Insights
- Analyseer welke events leiden tot conversie

### 4. **Flows** (User Journey)
- Ga naar Mixpanel → Flows
- Zie de user journey visueel

### 5. **Cohorts** (User Segmentation)
- Maak cohorts op basis van:
  - Premium vs Free users
  - Age groups
  - Referral sources
  - Difficulty levels

---

## 🔧 Handmatig Events Tracken

Als je handmatig een event wilt tracken:

```swift
// Simpel event
MixpanelManager.shared.track(event: "Custom Event")

// Event met properties
MixpanelManager.shared.track(event: "Custom Event", properties: [
    "property1": "value1",
    "property2": 123
])
```

---

## 📈 Best Practices

1. **Gebruik consistente event names:**
   - ✅ Goed: `Session Completed`
   - ❌ Slecht: `session_completed`, `SessionCompleted`, `sessionCompleted`

2. **Gebruik beschrijvende property names:**
   - ✅ Goed: `difficulty_level`, `total_sessions`
   - ❌ Slecht: `diff`, `sessions`

3. **Track belangrijke user actions:**
   - Elke keer dat gebruiker iets doet dat waarde heeft
   - Bijvoorbeeld: unlock, session complete, settings change

4. **Update user properties regelmatig:**
   - Na elke sessie
   - Bij subscription changes
   - Bij difficulty changes

---

## 🐛 Troubleshooting

### Mixpanel werkt niet

1. **Check of token correct is:**
   - Ga naar Info.plist
   - Check of `MixpanelToken` bestaat en correct is

2. **Check console logs:**
   - Zoek naar `✅ Mixpanel initialized with token`
   - Als je `⚠️ Mixpanel token not found` ziet, is de token niet correct ingesteld

3. **Check Mixpanel Dashboard:**
   - Ga naar Mixpanel → Live View
   - Events zouden binnen 1-2 minuten moeten verschijnen

### Events verschijnen niet in Mixpanel

1. **Check internet connectie**
2. **Wacht 1-2 minuten** (events worden gebatched)
3. **Check Mixpanel project** (zit je in het juiste project?)
4. **Check token** (is de token correct?)

### User properties worden niet bijgewerkt

- User properties worden alleen bijgewerkt als je `setUserProperties()` aanroept
- Dit gebeurt automatisch bij:
  - App launch
  - Session completion
  - Subscription changes
  - Difficulty changes

---

## 📚 Meer Info

- [Mixpanel iOS SDK Docs](https://developer.mixpanel.com/docs/ios)
- [Mixpanel Best Practices](https://help.mixpanel.com/hc/en-us/articles/115004613766-Best-practices-for-implementing-Mixpanel)
- [Mixpanel Event Tracking Guide](https://help.mixpanel.com/hc/en-us/articles/115004613766)

---

## ✅ Checklist

- [ ] Mixpanel account aangemaakt
- [ ] Project aangemaakt in Mixpanel
- [ ] Project Token gekopieerd
- [ ] Mixpanel SDK toegevoegd via SPM
- [ ] `MixpanelToken` toegevoegd aan Info.plist
- [ ] App gebuild en getest
- [ ] Events zichtbaar in Mixpanel Dashboard
- [ ] User properties correct ingesteld

---

**Klaar! 🎉 Je Mixpanel tracking is nu actief!**
