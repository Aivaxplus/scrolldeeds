# 📱 Versie 1.0.1 Release Guide - Stap voor Stap

## ✅ Wat is al gedaan

- ✅ "Skip for now" button verwijderd
- ✅ Share app functie toegevoegd
- ✅ Analytics tracking (lokaal + TelemetryDeck ready)
- ✅ Feedback popup na 3 unlocks
- ✅ Custom navigation bar
- ✅ Copy verbeterd

## 📋 Stap-voor-Stap Checklist

### **STAP 1: Versie Nummer Verhogen in Xcode**

1. Open Xcode
2. Selecteer project **scrolldeeds** in linker sidebar
3. Selecteer target **scrolldeeds** (onder TARGETS)
4. Ga naar tab **General**
5. In sectie **Identity**:
   - **Version**: Verander van `1.1` naar `1.0.1`
   - **Build**: Verhoog met +1 (bijv. `6` → `7`)
6. Sla op (⌘S)

### **STAP 2: TelemetryDeck Setup (Optioneel - kan later)**

Als je nu TelemetryDeck wilt toevoegen:

1. **Account aanmaken:**
   - Ga naar https://telemetrydeck.com
   - Maak gratis account
   - Maak nieuwe app aan
   - Kopieer je **App ID**

2. **SDK toevoegen in Xcode:**
   - Xcode → Project → **Package Dependencies** tab
   - Klik **+** (Add Package)
   - URL: `https://github.com/TelemetryDeck/SwiftClient`
   - Kies **Up to Next Major Version** → `3.0.0`
   - Klik **Add Package**
   - Selecteer **TelemetryClient** → **Add Package**

3. **Code activeren:**
   - Open `scrolldeedsApp.swift`
   - Voeg toe bovenaan: `import TelemetryClient`
   - In `didFinishLaunchingWithOptions`, na `AnalyticsManager.shared.trackAppLaunch()`:
   ```swift
   let configuration = TelemetryManagerConfiguration(
       appID: "YOUR_APP_ID_HIER"
   )
   TelemetryManager.start(with: configuration)
   ```
   - Open `AnalyticsManager.swift`
   - Uncomment: `import TelemetryClient`
   - Uncomment in `sendTelemetryDeckEvent`: `TelemetryManager.send(name, with: parameters)`

**Of skip dit nu en doe het later** - de app werkt ook zonder TelemetryDeck!

### **STAP 3: Test de App Lokaal**

1. **Run de app** (⌘R) op je iPhone of Simulator
2. **Test alle nieuwe features:**
   - ✅ Navigatie bar (Progress links, Settings rechts)
   - ✅ Share functie in Settings
   - ✅ Feedback popup (na 3 dhikr sessies)
   - ✅ Geen "Skip for now" bij Family Controls
   - ✅ Verbeterde copy

3. **Fix eventuele bugs** die je tegenkomt

### **STAP 4: Nieuwe Screenshots Maken**

1. **Run app op iPhone** (niet Simulator - voor beste kwaliteit)
2. **Maak screenshots van:**
   - Home screen (met nieuwe navigation bar)
   - Progress view (met nieuwe line chart)
   - Settings (met share button)
   - Onboarding screens (als nodig)

3. **Organiseer screenshots:**
   - Maak mappen: `Screenshots/iPhone 6.7"`, `Screenshots/iPhone 6.5"`, etc.
   - Zorg dat alle sizes kloppen (zie App Store Connect requirements)

### **STAP 5: Archive en Upload**

1. **Selecteer "Any iOS Device"** in Xcode (bovenin, naast Play button)
2. **Product → Archive** (of ⌘B dan Product → Archive)
3. **Wacht** tot Organizer opent
4. **Selecteer nieuwe archive** (versie 1.0.1, build 7)
5. **Klik "Distribute App"**
6. **Kies "App Store Connect"**
7. **Kies "Upload"**
8. **Volg wizard:**
   - Bevestig opties
   - Check signing (moet "Apple Distribution" zijn)
   - Klik **Upload**
9. **Wacht** tot upload compleet is (kan 5-15 minuten duren)

### **STAP 6: App Store Connect - Versie 1.0.1**

1. **Ga naar App Store Connect:**
   - https://appstoreconnect.apple.com
   - Login met je Apple Developer account

2. **Navigeer naar ScrollDeeds:**
   - **My Apps** → **ScrollDeeds**
   - **App Store** → **iOS App**

3. **Maak nieuwe versie:**
   - Klik **"+ Version or Platform"**
   - Versie: `1.0.1`
   - Klik **Create**

4. **Vul metadata in:**
   - **Promotional Text:**
     ```
     Break scrolling habits with mindful dhikr. Lock apps, unlock 15 minutes with 3 recitations. Share with friends—now easier than ever.
     ```
   
   - **What's New:**
     ```
     What's New in Version 1.0.1

     ✨ New Features
     • Share ScrollDeeds with friends directly from Settings
     • Beautiful new navigation bar for easier access
     • Feedback request after your first 3 sessions

     🎨 Improvements
     • Cleaner, more intuitive interface
     • Improved copy throughout the app
     • Better user experience and flow

     🔒 Core Experience
     Everything you love remains the same:
     • Lock distracting apps with Family Controls
     • Unlock 15 minutes by reciting dhikr 3 times
     • Automatic reminders keep you accountable
     • 100% local and private—no accounts needed

     Thank you for using ScrollDeeds. Your feedback helps us improve!
     ```
   
   - **Version:** `1.0.1`
   - **Copyright:** `© 2025 Sabri El Makhoukhi. All rights reserved.`

5. **Upload Screenshots:**
   - Scroll naar **App Preview and Screenshots**
   - Upload nieuwe screenshots voor alle iPhone sizes
   - Zorg dat ze de nieuwe features tonen

6. **Selecteer Build:**
   - Scroll naar **Build** sectie
   - Klik **+** naast "Build"
   - Selecteer build **1.0.1 (7)** (of hoger)
   - Klik **Done**

### **STAP 7: Submit for Review**

1. **Check alles:**
   - ✅ Alle metadata ingevuld
   - ✅ Screenshots geüpload
   - ✅ Build geselecteerd
   - ✅ Export Compliance ingevuld (als nodig)

2. **Klik "Add for Review"** (rechtsboven)
3. **Beantwoord review vragen** (als gevraagd)
4. **Klik "Submit for Review"**
5. **Wacht op Apple Review** (meestal 24-48 uur)

### **STAP 8: Na Goedkeuring**

1. **Je krijgt email** van Apple wanneer goedgekeurd
2. **Release optie kiezen:**
   - **Automatisch**: App gaat live binnen 24 uur
   - **Handmatig**: Je zet zelf live wanneer je wilt

3. **App is live!** 🎉

## ⚠️ Belangrijke Notities

- **TelemetryDeck is optioneel** - app werkt ook zonder
- **Test goed** voordat je upload
- **Screenshots moeten up-to-date** zijn
- **Build nummer moet altijd omhoog** (niet alleen versie)

## 🆘 Problemen?

- **Build errors?** → Check signing & capabilities
- **Upload fails?** → Check internet & Apple Developer account
- **Review rejected?** → Check email voor details

## ✅ Klaar!

Na deze stappen is versie 1.0.1 live op de App Store!

