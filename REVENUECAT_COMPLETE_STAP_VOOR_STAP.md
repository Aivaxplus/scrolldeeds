# RevenueCat Complete Setup - Van Begin tot Eind

## 📋 Overzicht

Je gaat RevenueCat volledig instellen voor ScrollDeeds. Dit proces bestaat uit:
1. Apple Subscription Key maken (in Apple Developer)
2. Key uploaden in RevenueCat
3. Products toevoegen in RevenueCat
4. Entitlement maken
5. Testen

**Tijd:** ~20 minuten

---

## ✅ DEEL 1: Apple Subscription Key Maken

### Stap 1.1: Ga naar Apple Developer

1. **Open je browser**
2. **Ga naar:** [developer.apple.com](https://developer.apple.com)
3. **Login** met je Apple Developer account
4. **Klik op:** "Certificates, Identifiers & Profiles" (of gebruik deze link: https://developer.apple.com/account/resources/authkeys/list)

---

### Stap 1.2: Ga naar Keys

1. **In het linker menu**, klik op **"Keys"**
2. Je ziet een lijst met alle keys (waarschijnlijk leeg als je nog geen keys hebt)

---

### Stap 1.3: Maak Nieuwe Key

1. **Klik op de "+" knop** (linksboven, naast "Keys")
2. Je ziet nu: "Register a New Key"

---

### Stap 1.4: Vul Key Details In

#### A. Key Name (VERPLICHT)

1. **Klik in het "Key Name" veld**
2. **Type EXACT dit:**
   ```
   subscription_revenuecat
   ```
   ⚠️ **BELANGRIJK:**
   - Moet beginnen met `subscription_`
   - Alleen kleine letters
   - Gebruik `_` (underscore), geen spaties
   - Geen speciale karakters

#### B. Key Usage Description (OPTIONEEL)

1. **Klik in het "Key Usage Description" veld**
2. **Type (optioneel):**
   ```
   For RevenueCat subscription management
   ```
   Of laat het leeg - maakt niet uit

---

### Stap 1.5: Selecteer Service (VERPLICHT)

⚠️ **Je MOET minimaal 1 service selecteren om door te gaan**

1. **Kijk naar de lijst met services**
2. **Vind "DeviceCheck"** (eerste optie, zonder "Configure" knop)
3. **Klik op de radio button** naast "DeviceCheck" om het aan te vinken
   - ✅ DeviceCheck is nu geselecteerd

**Waarom DeviceCheck?**
- Het is de makkelijkste optie (geen extra configuratie nodig)
- Het blokkeert RevenueCat niet
- RevenueCat heeft het niet nodig, maar het doet geen kwaad

---

### Stap 1.6: Continue Klikken

1. **Check of alles klopt:**
   - ✅ Key Name: `subscription_revenuecat`
   - ✅ DeviceCheck: Aangevinkt
   - ✅ Continue knop: Zou nu blauw/actief moeten zijn

2. **Klik op "Continue"** (rechtsboven)

---

### Stap 1.7: Download P8 Key

⚠️ **KRITIEK:** Je kunt dit bestand maar 1x downloaden!

1. **Je ziet een waarschuwing:**
   - "You can download your key only once"
   - "Download your key and save it in a secure location"

2. **Klik op "Download"** knop
3. **Het bestand wordt gedownload:**
   - Bestandsnaam: `AuthKey_XXXXXXXX.p8`
   - Bijvoorbeeld: `AuthKey_YSYR6LN4R2.p8`
   - Locatie: Meestal in je Downloads folder

4. **⚠️ BELANGRIJK - Bewaar dit bestand veilig!**
   - Verplaats het naar een veilige locatie
   - Bijvoorbeeld: Desktop → RevenueCat folder
   - Of sla het op in een password manager
   - **Je kunt het niet opnieuw downloaden!**

---

### Stap 1.8: Noteer Key ID

1. **Op dezelfde pagina waar je de key downloadde, zie je:**
   - **Key ID:** `XXXXXXXXXX` (10 karakters)
   - Bijvoorbeeld: `YSYR6LN4R2`

2. **⚠️ BELANGRIJK - Noteer dit!**
   - Kopieer het of schrijf het op
   - Je hebt het nodig in RevenueCat
   - Bijvoorbeeld: `YSYR6LN4R2`

---

### Stap 1.9: Noteer Issuer ID

1. **Klik op "< All Keys"** (bovenaan de pagina)
   - Of ga terug naar: Certificates, Identifiers & Profiles → Keys

2. **Bovenaan de Keys pagina zie je:**
   - **Issuer ID:** `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` (UUID format)
   - Bijvoorbeeld: `691fae94-1da3-42e7-9ca6-f4bd4d13609b`

3. **⚠️ BELANGRIJK - Noteer dit!**
   - Kopieer het of schrijf het op
   - Je hebt het nodig in RevenueCat
   - Dit is hetzelfde voor alle keys in je account

---

## ✅ DEEL 2: Key Uploaden in RevenueCat

### Stap 2.1: Ga naar RevenueCat Dashboard

1. **Open een nieuwe tab** in je browser
2. **Ga naar:** [app.revenuecat.com](https://app.revenuecat.com)
3. **Login** met je RevenueCat account
4. **Selecteer project:** Scrolldeeds

---

### Stap 2.2: Ga naar Apps & Providers

1. **In het linker menu**, klik op **"Apps & providers"**
2. Je ziet waarschijnlijk een lijst met apps (of een lege lijst)

---

### Stap 2.3: Maak/Configureer App Store App

#### Optie A: Als je al een app ziet

1. **Klik op:** "Scrolldeeds (App Store)" of de app die je ziet
2. Ga naar Stap 2.4

#### Optie B: Als je geen app ziet

1. **Klik op:** "+ New" knop (rechtsboven)
2. **Selecteer:** "App Store app"
3. Ga naar Stap 2.4

---

### Stap 2.4: Vul App Details In

1. **App name:**
   - Type: `Scrolldeeds (App Store)`
   - Of: `Scrolldeeds`

2. **App Bundle ID:**
   - Type: `com.scrolldeeds.app`
   - ⚠️ **Dit moet EXACT overeenkomen met je Xcode project!**
   - Check in Xcode: Project → Target → General → Bundle Identifier

---

### Stap 2.5: Upload P8 Key

1. **Zoek naar:** "P8 key file from App Store Connect" sectie
2. **Klik op het upload vak** (groot grijs vak)
   - Of klik op "Choose File" / "Upload" knop

3. **Selecteer het P8 bestand:**
   - Ga naar je Downloads folder (of waar je het hebt opgeslagen)
   - Selecteer: `AuthKey_XXXXXXXX.p8`
   - Bijvoorbeeld: `AuthKey_YSYR6LN4R2.p8`

4. **Check of het bestand is geüpload:**
   - Je zou de bestandsnaam moeten zien in het upload vak

---

### Stap 2.6: Vul Key ID In

1. **Zoek naar:** "Key ID" veld
2. **Type of plak:** Je Key ID die je noteerde
   - Bijvoorbeeld: `YSYR6LN4R2`
   - ⚠️ **10 karakters, geen spaties**

---

### Stap 2.7: Vul Issuer ID In

1. **Zoek naar:** "Issuer ID" veld
2. **Type of plak:** Je Issuer ID die je noteerde
   - Bijvoorbeeld: `691fae94-1da3-42e7-9ca6-f4bd4d13609b`
   - ⚠️ **UUID format, met streepjes**

---

### Stap 2.8: Save

1. **Scroll naar beneden**
2. **Klik op:** "Save changes" knop (rechtsonder)
3. **✅ Als alles goed is:**
   - Error zou nu weg moeten zijn!
   - Je ziet "Connected" of "Active" status
   - Je kunt nu products toevoegen!

---

## ✅ DEEL 3: Products Toevoegen in RevenueCat

### Stap 3.1: Ga naar Product Catalog

1. **In het linker menu**, klik op **"Product catalog"**
2. **Klik op tab:** "Products" (bovenaan)

---

### Stap 3.2: Voeg Monthly Product Toe

1. **Klik op:** "+ New" of "New product" knop (rechtsboven)

2. **Vul in:**
   - **Product ID:** `com.scrolldeeds.premium.monthly`
   - **Store Product ID:** `com.scrolldeeds.premium.monthly`
     - ⚠️ **BELANGRIJK:** Dit moet EXACT overeenkomen met App Store Connect!
   - **Type:** Selecteer `Subscription` uit dropdown
   - **Store:** Selecteer `Apple App Store` (of laat leeg)

3. **Klik op:** "Save" of "Create"

✅ **Product 1 is toegevoegd!**

---

### Stap 3.3: Voeg Yearly Product Toe

1. **Klik opnieuw:** "+ New" of "New product"

2. **Vul in:**
   - **Product ID:** `com.scrolldeeds.premium.yearly`
   - **Store Product ID:** `com.scrolldeeds.premium.yearly`
     - ⚠️ **BELANGRIJK:** Dit moet EXACT overeenkomen met App Store Connect!
   - **Type:** Selecteer `Subscription` uit dropdown
   - **Store:** Selecteer `Apple App Store` (of laat leeg)

3. **Klik op:** "Save" of "Create"

✅ **Product 2 is toegevoegd!**

---

## ✅ DEEL 4: Entitlement Maken

### Stap 4.1: Ga naar Entitlements

1. **In hetzelfde scherm**, klik op tab **"Entitlements"** (naast Products)

---

### Stap 4.2: Maak Entitlement

1. **Klik op:** "+ New" of "New entitlement" knop

2. **Vul in:**
   - **Entitlement ID:** `Scrolldeeds Pro`
     - ⚠️ **BELANGRIJK:** Exact zoals hier, met hoofdletters en spatie!
     - Niet: `scrolldeeds pro` of `ScrolldeedsPro`
   - **Description:** `Premium access to all ScrollDeeds features` (optioneel)

---

### Stap 4.3: Koppel Products

1. **Scroll naar beneden** naar "Products" sectie
2. **Klik op:** "Add Product" of "Link Product" knop
3. **Selecteer:** `com.scrolldeeds.premium.monthly`
4. **Klik opnieuw:** "Add Product"
5. **Selecteer:** `com.scrolldeeds.premium.yearly`

✅ **Beide products zijn nu gekoppeld!**

---

### Stap 4.4: Save Entitlement

1. **Klik op:** "Save" of "Create"

✅ **Entitlement is gemaakt!**

---

## ✅ DEEL 5: Offering Maken (Aanbevolen)

### Stap 5.1: Ga naar Offerings

1. **Klik op tab:** "Offerings" (naast Entitlements)

---

### Stap 5.2: Maak Offering

1. **Klik op:** "+ New" of "New offering" knop

2. **Vul in:**
   - **Offering ID:** `default` (of laat leeg voor default offering)
   - **Description:** `Default offering for ScrollDeeds` (optioneel)

---

### Stap 5.3: Voeg Packages Toe

1. **Klik op:** "Add Package" of "Create Package"

2. **Package 1: Monthly**
   - **Package Identifier:** `monthly` (of `$rc_monthly`)
   - **Product:** Selecteer `com.scrolldeeds.premium.monthly`
   - **Klik:** "Save"

3. **Klik opnieuw:** "Add Package"

4. **Package 2: Yearly**
   - **Package Identifier:** `yearly` (of `$rc_yearly`)
   - **Product:** Selecteer `com.scrolldeeds.premium.yearly`
   - **Klik:** "Save"

---

### Stap 5.4: Save Offering

1. **Klik op:** "Save" of "Create"

✅ **Offering is gemaakt!**

---

## ✅ DEEL 6: Verificatie

### Check of Alles Klopt:

1. **Apps & providers:**
   - ✅ App staat er zonder errors
   - ✅ Status is "Connected" of "Active"

2. **Products:**
   - ✅ `com.scrolldeeds.premium.monthly` bestaat
   - ✅ `com.scrolldeeds.premium.yearly` bestaat

3. **Entitlement:**
   - ✅ `Scrolldeeds Pro` bestaat
   - ✅ Beide products zijn gekoppeld

4. **Offering:**
   - ✅ `default` offering bestaat
   - ✅ Beide packages zijn toegevoegd

---

## ✅ DEEL 7: Testen

### Stap 7.1: Build App

1. **Open Xcode**
2. **Open project:** `scrolldeeds.xcodeproj`
3. **Build:** Cmd+B
4. **Check voor errors**

---

### Stap 7.2: Run App

1. **Run app:** Cmd+R
2. **Test paywall:**
   - Start een dhikr sessie
   - Paywall zou moeten verschijnen

---

### Stap 7.3: Check Console

1. **Open Xcode console:** Cmd+Shift+Y
2. **Zoek naar:**
   - `✅ RevenueCat initialized`
   - `✅ Loaded offerings`
   - `📊 Premium status: Active/Inactive`

---

## 📋 Complete Checklist

### Apple Developer:
- [ ] Key gemaakt met naam: `subscription_revenuecat`
- [ ] DeviceCheck geselecteerd
- [ ] P8 bestand gedownload (`AuthKey_XXXXXXXX.p8`)
- [ ] Key ID genoteerd (10 karakters)
- [ ] Issuer ID genoteerd (UUID)

### RevenueCat:
- [ ] App toegevoegd: `Scrolldeeds (App Store)`
- [ ] Bundle ID: `com.scrolldeeds.app`
- [ ] P8 key geüpload
- [ ] Key ID ingevuld
- [ ] Issuer ID ingevuld
- [ ] "Save changes" geklikt
- [ ] Error is weg!

### Products:
- [ ] `com.scrolldeeds.premium.monthly` toegevoegd
- [ ] `com.scrolldeeds.premium.yearly` toegevoegd

### Entitlement:
- [ ] `Scrolldeeds Pro` gemaakt
- [ ] Beide products gekoppeld

### Offering:
- [ ] `default` offering gemaakt
- [ ] Beide packages toegevoegd

### Testen:
- [ ] App gebuild zonder errors
- [ ] App gerund
- [ ] Paywall getest
- [ ] Console logs gecheckt

---

## 🆘 Troubleshooting

### Error: "Both Apple's Subscription Key ID and Private Key must be provided"
- **Oplossing:** Check of P8 bestand is geüpload, Key ID en Issuer ID zijn ingevuld

### Products laden niet in app
- **Oplossing:** Check of Product IDs exact overeenkomen tussen App Store Connect, RevenueCat en code

### Entitlement werkt niet
- **Oplossing:** Check of Entitlement ID exact is: `Scrolldeeds Pro` (niet `scrolldeeds pro`)

---

## 🎯 Volgende Stappen

Na het voltooien van deze setup:

1. **Products in App Store Connect:**
   - Zorg dat products ook in App Store Connect staan
   - Product IDs moeten exact overeenkomen

2. **Test met Sandbox:**
   - Maak sandbox test account
   - Test purchase flow

3. **Production:**
   - Vervang test API key met productie key
   - Submit app naar App Store

---

**Je bent klaar! Volg deze stappen stap voor stap en laat weten als je ergens vastloopt!** 🚀

