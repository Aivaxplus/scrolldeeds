# 🚀 ScrollDeeds - Final Submission Checklist

## ✅ AL GEDAAN

1. ✅ **Family Controls Approval** - Aangevraagd en goedgekeurd (email ontvangen)
2. ✅ **Code Optimalisaties** - Alle bugs gefixt, code schoon
3. ✅ **Privacy Policy & Terms** - Online op `https://scrolldeeds.lovable.app/privacy` en `/terms`
4. ✅ **Notificaties** - Professionele copy, variatie, correcte workflow
5. ✅ **Webhook Optimalisatie** - Snellere response times
6. ✅ **15 minuten unlock** - Alle copy correct
7. ✅ **3x dhikr** - Alle copy correct

---

## 📋 NOG TE DOEN (In Volgorde)

### 1. 🏗️ Xcode - Final Build Preparation

#### A. Provisioning Profile Check
- [ ] Open Xcode → Project → Signing & Capabilities
- [ ] Controleer dat **Release** configuratie **Apple Distribution** certificaat gebruikt
- [ ] Controleer dat **Family Controls (Production)** capability zichtbaar is
- [ ] Als niet zichtbaar: Xcode → Settings → Accounts → Download Manual Profiles

#### B. Build Number Verhogen
- [ ] Open `scrolldeeds.xcodeproj`
- [ ] Selecteer project → Target `scrolldeeds` → General tab
- [ ] Verhoog **Build** nummer (bijv. van `1` naar `2`)
- [ ] **Version** blijft `1.0` (voor eerste release)

#### C. Archive & Validate
- [ ] Product → Clean Build Folder (⇧⌘K)
- [ ] Selecteer **Any iOS Device (arm64)** als target
- [ ] Product → Archive
- [ ] Wacht tot Organizer opent
- [ ] Klik **Validate App...**
- [ ] Kies "App Store Connect"
- [ ] Volg wizard → Controleer dat validatie **slaagt** (geen errors)

---

### 2. 📸 App Store Assets Voorbereiden

#### A. Screenshots (VERPLICHT)
Maak screenshots voor:
- [ ] **6.7" iPhone** (iPhone 15 Pro Max) - Minimaal 2, maximaal 10
- [ ] **6.5" iPhone** (iPhone 14 Plus) - Minimaal 2, maximaal 10  
- [ ] **5.5" iPhone** (iPhone 8 Plus) - Minimaal 2, maximaal 10

**Screenshot Flow:**
1. Splash Screen
2. Onboarding (eerste scherm)
3. Dashboard (main screen met locked apps)
4. Dhikr Practice Session
5. Unlocked State (met timer)
6. Progress/Stats View
7. Settings

**Tips:**
- Gebruik Simulator → Device → Screenshot
- Of maak screenshots op fysiek device
- Zorg voor consistente styling (geen persoonlijke data)

#### B. App Preview Video (Optioneel maar Aanbevolen)
- [ ] Maak 15-30 seconden video die de flow demonstreert
- [ ] Toon: App selection → Dhikr → Unlock → Timer
- [ ] Upload als App Preview in App Store Connect

---

### 3. 📝 App Store Connect Metadata

#### A. App Information
- [ ] **Name**: ScrollDeeds
- [ ] **Subtitle**: Break free from doomscrolling
- [ ] **Category**: Lifestyle (of Health & Fitness)
- [ ] **Privacy Policy URL**: `https://scrolldeeds.lovable.app/privacy`
- [ ] **Support URL**: `https://scrolldeeds.lovable.app` (of email: `Sabri.makhoukhi@gmail.com`)
- [ ] **Marketing URL** (optioneel): `https://scrolldeeds.lovable.app`

#### B. App Description
```
ScrollDeeds helps you break free from mindless scrolling through Islamic mindfulness practices.

HOW IT WORKS:
• Lock distracting apps (TikTok, Instagram, etc.)
• Recite dhikr 3 times to unlock for 15 minutes
• AI verifies your recitation
• Track your progress and build streaks

FEATURES:
• App locking with Screen Time integration
• Voice-verified dhikr recitation
• 15-minute mindful unlock periods
• Progress tracking & daily stats
• Persistent alarms until you return

WHY SCROLLDEEDS:
Every second counts. ScrollDeeds helps you be intentional with your screen time by combining app restrictions with spiritual practice. Lock your distractions, unlock through mindfulness.

Perfect for Muslims who want to reduce phone addiction while staying connected to their faith.
```

#### C. Keywords
```
dhikr, mindfulness, screen time, app lock, Islamic, productivity, focus, distraction, phone addiction, self-control, spiritual practice
```

#### D. Promotional Text (Optioneel)
```
New in this version:
• Improved verification speed
• Professional notification system
• Enhanced user experience
```

---

### 4. 🔐 App Privacy Questionnaire

In App Store Connect → App Privacy:

- [ ] **Data Collection**: 
  - Selecteer "We collect data from this app"
  
- [ ] **Data Types**:
  - ✅ **App and Website Usage** (Family Controls)
    - Purpose: App Functionality
    - Linked to User: No
    - Used for Tracking: No
  
  - ✅ **Audio Data** (Microphone + Speech Recognition)
    - Purpose: App Functionality
    - Linked to User: No
    - Used for Tracking: No
    - Note: "Audio is sent to secure webhook for dhikr verification only, not stored"
  
  - ✅ **Device ID** (Notifications)
    - Purpose: App Functionality
    - Linked to User: No
    - Used for Tracking: No

- [ ] **Data Not Collected**: All other data types

---

### 5. 📤 Upload Build naar App Store Connect

#### A. Upload Archive
- [ ] In Xcode Organizer: Selecteer je archive
- [ ] Klik **Distribute App...**
- [ ] Kies **App Store Connect**
- [ ] Kies **Upload**
- [ ] Volg wizard (automatic signing, bitcode OFF)
- [ ] Wacht tot upload **compleet** is

#### B. Wacht op Processing
- [ ] Ga naar App Store Connect → My Apps → ScrollDeeds → TestFlight
- [ ] Wacht 10-30 minuten tot build status **"Processing"** → **"Ready to Test"**
- [ ] Als er errors zijn, fix ze en upload opnieuw

---

### 6. 🧪 TestFlight Testing (Aanbevolen)

#### A. Internal Testing
- [ ] In App Store Connect → TestFlight → Internal Testing
- [ ] Selecteer je build
- [ ] Voeg jezelf toe als tester
- [ ] Test op fysiek device
- [ ] Test alle features:
  - [ ] App selection & locking
  - [ ] Dhikr recording & verification
  - [ ] 15 minuten unlock timer
  - [ ] Automatische shield applicatie
  - [ ] Notifications (alarm workflow)
  - [ ] Progress tracking

#### B. External Testing (Optioneel)
- [ ] Nodig 1-2 vrienden/familie uit als testers
- [ ] Verzamel feedback
- [ ] Fix kritieke bugs indien nodig

---

### 7. 📋 App Store Review Information

#### A. Review Notes
```
Review Notes:
ScrollDeeds is a screen time management app that uses Family Controls to lock distracting apps. Users unlock apps by completing Islamic dhikr recitation (3 times), which is verified via secure webhook. The app grants 15 minutes of access after successful verification.

Testing Instructions:
1. Grant Family Controls permission when prompted
2. Select apps to lock (e.g., TikTok, Instagram)
3. Tap "Unlock Apps with Dhikr"
4. Record yourself reciting "Alhamdulillah" 3 times
5. Wait for verification (may take 5-15 seconds)
6. Apps unlock for 15 minutes
7. After 15 minutes, apps automatically relock

Note: The app requires microphone and speech recognition permissions for dhikr verification. All audio is sent to secure webhook for verification only and is not stored.
```

#### B. Demo Account (Niet Nodig)
- [ ] Geen demo account nodig (app werkt zonder login)

#### C. Contact Information
- [ ] **First Name**: Sabri
- [ ] **Last Name**: El Makhoukhi
- [ ] **Phone**: [Jouw telefoonnummer]
- [ ] **Email**: Sabri.makhoukhi@gmail.com

---

### 8. 🚀 Submit for Review

#### A. Final Checks
- [ ] Build is "Ready to Submit" in App Store Connect
- [ ] Alle metadata is ingevuld
- [ ] Screenshots zijn geüpload
- [ ] Privacy Policy & Terms URLs werken
- [ ] App Privacy questionnaire is compleet
- [ ] Review notes zijn geschreven

#### B. Submit
- [ ] In App Store Connect → App Store tab
- [ ] Kies **"1.0 Prepare for Submission"**
- [ ] Selecteer je build
- [ ] Controleer alle informatie
- [ ] Klik **"Submit for Review"**
- [ ] Bevestig submission

#### C. Wacht op Review
- [ ] Status wordt **"Waiting for Review"**
- [ ] Review duurt meestal **1-3 dagen**
- [ ] Je krijgt email bij status updates
- [ ] Als rejected: lees feedback en fix issues

---

## ⚠️ BELANGRIJKE NOTITIES

### Family Controls
- ✅ **Goedgekeurd** - Je hebt de email ontvangen
- ✅ **Production entitlement** is actief
- ⚠️ Zorg dat Xcode de **Production** capability ziet (niet alleen Development)

### Webhook Service
- ⚠️ Zorg dat n8n webhook **altijd operationeel** is
- ⚠️ Als webhook down is, kunnen gebruikers geen dhikr verifiëren
- ✅ Webhook is geoptimaliseerd voor snellere response

### Legal Documents
- ✅ Privacy Policy: `https://scrolldeeds.lovable.app/privacy`
- ✅ Terms of Service: `https://scrolldeeds.lovable.app/terms`
- ⚠️ Zorg dat deze URLs **altijd bereikbaar** zijn

### Testing
- ⚠️ Test **altijd** op fysiek device (niet alleen simulator)
- ⚠️ Test **alle features** voordat je submit
- ⚠️ Test **notificaties** (alarm workflow)

---

## 📊 ESTIMATED TIMELINE

1. **Xcode Build & Upload**: 30 minuten
2. **App Store Connect Setup**: 1-2 uur
3. **Screenshots Maken**: 1-2 uur
4. **TestFlight Testing**: 1-2 dagen (optioneel)
5. **App Review**: 1-3 dagen (Apple's kant)

**Totaal**: 2-3 dagen tot live (als alles goed gaat)

---

## 🎯 PRIORITEITEN

### HOGE PRIORITEIT (Moet voor submission)
1. ✅ Family Controls approval (al gedaan)
2. [ ] Archive & Validate in Xcode
3. [ ] Upload build naar App Store Connect
4. [ ] App Store metadata invullen
5. [ ] Screenshots maken
6. [ ] App Privacy questionnaire
7. [ ] Submit for Review

### MEDIUM PRIORITEIT (Aanbevolen)
- [ ] TestFlight testing
- [ ] App Preview video
- [ ] Promotional text

### LAGE PRIORITEIT (Later)
- [ ] Marketing materiaal
- [ ] Social media posts
- [ ] User feedback verzamelen

---

## ✅ CHECKLIST SAMENVATTING

**Voor Submission:**
- [ ] Build geüpload en gevalideerd
- [ ] Screenshots voor alle iPhone sizes
- [ ] App Store metadata compleet
- [ ] Privacy Policy & Terms URLs werken
- [ ] App Privacy questionnaire ingevuld
- [ ] Review notes geschreven
- [ ] Alles getest op fysiek device

**Klaar om te submitten?** ✅

---

**Laatste Update**: Na alle code optimalisaties en Family Controls approval
**Status**: Klaar voor final submission prep! 🚀

