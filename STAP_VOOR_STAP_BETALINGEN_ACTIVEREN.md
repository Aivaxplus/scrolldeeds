# Stap-voor-Stap: Betalingen Activeren voor ScrollDeeds 🚀

## 🎯 **DOEL:**
Je app live krijgen in de App Store zodat gebruikers kunnen betalen voor premium subscriptions.

---

## ✅ **STAP 1: Missing Metadata Oplossen (5-10 minuten)**

### 1.1 Ga naar App Store Connect
1. Open je browser
2. Ga naar: https://appstoreconnect.apple.com
3. Login met je Apple Developer account
4. Klik op **"ScrollDeeds"** (je app)

### 1.2 Open Subscriptions
1. In de linker sidebar, klik op **"Subscriptions"**
   - ⚠️ NIET "In-App Purchases" - dat is iets anders!
   - Je moet op **"Subscriptions"** klikken
2. Je ziet nu je subscriptions: "Premium Monthly" en "Premium Yearly"

### 1.3 Fix Monthly Subscription
1. Klik op **"Premium Monthly"** (of hoe je subscription heet)
2. Scroll naar beneden en vul in:

   **Subscription Information:**
   - **Name:** `Premium Monthly`
   - **Description:** 
     ```
     Unlock all premium features with monthly subscription. Access all difficulty levels (Easy, Medium, Hard, Extreme) and unlock your apps by completing dhikr recitation. Unlimited sessions and full access to all ScrollDeeds features.
     ```
   - **Subscription Group:** Zorg dat dit "ScrollDeeds Premium" is (of je groep naam)
   - **Subscription Duration:** 1 Month (moet al staan)
   - **Price:** €6.99 (controleer of dit klopt)

3. Scroll naar **"Subscription Benefits"** (optioneel maar aanbevolen):
   - Klik "+" om benefits toe te voegen:
     - "Unlock all difficulty levels"
     - "Unlimited dhikr sessions"
     - "Unlock apps with dhikr practice"
     - "Full access to all features"

4. Klik **"Save"** (rechtsboven)

### 1.4 Fix Yearly Subscription
1. Klik op **"Premium Yearly"** (of hoe je subscription heet)
2. Vul hetzelfde in als bij Monthly, maar:
   - **Name:** `Premium Yearly`
   - **Description:**
     ```
     Unlock all premium features with yearly subscription. Save 1 month free! Access all difficulty levels (Easy, Medium, Hard, Extreme) and unlock your apps by completing dhikr recitation. Unlimited sessions and full access to all ScrollDeeds features.
     ```
   - **Subscription Duration:** 1 Year (moet al staan)
   - **Price:** €69.99 (controleer of dit klopt)

3. Scroll naar **"Introductory Offers"**:
   - Klik **"+"** → **"Free Trial"**
   - **Duration:** 1 Month
   - **Price:** €0.00 (automatisch)
   - **Eligibility:** All New Subscribers
   - Klik **"Create"**

4. Scroll naar **"Subscription Benefits"** (optioneel):
   - Voeg dezelfde benefits toe als bij Monthly

5. Klik **"Save"** (rechtsboven)

### 1.5 Check Status
1. Ga terug naar de Subscriptions lijst
2. Check of beide subscriptions nu **"Ready to Submit"** status hebben
   - ✅ Als je "Ready to Submit" ziet → Perfect!
   - ❌ Als je nog steeds "Missing Metadata" ziet:
     - Refresh de pagina (F5 of Cmd+R)
     - Wacht 2-3 minuten en check opnieuw
     - Check of je alle velden hebt ingevuld

**✅ STAP 1 VOLTOOID WANNEER:**
- Beide subscriptions hebben "Ready to Submit" status
- Geen "Missing Metadata" meer

---

## ✅ **STAP 2: Build Archiveren in Xcode (10-15 minuten)**

### 2.1 Open Xcode
1. Open Xcode
2. Open je ScrollDeeds project
3. Wacht tot Xcode klaar is met indexeren

### 2.2 Selecteer Juiste Target
1. Bovenin Xcode, naast het play/pause icoon
2. Klik op het dropdown menu (waar nu waarschijnlijk "iPhone 15 Pro" of simulator staat)
3. Selecteer **"Any iOS Device"**
   - ⚠️ BELANGRIJK: Niet een simulator!
   - Je moet "Any iOS Device" selecteren

### 2.3 Check Version & Build Number
1. Klik op je project naam (bovenaan links in de navigator)
2. Selecteer het **"scrolldeeds"** target (onder "TARGETS")
3. Klik op het **"General"** tab
4. Check:
   - **Version:** 1.2 (of hoger)
   - **Build:** 8 (of verhoog naar 9 als je al build 8 hebt geüpload)
5. Als je Build moet verhogen:
   - Verander "8" naar "9" (of hoger)
   - Xcode vraagt om te bevestigen → Klik "OK"

### 2.4 Archive Maken
1. In Xcode menu: **Product** → **Archive**
   - Of druk: `Cmd + Shift + B` (maar dan moet je eerst "Any iOS Device" selecteren)
2. Wacht tot Xcode klaar is (kan 2-5 minuten duren)
3. Als het klaar is, opent automatisch het **Organizer** venster
   - Je ziet je archive met versie 1.2 en build nummer

### 2.5 Upload naar App Store Connect
1. In het Organizer venster, selecteer je archive (de nieuwste)
2. Klik **"Distribute App"** (rechtsboven)
3. Kies **"App Store Connect"** → Klik **"Next"**
4. Kies **"Upload"** → Klik **"Next"**
5. Check de opties:
   - ✅ "Include bitcode" (als het aangevinkt staat, laat het staan)
   - ✅ "Upload your app's symbols" (laat staan)
6. Klik **"Next"**
7. Kies je **Distribution Certificate** en **Provisioning Profile**
   - Xcode selecteert meestal automatisch de juiste
   - Als er een error is, volg de instructies
8. Klik **"Next"**
9. Review de informatie → Klik **"Upload"**
10. Wacht tot upload klaar is (5-15 minuten)
    - Je ziet een progress bar
    - Wanneer klaar: "Upload Successful" ✅

**✅ STAP 2 VOLTOOID WANNEER:**
- Upload is succesvol
- Je ziet "Upload Successful" bericht

---

## ✅ **STAP 3: Build Verwerken (15 minuten - 2 uur)**

### 3.1 Check App Store Connect
1. Ga naar: https://appstoreconnect.apple.com
2. Klik op **"ScrollDeeds"**
3. Klik op **"TestFlight"** tab (bovenaan)
4. Klik op **"iOS Builds"** (linker sidebar)
5. Je ziet je build met status:
   - ⏳ **"Processing"** → Apple is nog bezig
   - ✅ **"Ready to Submit"** → Klaar!

### 3.2 Wachten
- Apple verwerkt je build (15 minuten - 2 uur)
- Je krijgt een email wanneer het klaar is
- Check elke 15-30 minuten in App Store Connect

**✅ STAP 3 VOLTOOID WANNEER:**
- Build status is "Ready to Submit"
- Je ziet je build in de lijst

---

## ✅ **STAP 4: Build Koppelen aan App Versie (5 minuten)**

### 4.1 Ga naar App Store Tab
1. In App Store Connect → ScrollDeeds
2. Klik op **"App Store"** tab (bovenaan)
3. Je ziet je app versie (1.2 of hoger)

### 4.2 Selecteer of Maak Versie
- Als je al versie 1.2 hebt:
  - Klik op de versie
- Als je nog geen versie hebt:
  - Klik **"+"** → **"New Version"**
  - Versie: `1.2`
  - Klik **"Create"**

### 4.3 Koppel Build
1. Scroll naar **"Build"** sectie
2. Klik op **"+"** (of "Select a build before you submit")
3. Selecteer je nieuwe build (versie 1.2, build 8 of hoger)
4. Klik **"Done"**
5. Build is nu gekoppeld ✅

**✅ STAP 4 VOLTOOID WANNEER:**
- Build is zichtbaar in de "Build" sectie
- Geen errors of warnings

---

## ✅ **STAP 5: Subscriptions Koppelen (3 minuten)**

### 5.1 Ga naar In-App Purchases
1. In App Store Connect → ScrollDeeds → App Store tab
2. Scroll naar **"In-App Purchases and Subscriptions"** sectie
3. Klik **"Manage"**

### 5.2 Selecteer Subscriptions
1. Je ziet een lijst met subscriptions
2. Selecteer beide:
   - ✅ Premium Monthly
   - ✅ Premium Yearly
3. Beide moeten **"Ready to Submit"** status hebben
4. Als ze dat hebben → Klaar! ✅

**✅ STAP 5 VOLTOOID WANNEER:**
- Beide subscriptions zijn zichtbaar
- Status is "Ready to Submit"

---

## ✅ **STAP 6: Final Checks (5 minuten)**

### 6.1 Check App Information
1. In App Store Connect → ScrollDeeds → App Store tab
2. Scroll door alle secties en check:

   **App Information:**
   - [ ] Name: ScrollDeeds
   - [ ] Category: Lifestyle / Health & Fitness
   - [ ] Privacy Policy URL: Werkt (test de link)

   **Pricing and Availability:**
   - [ ] App is gratis (of betaald, jouw keuze)
   - [ ] Beschikbaar in alle landen (of specifieke landen)

   **Version Information:**
   - [ ] Description: Up-to-date
   - [ ] Keywords: Ingevuld
   - [ ] Screenshots: Toegevoegd (minimaal voor 6.7" iPhone)
   - [ ] App Icon: Toegevoegd

### 6.2 Review Information
1. Scroll naar **"App Review Information"**
2. Check:
   - [ ] **Contact Information:** Jouw email
   - [ ] **Phone Number:** Jouw telefoonnummer
   - [ ] **Demo Account:** Sandbox test account (optioneel maar aanbevolen)
   - [ ] **Notes:**
     ```
     Paywall verschijnt wanneer gebruiker op mic knop drukt om dhikr te doen.
     Gebruikers kunnen 1 maand free trial krijgen met yearly subscription (€69.99).
     Monthly subscription: €6.99.
     Test met sandbox account: [jouw test email]
     ```

### 6.3 Export Compliance
1. Scroll naar **"Export Compliance"**
2. Beantwoord de vragen:
   - Meestal: "No" op alle vragen (tenzij je encryption gebruikt)
   - Klik **"Save"**

**✅ STAP 6 VOLTOOID WANNEER:**
- Alle velden zijn ingevuld
- Geen errors of warnings
- Alles ziet er compleet uit

---

## ✅ **STAP 7: Submit voor Review (5 minuten)**

### 7.1 Final Check
1. Scroll naar boven in App Store Connect
2. Check of alles groen is:
   - ✅ Build: Gekoppeld
   - ✅ Subscriptions: Ready to Submit
   - ✅ App Information: Compleet
   - ✅ Screenshots: Toegevoegd
   - ✅ Privacy Policy: URL werkt

### 7.2 Submit
1. Klik op **"Submit for Review"** (rechtsboven, grote blauwe knop)
2. Check de popup:
   - Export Compliance: Geaccepteerd
   - Content Rights: Geaccepteerd
   - Advertising Identifier: Als je die gebruikt, accepteer
3. Klik **"Submit"**
4. Bevestig: Klik **"Submit"** nog een keer

### 7.3 Bevestiging
1. Je ziet: **"Your app has been submitted for review"** ✅
2. Status verandert naar: **"Waiting for Review"**
3. Je krijgt een email bevestiging

**✅ STAP 7 VOLTOOID WANNEER:**
- App is ingediend
- Status is "Waiting for Review"
- Email bevestiging ontvangen

---

## ⏰ **WAT NU?**

### Review Proces
- **Tijd:** 1-3 dagen (meestal 24-48 uur)
- **Status updates:** Je krijgt emails van Apple
- **Mogelijke statussen:**
  - ⏳ "Waiting for Review"
  - 🔍 "In Review"
  - ✅ "Ready for Sale" (goedgekeurd!)
  - ❌ "Rejected" (met feedback om te fixen)

### Als Goedgekeurd
1. Je krijgt email: "Your app is ready for sale"
2. In App Store Connect → Status: "Ready for Sale"
3. Kies wanneer je wilt releasen:
   - **"Release this version"** → Direct live
   - **"Schedule release"** → Kies datum/tijd
4. App is live → Gebruikers kunnen betalen! 🎉

### Als Afgewezen
1. Je krijgt email met feedback
2. Lees de feedback zorgvuldig
3. Fix de issues
4. Upload nieuwe build
5. Submit opnieuw

---

## 📊 **NA RELEASE: Betalingen Ontvangen**

### Wanneer Ontvang Je Geld?
- **Uitbetaling:** Maandelijks (meestal rond de 15e)
- **Minimum:** €10 (of equivalent)
- **Commissie:** 
  - Eerste jaar: 30% (Apple) / 70% (jij)
  - Na jaar 1: 15% (Apple) / 85% (jij)

### Waar Zie Je Betalingen?
1. App Store Connect → **"Sales and Trends"**
2. Je ziet:
   - Aantal subscriptions
   - Omzet
   - Uitbetalingen

### Voorbeeld
- 10 gebruikers kopen Monthly (€6.99) = €69.90
- Apple commissie (30%) = €20.97
- Jij ontvangt (70%) = €48.93

---

## 🆘 **TROUBLESHOOTING**

### "Missing Metadata" blijft staan?
- Refresh pagina (F5)
- Wacht 5-10 minuten
- Check of ALLE velden zijn ingevuld (Name, Description, Pricing)
- Check of subscriptions in dezelfde Subscription Group zitten

### Build upload faalt?
- Check of je "Any iOS Device" hebt geselecteerd
- Check of signing correct is (Automatic Signing)
- Check Xcode → Preferences → Accounts → Je Apple ID

### Subscriptions niet zichtbaar?
- Check of ze "Ready to Submit" zijn
- Check of metadata compleet is
- Refresh pagina

### Review afgewezen?
- Lees de feedback zorgvuldig
- Fix alle issues
- Upload nieuwe build
- Submit opnieuw

---

## ✅ **QUICK CHECKLIST**

**Voor Submit:**
- [ ] Missing Metadata opgelost (beide subscriptions "Ready to Submit")
- [ ] Build geüpload (versie 1.2, build 8+)
- [ ] Build status: "Ready to Submit"
- [ ] Build gekoppeld aan app versie
- [ ] Subscriptions gekoppeld
- [ ] App Information compleet
- [ ] Screenshots toegevoegd
- [ ] Privacy Policy URL werkt
- [ ] Review notes geschreven
- [ ] Submit voor review

**Na Submit:**
- [ ] Wacht op review (1-3 dagen)
- [ ] Check email voor updates
- [ ] Als goedgekeurd: Release!
- [ ] Betalingen ontvangen! 🎉

---

## 🚀 **JE BENT KLAAR!**

**Totaal tijd:** ~1-2 uur werk + 1-3 dagen wachten op review

**Volgende stappen:**
1. Volg alle stappen hierboven
2. Submit voor review
3. Wacht op Apple goedkeuring
4. Release app
5. Ontvang betalingen! 💰

**Laat weten als je hulp nodig hebt bij een specifieke stap!**

