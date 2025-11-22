# 🎉 Approval Ontvangen - Final Steps!

## ✅ GEDAAN
- [x] Screenshots georganiseerd
- [x] Family Controls approval ontvangen

---

## 🚀 NU KUNNEN WE SUBMITTEN!

### 1. 🏗️ Xcode - Build & Validate (30 minuten)

#### A. Provisioning Profile Check
- [ ] Open Xcode → Project `scrolldeeds.xcodeproj`
- [ ] Selecteer project → Target `scrolldeeds` → Tab **Signing & Capabilities**
- [ ] Check **Release** configuratie (rechtsboven dropdown)
- [ ] Verify:
  - ✅ **Team**: "sabri El Makhoukhi" (of jouw team)
  - ✅ **Bundle Identifier**: `com.scrolldeeds.app`
  - ✅ **Signing Certificate**: "Apple Distribution: ..." (NIET Development!)
  - ✅ **Family Controls** capability is zichtbaar (zou nu Production moeten zijn)

**Als Family Controls (Production) niet zichtbaar is:**
- [ ] Xcode → Settings (⌘,) → Accounts tab
- [ ] Selecteer je Apple ID
- [ ] Klik tandwiel-icoon → **Download Manual Profiles**
- [ ] Wacht tot download compleet is
- [ ] Herstart Xcode
- [ ] Check opnieuw

#### B. Build Number Verhogen
- [ ] In Xcode: Project → Target `scrolldeeds` → **General** tab
- [ ] **Version**: `1.0` (blijft zo voor eerste release)
- [ ] **Build**: Verhoog van `1` naar `2` (of hoger als je al builds hebt gemaakt)
- [ ] Dit zorgt dat App Store Connect de nieuwe build accepteert

#### C. Clean & Archive
- [ ] **Product** → **Clean Build Folder** (⇧⌘K)
- [ ] Wacht tot clean compleet is
- [ ] Selecteer **Any iOS Device (arm64)** als target (linksboven, NIET simulator!)
- [ ] **Product** → **Archive**
- [ ] Wacht 2-5 minuten tot archive compleet is
- [ ] Organizer venster opent automatisch

#### D. Validate App
- [ ] In Organizer: Selecteer je nieuwe archive (meest recente datum/tijd)
- [ ] Klik **Validate App...**
- [ ] Kies **"App Store Connect"**
- [ ] Klik **Next**
- [ ] Selecteer **"Automatically manage signing"** (of je team als dat al geselecteerd is)
- [ ] Klik **Next**
- [ ] Wacht tot validatie compleet is

**✅ Als validatie slaagt:**
- Je ziet "Validation Successful"
- Klaar voor upload!

**❌ Als validatie faalt:**
- Lees de error messages
- Meest voorkomende: Provisioning profile issues
- Fix errors en archive opnieuw

---

### 2. 📤 Upload Build naar App Store Connect (15 minuten)

#### A. Distribute App
- [ ] In Organizer: Selecteer je archive (die net gevalideerd is)
- [ ] Klik **Distribute App...**
- [ ] Kies **"App Store Connect"**
- [ ] Klik **Next**
- [ ] Kies **"Upload"** (niet Export)
- [ ] Klik **Next**

#### B. Distribution Options
- [ ] **Distribution options**: Laat alles default (bitcode OFF is normaal)
- [ ] Klik **Next**
- [ ] **App Thinning**: "All compatible device variants" (default)
- [ ] Klik **Next**

#### C. Signing
- [ ] **"Automatically manage signing"** (of selecteer je team)
- [ ] Klik **Next**
- [ ] Review summary
- [ ] Klik **Upload**
- [ ] Wacht tot upload compleet is (kan 5-15 minuten duren)

**✅ Upload succesvol:**
- Je ziet "Upload Successful"
- Build wordt nu verwerkt door Apple

---

### 3. ⏳ Wacht Op Build Processing (10-30 minuten)

#### A. Check App Store Connect
- [ ] Ga naar [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Login met je Apple Developer account
- [ ] Ga naar **My Apps** → **ScrollDeeds**
- [ ] Klik tab **TestFlight**
- [ ] Wacht tot je build verschijnt

#### B. Build Status
- [ ] Status begint als **"Processing"**
- [ ] Na 10-30 minuten wordt het **"Ready to Test"**
- [ ] Als status **"Invalid Binary"** of error: lees de error en fix

**⚠️ Als build processing faalt:**
- Check email voor details
- Meestal: Missing entitlements, code signing issues
- Fix in Xcode en upload opnieuw

---

### 4. 📸 Screenshots Uploaden (15 minuten)

#### A. Ga Naar App Store Tab
- [ ] In App Store Connect → ScrollDeeds
- [ ] Klik tab **App Store** (niet TestFlight)
- [ ] Klik **"1.0 Prepare for Submission"** (of "+ Version" als eerste keer)

#### B. Upload Screenshots
- [ ] Scroll naar **Screenshots** sectie
- [ ] **6.7" iPhone** (iPhone 15 Pro Max):
  - [ ] Klik **"+"** of drag & drop
  - [ ] Upload alle screenshots voor 6.7"
  - [ ] Zorg dat volgorde klopt (eerste = splash, laatste = progress)
  
- [ ] **6.5" iPhone** (iPhone 14 Plus):
  - [ ] Klik **"+"** of drag & drop
  - [ ] Upload alle screenshots voor 6.5"
  
- [ ] **5.5" iPhone** (iPhone 8 Plus):
  - [ ] Klik **"+"** of drag & drop
  - [ ] Upload alle screenshots voor 5.5"

**✅ Check:**
- [ ] Alle screenshots zijn geüpload
- [ ] Geen errors of warnings
- [ ] Screenshots zijn scherp en duidelijk

---

### 5. 📝 App Store Metadata Invullen (30 minuten)

#### A. App Information
- [ ] **Name**: ScrollDeeds
- [ ] **Subtitle**: Break free from doomscrolling
- [ ] **Category**: Lifestyle (of Health & Fitness)
- [ ] **Privacy Policy URL**: `https://scrolldeeds.lovable.app/privacy`
- [ ] **Support URL**: `https://scrolldeeds.lovable.app` (of email: `Sabri.makhoukhi@gmail.com`)
- [ ] **Marketing URL** (optioneel): `https://scrolldeeds.lovable.app`

#### B. App Description
**Plak deze tekst:**

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

- [ ] Plak in **Description** veld
- [ ] Check spelling en formatting

#### C. Keywords
**Plak deze keywords (max 100 karakters):**

```
dhikr, mindfulness, screen time, app lock, Islamic, productivity, focus, distraction, phone addiction, self-control, spiritual practice
```

- [ ] Plak in **Keywords** veld
- [ ] Check dat het onder 100 karakters is

#### D. Promotional Text (Optioneel)
```
New in this version:
• Improved verification speed
• Professional notification system
• Enhanced user experience
• 15-minute mindful unlock periods
```

- [ ] Plak in **Promotional Text** veld (optioneel)

---

### 6. 🔒 App Privacy Questionnaire (15 minuten)

#### A. Open App Privacy
- [ ] In App Store Connect → ScrollDeeds
- [ ] Klik **App Privacy** (in linker menu of bij App Information)
- [ ] Klik **"Get Started"** of **"Edit"**

#### B. Vul In
- [ ] **Data Collection**: Selecteer **"We collect data from this app"**

- [ ] **App and Website Usage**:
  - [ ] Vink aan
  - [ ] Purpose: **App Functionality**
  - [ ] Linked to User: **No**
  - [ ] Used for Tracking: **No**

- [ ] **Audio Data**:
  - [ ] Vink aan
  - [ ] Purpose: **App Functionality**
  - [ ] Linked to User: **No**
  - [ ] Used for Tracking: **No**
  - [ ] Note: "Audio sent to secure webhook for verification only, not stored"

- [ ] **Device ID**:
  - [ ] Vink aan (onder Identifiers)
  - [ ] Purpose: **App Functionality**
  - [ ] Linked to User: **No**
  - [ ] Used for Tracking: **No**

- [ ] **All other data types**: Selecteer **"Data Not Collected"**

- [ ] Klik **Save** of **Done**

---

### 7. 📋 Review Information (10 minuten)

#### A. Review Notes
**Plak deze tekst:**

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

- [ ] Plak in **Review Notes** veld
- [ ] Check spelling

#### B. Contact Information
- [ ] **First Name**: Sabri
- [ ] **Last Name**: El Makhoukhi
- [ ] **Phone**: [Jouw telefoonnummer]
- [ ] **Email**: Sabri.makhoukhi@gmail.com

---

### 8. 🎯 Build Selecteren

#### A. Selecteer Build
- [ ] In App Store Connect → ScrollDeeds → App Store tab
- [ ] Scroll naar **Build** sectie
- [ ] Klik **"+"** of **"Select a build"**
- [ ] Selecteer je build (versie 1.0, build 2 of hoger)
- [ ] Build moet status **"Ready to Submit"** hebben

**⚠️ Als build niet zichtbaar is:**
- Wacht nog 10-15 minuten (processing kan langer duren)
- Check TestFlight tab of build daar staat
- Als >1 uur: check email voor errors

---

### 9. ✅ Final Checks (5 minuten)

**Checklist voor submission:**
- [ ] Build is geselecteerd en "Ready to Submit"
- [ ] Alle screenshots zijn geüpload (minimaal 2 per device size)
- [ ] App description is ingevuld
- [ ] Keywords zijn ingevuld
- [ ] Privacy Policy URL werkt (`https://scrolldeeds.lovable.app/privacy`)
- [ ] Terms of Service URL werkt (`https://scrolldeeds.lovable.app/terms`)
- [ ] Support URL is ingevuld
- [ ] App Privacy questionnaire is compleet
- [ ] Review notes zijn geschreven
- [ ] Contact information is ingevuld

---

### 10. 🚀 Submit for Review!

#### A. Submit
- [ ] In App Store Connect → ScrollDeeds → App Store tab
- [ ] Scroll naar boven
- [ ] Klik **"Submit for Review"** (rechtsboven)
- [ ] Bevestig dat alles klopt
- [ ] Bevestig submission

#### B. Status
- [ ] Status wordt **"Waiting for Review"**
- [ ] Je krijgt email bevestiging
- [ ] Review duurt meestal **1-3 dagen**

#### C. Wacht Op Review
- [ ] Check email voor status updates
- [ ] Check App Store Connect voor updates
- [ ] Als **"In Review"**: App wordt nu beoordeeld
- [ ] Als **"Approved"**: 🎉 App is live!
- [ ] Als **"Rejected"**: Lees feedback en fix issues

---

## ⏰ TIMELINE

**Vandaag:**
- Build & upload: **30 min**
- Screenshots uploaden: **15 min**
- Metadata invullen: **30 min**
- Privacy questionnaire: **15 min**
- Review notes: **10 min**
- Submit: **5 min**
- **Totaal**: ~2 uur werk

**Na Submission:**
- App Review: **1-3 dagen** (Apple's kant)
- Als approved: App is **live** op App Store! 🎉

---

## 🎯 VOLGENDE STAP

**Begin nu met:**
1. ✅ Xcode → Build & Validate (30 min)
2. ✅ Upload build (15 min)
3. ✅ Wacht op processing (10-30 min)
4. ✅ Screenshots uploaden (15 min)
5. ✅ Metadata invullen (30 min)
6. ✅ Submit for Review! 🚀

---

## 💡 TIPS

- **Neem je tijd**: Haast je niet, check alles goed
- **Test build eerst**: Als je tijd hebt, test via TestFlight eerst
- **Check emails**: Apple stuurt belangrijke updates via email
- **Wees geduldig**: Review kan 1-3 dagen duren

---

**Status**: Approval ontvangen! 🎉 Klaar om te submitten!

**Veel succes!** 🚀

