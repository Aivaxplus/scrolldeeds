# RevenueCat Products Toevoegen - Stap voor Stap

## 📋 Overzicht

Je moet 2 products toevoegen in RevenueCat:
1. **Monthly Subscription** - `com.scrolldeeds.premium.monthly`
2. **Yearly Subscription** - `com.scrolldeeds.premium.yearly`

En 1 entitlement:
- **Scrolldeeds Pro** - Koppel beide products hieraan

---

## ✅ Stap 1: Products Toevoegen

### Product 1: Monthly Subscription

1. **Ga naar RevenueCat Dashboard:**
   - Open [app.revenuecat.com](https://app.revenuecat.com)
   - Login met je account
   - Selecteer project: **Scrolldeeds**

2. **Navigeer naar Products:**
   - Klik op **"Product catalog"** in het linker menu
   - Klik op tab **"Products"** (bovenaan)

3. **Voeg nieuw product toe:**
   - Klik op **"+ New"** of **"New product"** knop (rechtsboven)

4. **Vul product details in:**
   - **Product ID:** `com.scrolldeeds.premium.monthly`
   - **Store Product ID:** `com.scrolldeeds.premium.monthly` 
     - ⚠️ **BELANGRIJK:** Dit moet EXACT overeenkomen met App Store Connect!
   - **Type:** Selecteer `Subscription` uit dropdown
   - **Store:** Selecteer `Apple App Store` (of laat leeg voor alle stores)

5. **Klik "Save" of "Create"**

✅ **Product 1 is toegevoegd!**

---

### Product 2: Yearly Subscription

1. **Klik opnieuw "+ New" of "New product"**

2. **Vul product details in:**
   - **Product ID:** `com.scrolldeeds.premium.yearly`
   - **Store Product ID:** `com.scrolldeeds.premium.yearly`
     - ⚠️ **BELANGRIJK:** Dit moet EXACT overeenkomen met App Store Connect!
   - **Type:** Selecteer `Subscription` uit dropdown
   - **Store:** Selecteer `Apple App Store` (of laat leeg voor alle stores)

3. **Klik "Save" of "Create"**

✅ **Product 2 is toegevoegd!**

---

## ✅ Stap 2: Entitlement Maken

### Entitlement: Scrolldeeds Pro

1. **Ga naar Entitlements:**
   - In hetzelfde scherm, klik op tab **"Entitlements"** (naast Products)

2. **Voeg nieuw entitlement toe:**
   - Klik op **"+ New"** of **"New entitlement"** knop

3. **Vul entitlement details in:**
   - **Entitlement ID:** `Scrolldeeds Pro`
     - ⚠️ **BELANGRIJK:** Dit moet EXACT overeenkomen met je code!
     - Geen kleine letters, exact zoals hier: `Scrolldeeds Pro`
   - **Description:** `Premium access to all ScrollDeeds features` (optioneel)

4. **Koppel Products:**
   - Scroll naar beneden naar **"Products"** sectie
   - Klik op **"Add Product"** of **"Link Product"**
   - Selecteer: `com.scrolldeeds.premium.monthly`
   - Klik opnieuw **"Add Product"**
   - Selecteer: `com.scrolldeeds.premium.yearly`

5. **Klik "Save" of "Create"**

✅ **Entitlement is gemaakt en products zijn gekoppeld!**

---

## ✅ Stap 3: Offering Maken (Aanbevolen)

### Offering: Default

1. **Ga naar Offerings:**
   - Klik op tab **"Offerings"** (naast Entitlements)

2. **Voeg nieuw offering toe:**
   - Klik op **"+ New"** of **"New offering"** knop

3. **Vul offering details in:**
   - **Offering ID:** `default` (of laat leeg voor default offering)
   - **Description:** `Default offering for ScrollDeeds` (optioneel)

4. **Voeg Packages toe:**
   - Klik op **"Add Package"** of **"Create Package"**
   - **Package Identifier:** `monthly` (of `$rc_monthly`)
   - **Product:** Selecteer `com.scrolldeeds.premium.monthly`
   - Klik **"Save"**
   
   - Klik opnieuw **"Add Package"**
   - **Package Identifier:** `yearly` (of `$rc_yearly`)
   - **Product:** Selecteer `com.scrolldeeds.premium.yearly`
   - Klik **"Save"**

5. **Klik "Save" of "Create"** op het offering

✅ **Offering is gemaakt!**

---

## ✅ Stap 4: Verificatie

### Check of alles klopt:

1. **Products:**
   - ✅ `com.scrolldeeds.premium.monthly` bestaat
   - ✅ `com.scrolldeeds.premium.yearly` bestaat

2. **Entitlement:**
   - ✅ `Scrolldeeds Pro` bestaat
   - ✅ Beide products zijn gekoppeld aan entitlement

3. **Offering:**
   - ✅ `default` offering bestaat (of er is een default)
   - ✅ Beide packages zijn toegevoegd

---

## ⚠️ Belangrijke Controlepunten

### Product IDs moeten EXACT overeenkomen:

✅ **App Store Connect:**
- `com.scrolldeeds.premium.monthly`
- `com.scrolldeeds.premium.yearly`

✅ **RevenueCat Dashboard:**
- Product ID: `com.scrolldeeds.premium.monthly`
- Store Product ID: `com.scrolldeeds.premium.monthly`
- Product ID: `com.scrolldeeds.premium.yearly`
- Store Product ID: `com.scrolldeeds.premium.yearly`

✅ **Je Code:**
- Entitlement ID: `"Scrolldeeds Pro"` (in SubscriptionManager.swift)

---

## 🆘 Troubleshooting

### Product wordt niet gevonden in app?

**Check:**
1. Product ID klopt exact? (geen extra spaties, hoofdletters)
2. Store Product ID klopt exact?
3. Product is opgeslagen in RevenueCat?
4. Offering is geconfigureerd?
5. App heeft internet verbinding?

### Entitlement werkt niet?

**Check:**
1. Entitlement ID is exact: `Scrolldeeds Pro` (niet `scrolldeeds pro` of `ScrolldeedsPro`)
2. Products zijn gekoppeld aan entitlement?
3. Subscription is actief in App Store Connect?

### Products laden niet?

**Check:**
1. API key is correct?
2. Products bestaan in App Store Connect?
3. Check Xcode console voor errors

---

## 📸 Screenshot Locaties

Als je hulp nodig hebt, hier zijn de belangrijkste schermen:

1. **Products:** Product catalog → Products tab
2. **Entitlements:** Product catalog → Entitlements tab
3. **Offerings:** Product catalog → Offerings tab

---

## ✅ Volgende Stappen

Na het toevoegen van products:

1. **Test in app:**
   - Build app (Cmd+B)
   - Run app
   - Test paywall
   - Check of products laden

2. **Verify in RevenueCat:**
   - Dashboard → Customers
   - Check of test purchases verschijnen

3. **App Store Connect:**
   - Zorg dat products ook in App Store Connect staan
   - Product IDs moeten exact overeenkomen!

---

**Laat weten als je klaar bent of als je hulp nodig hebt!** 🚀

