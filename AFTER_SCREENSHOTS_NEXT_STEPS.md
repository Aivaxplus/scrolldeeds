# 📸 Screenshots Klaar - Wat Nu?

## ✅ GEDAAN
- [x] Screenshots gemaakt voor alle iPhone sizes

---

## 🎯 VOLGENDE STAPPEN (In Volgorde)

### 1. 📁 Screenshots Organiseren (15 minuten)

**Check:**
- [ ] Screenshots zijn scherp en duidelijk
- [ ] Geen persoonlijke data zichtbaar
- [ ] Geen bugs of errors zichtbaar
- [ ] Goede visuele hiërarchie

**Organiseer:**
```
Screenshots/
├── 6.7-inch/ (iPhone 15 Pro Max)
│   ├── 01-splash.png
│   ├── 02-onboarding.png
│   ├── 03-dashboard-locked.png
│   ├── 04-app-selection.png
│   ├── 05-dhikr-practice.png
│   ├── 06-dashboard-unlocked.png
│   └── 07-progress.png
├── 6.5-inch/ (iPhone 14 Plus)
│   └── (zelfde structuur)
└── 5.5-inch/ (iPhone 8 Plus)
    └── (zelfde structuur)
```

- [ ] Screenshots georganiseerd per device size
- [ ] Bestanden duidelijk genaamd
- [ ] Klaar voor upload naar App Store Connect

---

### 2. 📝 App Store Connect Metadata Voorbereiden (1-2 uur)

**Je kunt dit alvast invullen in App Store Connect:**

#### A. App Information
- [ ] **Name**: ScrollDeeds
- [ ] **Subtitle**: Break free from doomscrolling
- [ ] **Category**: Lifestyle (of Health & Fitness)
- [ ] **Privacy Policy URL**: `https://scrolldeeds.lovable.app/privacy`
- [ ] **Support URL**: `https://scrolldeeds.lovable.app` (of email: `Sabri.makhoukhi@gmail.com`)
- [ ] **Marketing URL** (optioneel): `https://scrolldeeds.lovable.app`

#### B. App Description
**Kopieer deze tekst:**

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

- [ ] App description gekopieerd en klaar om te plakken

#### C. Keywords (max 100 karakters)
```
dhikr, mindfulness, screen time, app lock, Islamic, productivity, focus, distraction, phone addiction, self-control, spiritual practice
```

- [ ] Keywords voorbereid

#### D. Promotional Text (Optioneel)
```
New in this version:
• Improved verification speed
• Professional notification system
• Enhanced user experience
• 15-minute mindful unlock periods
```

- [ ] Promotional text geschreven (optioneel)

---

### 3. 🔒 App Privacy Questionnaire Voorbereiden (30 minuten)

**Antwoorden die je nodig hebt:**

1. **Data Collection**: 
   - Selecteer: "We collect data from this app"

2. **Data Types**:
   - ✅ **App and Website Usage** (Family Controls)
     - Purpose: App Functionality
     - Linked to User: No
     - Used for Tracking: No
   
   - ✅ **Audio Data** (Microphone + Speech Recognition)
     - Purpose: App Functionality
     - Linked to User: No
     - Used for Tracking: No
     - Note: "Audio sent to secure webhook for verification only, not stored"
   
   - ✅ **Device ID** (Notifications)
     - Purpose: App Functionality
     - Linked to User: No
     - Used for Tracking: No

3. **Data Not Collected**: 
   - All other data types

- [ ] Privacy questionnaire antwoorden voorbereid

---

### 4. 📋 Review Notes Schrijven (15 minuten)

**Kopieer deze tekst:**

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

Contact:
Email: Sabri.makhoukhi@gmail.com
```

- [ ] Review notes gekopieerd en klaar

---

### 5. ⏳ Check Family Controls Approval Status

**Check deze plekken:**

- [ ] **Email inbox** (ook spam folder)
  - Zoek naar email van "Apple Developer" of "no-reply@apple.com"
  - Subject: "Family Controls & Personal Device Usage Entitlement Request"
  
- [ ] **App Store Connect**
  - Ga naar: Certificates, IDs & Profiles → Identifiers
  - Zoek: `com.scrolldeeds.app`
  - Check of **Family Controls** capability zichtbaar is met **Production** status

- [ ] **Apple Developer Portal**
  - Ga naar: [developer.apple.com](https://developer.apple.com)
  - Check je account status

**Als nog geen approval:**
- [ ] Wacht 1-3 werkdagen (normale wachttijd)
- [ ] Als >1 week: contact Apple Developer Support

---

## 🚫 WAT JE NOG NIET KUNT DOEN (Tot Approval)

- ❌ Build valideren in Xcode (fails zonder Production entitlement)
- ❌ Build uploaden naar App Store Connect
- ❌ Screenshots uploaden (kan wel, maar build moet eerst klaar zijn)
- ❌ Submit for Review

---

## ✅ WAT JE WEL KUNT DOEN (Nu)

- ✅ Screenshots organiseren
- ✅ App Store Connect metadata invullen
- ✅ Privacy questionnaire voorbereiden
- ✅ Review notes schrijven
- ✅ Alles voorbereiden zodat je direct kunt submitten zodra approval is

---

## 📅 TIMELINE

**Nu (Zonder Approval):**
- Screenshots organiseren: **15 min**
- Metadata schrijven: **1-2 uur**
- Privacy questionnaire: **30 min**
- Review notes: **15 min**
- **Totaal**: ~2-3 uur werk

**Na Approval:**
- Build & upload: **30 min**
- Screenshots uploaden: **15 min**
- Submit: **15 min**
- **Totaal**: ~1 uur werk

**App Review (Apple):**
- **1-3 dagen** wachttijd

---

## 🎯 VOLGENDE STAP

**Begin nu met:**
1. ✅ Screenshots organiseren (15 min)
2. ✅ App Store Connect openen en metadata invullen (1-2 uur)
3. ⏳ Wacht op Family Controls approval

**Zodra approval is:**
4. Build & validate in Xcode
5. Upload build naar App Store Connect
6. Screenshots uploaden
7. Submit for Review

---

## 💡 TIP

**Je kunt alvast in App Store Connect:**
- App informatie invullen
- Description toevoegen
- Keywords toevoegen
- Privacy questionnaire invullen

**Dit bespaart tijd zodra je approval hebt!**

---

**Status**: Screenshots klaar! 🎉 Nu metadata voorbereiden en wachten op approval.

