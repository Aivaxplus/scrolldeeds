# Apple Subscription Key Setup - RevenueCat

## ⚠️ Error Oplossen

Je krijgt deze error omdat RevenueCat de Apple Subscription Key nodig heeft om met App Store Connect te communiceren.

**Error:** "Both Apple's Subscription Key ID and Private Key must be provided"

---

## ✅ Stap 1: Genereer P8 Key in App Store Connect

### 1.1 Ga naar App Store Connect

1. Open [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Login met je Apple Developer account
3. Klik op je naam (rechtsboven)
4. Selecteer **"Users and Access"**

### 1.2 Ga naar Keys

1. In het linker menu, klik op **"Keys"**
2. Klik op tab **"Keys"** (bovenaan)

### 1.3 Maak nieuwe key

1. Klik op **"+"** knop (linksboven, naast "Keys")
2. Vul in:
   - **Key Name:** `RevenueCat Subscription Key` (of een andere naam)
   - **Access:** Selecteer **"App Manager"** of **"Admin"**
3. Klik **"Generate"**

### 1.4 Download P8 Key

⚠️ **BELANGRIJK:** Je kunt deze key maar 1x downloaden!

1. Klik op **"Download"** knop
2. Het bestand wordt gedownload als: `AuthKey_XXXXXXXX.p8`
   - Bijvoorbeeld: `AuthKey_YSYR6LN4R2.p8`
3. **Bewaar dit bestand veilig!** Je kunt het niet opnieuw downloaden.

### 1.5 Noteer Key ID en Issuer ID

Na het genereren zie je:
- **Key ID:** Bijvoorbeeld `YSYR6LN4R2` (10 karakters)
- **Issuer ID:** Bijvoorbeeld `691fae94-1da3-42e7-9ca6-f4bd4d13609b` (UUID)

⚠️ **Noteer beide!** Je hebt ze nodig in RevenueCat.

---

## ✅ Stap 2: Upload P8 Key in RevenueCat

### 2.1 Ga naar RevenueCat Dashboard

1. Open [app.revenuecat.com](https://app.revenuecat.com)
2. Selecteer project: **Scrolldeeds**
3. Ga naar **"Apps & providers"** in linker menu

### 2.2 Configureer App Store App

1. Je ziet waarschijnlijk al "Scrolldeeds (App Store)" of klik **"+ New"** → **"App Store app"**

2. **Vul app details in:**
   - **App name:** `Scrolldeeds (App Store)`
   - **App Bundle ID:** `com.scrolldeeds.app`
     - ⚠️ Dit moet exact overeenkomen met je Xcode project!

### 2.3 Upload P8 Key

1. **P8 key file uploaden:**
   - Klik op het grijze vakje waar "YSYR6LN4R2.p8" staat
   - Of klik op **"Choose File"** of **"Upload"**
   - Selecteer het gedownloade `.p8` bestand
   - Bijvoorbeeld: `AuthKey_YSYR6LN4R2.p8`

2. **Vul Key ID in:**
   - **Key ID:** `YSYR6LN4R2` (of jouw Key ID)
   - Dit is de 10-karakter code die je zag in App Store Connect

3. **Vul Issuer ID in:**
   - **Issuer ID:** `691fae94-1da3-42e7-9ca6-f4bd4d13609b` (of jouw Issuer ID)
   - Dit is de UUID die je zag in App Store Connect

### 2.4 Save

1. Klik op **"Save changes"** knop (rechtsonder)
2. ✅ Error zou nu weg moeten zijn!

---

## ✅ Stap 3: Verify Setup

### Check of alles klopt:

1. **In RevenueCat:**
   - Ga naar "Apps & providers"
   - Je app zou moeten verschijnen zonder errors
   - Status zou "Connected" of "Active" moeten zijn

2. **Test:**
   - Nu kun je products toevoegen!
   - Ga naar "Product catalog" → "Products"
   - Klik "+ New" om products toe te voegen

---

## 🔑 Belangrijke Informatie

### Bundle ID Check

⚠️ **Controleer je Bundle ID:**

1. Open Xcode
2. Selecteer je project
3. Selecteer target: `scrolldeeds`
4. Ga naar "General" tab
5. Check **"Bundle Identifier"**
6. Dit moet overeenkomen met wat je in RevenueCat invult!

**Als je Bundle ID anders is:**
- Bijvoorbeeld: `com.scrolldeeds` in plaats van `com.scrolldeeds.app`
- Gebruik dan de juiste Bundle ID in RevenueCat!

---

## 🆘 Troubleshooting

### P8 Key niet gevonden?

**Oplossing:**
- Check je Downloads folder
- Zoek naar bestand met `.p8` extensie
- Als je het niet meer hebt, moet je een nieuwe key genereren

### Key ID of Issuer ID vergeten?

**Oplossing:**
1. Ga terug naar App Store Connect
2. Users and Access → Keys
3. Je ziet alle keys die je hebt gemaakt
4. Key ID staat naast elke key
5. Issuer ID staat bovenaan de Keys pagina

### Error blijft bestaan?

**Check:**
1. P8 bestand is correct geüpload? (check of bestand zichtbaar is)
2. Key ID klopt? (10 karakters, geen spaties)
3. Issuer ID klopt? (UUID format)
4. Bundle ID klopt? (exact zoals in Xcode)

### Bundle ID Mismatch?

**Als je Bundle ID in Xcode anders is:**
- Gebruik de juiste Bundle ID in RevenueCat
- Bijvoorbeeld: als Xcode `com.scrolldeeds` heeft, gebruik dat in RevenueCat

---

## 📋 Checklist

- [ ] P8 key gegenereerd in App Store Connect
- [ ] P8 key gedownload en veilig bewaard
- [ ] Key ID genoteerd (10 karakters)
- [ ] Issuer ID genoteerd (UUID)
- [ ] P8 key geüpload in RevenueCat
- [ ] Key ID ingevuld in RevenueCat
- [ ] Issuer ID ingevuld in RevenueCat
- [ ] Bundle ID klopt (check Xcode!)
- [ ] "Save changes" geklikt
- [ ] Error is weg
- [ ] App staat in "Apps & providers" zonder errors

---

## ✅ Volgende Stappen

Na het oplossen van de error:

1. **Products toevoegen:**
   - Ga naar "Product catalog" → "Products"
   - Klik "+ New"
   - Voeg `com.scrolldeeds.premium.monthly` toe
   - Voeg `com.scrolldeeds.premium.yearly` toe

2. **Entitlement maken:**
   - Ga naar "Entitlements"
   - Maak `Scrolldeeds Pro` entitlement
   - Koppel beide products

3. **Testen:**
   - Build en run je app
   - Test paywall

---

**Laat weten als je klaar bent of als je hulp nodig hebt!** 🚀

