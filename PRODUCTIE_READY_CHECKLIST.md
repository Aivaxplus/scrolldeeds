# ScrollDeeds - Productie Ready Checklist 🚀

## ✅ **WAT IS AL GEDAAN:**

### Code & Implementatie:
- ✅ RevenueCat SDK geïntegreerd
- ✅ Paywall geïmplementeerd (alleen bij mic knop)
- ✅ Free trial duidelijk zichtbaar in paywall
- ✅ Premium check op alle juiste plekken
- ✅ SubscriptionManager werkt
- ✅ Customer Center link in Settings
- ✅ Notificaties aangepast (60 notificaties, 4 uur cycle)
- ✅ Version: 1.2, Build: 8

### RevenueCat Setup:
- ✅ App geregistreerd in RevenueCat
- ✅ Products gesynchroniseerd
- ✅ API Key geconfigureerd: `appl_wfLidJYoHXcwgXbFKMDBZGNfxGH`
- ✅ Apple Subscription Key (P8) geüpload
- ✅ Issuer ID geconfigureerd

### App Store Connect:
- ✅ Banking & Tax actief
- ✅ Subscriptions aangemaakt (Monthly & Yearly)

---

## ⚠️ **WAT NOG MOET:**

### 1. Missing Metadata Oplossen (KRITIEK!)
**Status:** Subscriptions tonen "Missing Metadata" in App Store Connect

**Oplossing:**
1. Ga naar App Store Connect → ScrollDeeds
2. Klik op "Subscriptions" (niet "In-App Purchases")
3. Voor elke subscription (Monthly & Yearly):
   - Klik op de subscription naam
   - Vul in:
     - **Name:** Premium Monthly / Premium Yearly
     - **Description:** Volledige beschrijving van features
     - **Subscription Group:** Zorg dat beide in dezelfde groep zitten
     - **Pricing:** Controleer of prijzen correct zijn (€6.99 / €69.99)
   - Klik "Save"
4. Voor Yearly subscription:
   - Scroll naar "Introductory Offers"
   - Zorg dat "1 Month Free Trial" is toegevoegd
   - Status moet "Ready to Submit" zijn

**Check:**
- [ ] Monthly subscription heeft alle metadata
- [ ] Yearly subscription heeft alle metadata
- [ ] Free trial is geconfigureerd voor yearly
- [ ] Beide subscriptions zijn in dezelfde Subscription Group
- [ ] Status is "Ready to Submit" (niet meer "Missing Metadata")

---

### 2. Build Archiveren & Uploaden

**Stappen:**
1. Open Xcode
2. Selecteer "Any iOS Device" (niet simulator)
3. Product → Archive
4. Wacht tot archive klaar is
5. Klik "Distribute App"
6. Kies "App Store Connect"
7. Kies "Upload"
8. Volg de wizard
9. Wacht tot upload compleet is (5-15 minuten)

**Check:**
- [ ] Archive succesvol gemaakt
- [ ] Build geüpload naar App Store Connect
- [ ] Build status: "Processing" → "Ready to Submit" (15 min - 2 uur)

---

### 3. Build Koppelen aan App Versie

**Stappen:**
1. Ga naar App Store Connect → ScrollDeeds
2. Klik op "App Store" tab
3. Kies je versie (1.2) of maak nieuwe versie
4. Scroll naar "Build"
5. Klik "+" en selecteer je nieuwe build
6. Zorg dat build zichtbaar is

**Check:**
- [ ] Build is gekoppeld aan app versie
- [ ] Build status is "Ready to Submit"

---

### 4. Subscriptions Koppelen aan App Versie

**Stappen:**
1. In App Store Connect → ScrollDeeds → App Store tab
2. Scroll naar "In-App Purchases and Subscriptions"
3. Klik "Manage"
4. Selecteer beide subscriptions (Monthly & Yearly)
5. Zorg dat ze "Ready to Submit" zijn

**Check:**
- [ ] Subscriptions zijn zichtbaar in app versie
- [ ] Status is "Ready to Submit"
- [ ] Geen "Missing Metadata" meer

---

### 5. Final Checks Voor Submit

**App Information:**
- [ ] App description is up-to-date
- [ ] Screenshots zijn toegevoegd
- [ ] Privacy Policy URL werkt
- [ ] Terms of Service URL werkt (optioneel)

**Review Information:**
- [ ] Test account toegevoegd (sandbox account)
- [ ] Notes voor reviewer:
   ```
   Paywall verschijnt wanneer gebruiker op mic knop drukt om dhikr te doen.
   Gebruikers kunnen 1 maand free trial krijgen met yearly subscription.
   Test met sandbox account: [jouw test email]
   ```

**Check:**
- [ ] Alle velden zijn ingevuld
- [ ] Geen errors of warnings
- [ ] Build is "Ready to Submit"
- [ ] Subscriptions zijn "Ready to Submit"

---

### 6. Submit voor Review

**Stappen:**
1. In App Store Connect → ScrollDeeds → App Store tab
2. Scroll naar boven
3. Klik "Submit for Review"
4. Check alle informatie
5. Accepteer export compliance (als nodig)
6. Klik "Submit"

**Check:**
- [ ] App is ingediend voor review
- [ ] Status is "Waiting for Review"
- [ ] Email bevestiging ontvangen

---

## 🚨 **BELANGRIJKE CONTROLES:**

### RevenueCat:
- ✅ API Key: `appl_wfLidJYoHXcwgXbFKMDBZGNfxGH` (productie key)
- ✅ Products gesynchroniseerd
- ✅ Entitlement: "Scrolldeeds Pro"

### App Store Connect:
- ✅ Banking & Tax actief
- ⚠️ Missing Metadata moet opgelost worden
- ⚠️ Build moet geüpload worden
- ⚠️ Subscriptions moeten gekoppeld worden aan app versie

### Code:
- ✅ Paywall verschijnt alleen bij mic knop
- ✅ Free trial wordt duidelijk getoond
- ✅ Premium check werkt correct
- ✅ Geen gratis versie (alleen free trial)

---

## 📋 **QUICK CHECKLIST:**

**Voor Submit:**
- [ ] Missing Metadata opgelost
- [ ] Build geüpload (1.2, Build 8+)
- [ ] Build gekoppeld aan app versie
- [ ] Subscriptions gekoppeld aan app versie
- [ ] Test account toegevoegd
- [ ] Review notes geschreven
- [ ] Submit voor review

**Na Submit:**
- [ ] Wacht op review (1-3 dagen)
- [ ] Check email voor updates
- [ ] Als goedgekeurd: release!

---

## 🆘 **TROUBLESHOOTING:**

### "Missing Metadata" blijft staan?
- Check of alle velden zijn ingevuld (Name, Description, Pricing)
- Check of subscriptions in dezelfde Subscription Group zitten
- Refresh de pagina
- Wacht 5-10 minuten en check opnieuw

### Build upload faalt?
- Check of je "Any iOS Device" hebt geselecteerd
- Check of signing correct is
- Check of alle dependencies correct zijn

### Subscriptions niet zichtbaar?
- Check of ze "Ready to Submit" zijn
- Check of ze in dezelfde Subscription Group zitten
- Check of metadata compleet is

---

## ✅ **JE BENT BIJNA KLAAR!**

**Volgende stappen:**
1. Missing Metadata oplossen (5 minuten)
2. Build archiveren & uploaden (15 minuten)
3. Build koppelen aan app versie (2 minuten)
4. Subscriptions koppelen (2 minuten)
5. Submit voor review (5 minuten)

**Totaal: ~30 minuten tot submit!**

---

**Laat weten als je hulp nodig hebt bij een specifieke stap! 🚀**

