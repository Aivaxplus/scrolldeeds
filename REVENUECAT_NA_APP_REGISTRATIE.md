# RevenueCat - Na App Registratie: Volgende Stappen

## ✅ Wat is al gedaan:
- ✅ App geregistreerd in RevenueCat
- ✅ Apple Subscription Key geüpload
- ✅ Key ID en Issuer ID ingevuld

## 📋 Wat je nu moet doen:

---

## ✅ STAP 1: Products Toevoegen

### Stap 1.1: Ga naar Product Catalog

1. **In RevenueCat Dashboard**
2. **Klik in linker menu:** "Product catalog"
3. **Klik op tab:** "Products" (bovenaan)

---

### Stap 1.2: Voeg Monthly Product Toe

1. **Klik op:** "+ New" of "New product" knop (rechtsboven)

2. **Vul in:**
   - **Product ID:** `com.scrolldeeds.premium.monthly`
   - **Store Product ID:** `com.scrolldeeds.premium.monthly`
     - ⚠️ **BELANGRIJK:** Dit moet EXACT overeenkomen met App Store Connect!
   - **Type:** Selecteer `Subscription` uit dropdown
   - **Store:** Selecteer `Apple App Store` (of laat leeg voor alle stores)

3. **Klik op:** "Save" of "Create"

✅ **Product 1 is toegevoegd!**

---

### Stap 1.3: Voeg Yearly Product Toe

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

## ✅ STAP 2: Entitlement Maken

### Stap 2.1: Ga naar Entitlements

1. **In hetzelfde scherm** (Product catalog)
2. **Klik op tab:** "Entitlements" (naast Products)

---

### Stap 2.2: Maak Entitlement

1. **Klik op:** "+ New" of "New entitlement" knop

2. **Vul in:**
   - **Entitlement ID:** `Scrolldeeds Pro`
     - ⚠️ **BELANGRIJK:** Exact zoals hier, met hoofdletters en spatie!
     - Niet: `scrolldeeds pro` of `ScrolldeedsPro` of `scrolldeeds_pro`
   - **Description:** `Premium access to all ScrollDeeds features` (optioneel)

---

### Stap 2.3: Koppel Products aan Entitlement

1. **Scroll naar beneden** naar "Products" sectie
2. **Klik op:** "Add Product" of "Link Product" knop
3. **Selecteer:** `com.scrolldeeds.premium.monthly`
   - Check dat het product verschijnt in de lijst
4. **Klik opnieuw:** "Add Product"
5. **Selecteer:** `com.scrolldeeds.premium.yearly`
   - Check dat beide products nu in de lijst staan

✅ **Beide products zijn nu gekoppeld aan het entitlement!**

---

### Stap 2.4: Save Entitlement

1. **Klik op:** "Save" of "Create"

✅ **Entitlement is gemaakt!**

---

## ✅ STAP 3: Offering Maken (Aanbevolen)

### Stap 3.1: Ga naar Offerings

1. **Klik op tab:** "Offerings" (naast Entitlements)

---

### Stap 3.2: Maak Offering

1. **Klik op:** "+ New" of "New offering" knop

2. **Vul in:**
   - **Offering ID:** `default` (of laat leeg voor default offering)
   - **Description:** `Default offering for ScrollDeeds` (optioneel)

---

### Stap 3.3: Voeg Packages Toe

1. **Klik op:** "Add Package" of "Create Package"

2. **Package 1: Monthly**
   - **Package Identifier:** `monthly` (of `$rc_monthly`)
   - **Product:** Selecteer `com.scrolldeeds.premium.monthly` uit dropdown
   - **Klik:** "Save" of "Add"

3. **Klik opnieuw:** "Add Package"

4. **Package 2: Yearly**
   - **Package Identifier:** `yearly` (of `$rc_yearly`)
   - **Product:** Selecteer `com.scrolldeeds.premium.yearly` uit dropdown
   - **Klik:** "Save" of "Add"

✅ **Beide packages zijn toegevoegd!**

---

### Stap 3.4: Save Offering

1. **Klik op:** "Save" of "Create"

✅ **Offering is gemaakt!**

---

## ✅ STAP 4: Verificatie

### Check of Alles Klopt:

1. **Products:**
   - ✅ `com.scrolldeeds.premium.monthly` bestaat
   - ✅ `com.scrolldeeds.premium.yearly` bestaat

2. **Entitlement:**
   - ✅ `Scrolldeeds Pro` bestaat
   - ✅ Beide products zijn gekoppeld

3. **Offering:**
   - ✅ `default` offering bestaat (of er is een default)
   - ✅ Beide packages zijn toegevoegd

---

## ✅ STAP 5: Testen in App

### Stap 5.1: Build App

1. **Open Xcode**
2. **Open project:** `scrolldeeds.xcodeproj`
3. **Build:** Cmd+B
4. **Check voor errors**

---

### Stap 5.2: Run App

1. **Run app:** Cmd+R
2. **Test paywall:**
   - Start een dhikr sessie
   - Paywall zou moeten verschijnen
   - Products zouden moeten laden

---

### Stap 5.3: Check Console

1. **Open Xcode console:** Cmd+Shift+Y
2. **Zoek naar:**
   - `✅ RevenueCat initialized`
   - `✅ Loaded offerings: X packages available`
   - `📊 Premium status: Active/Inactive`

---

## ⚠️ Belangrijke Checkpoints

### Product IDs Moeten Exact Overeenkomen:

✅ **App Store Connect:**
- `com.scrolldeeds.premium.monthly`
- `com.scrolldeeds.premium.yearly`

✅ **RevenueCat:**
- Product ID: `com.scrolldeeds.premium.monthly`
- Store Product ID: `com.scrolldeeds.premium.monthly`
- Product ID: `com.scrolldeeds.premium.yearly`
- Store Product ID: `com.scrolldeeds.premium.yearly`

✅ **Je Code:**
- Entitlement ID: `"Scrolldeeds Pro"` (in SubscriptionManager.swift)

---

### Entitlement ID Moet Exact Zijn:

✅ **In RevenueCat:** `Scrolldeeds Pro`
✅ **In Code:** `"Scrolldeeds Pro"`

❌ **Niet:** `scrolldeeds pro`, `ScrolldeedsPro`, `scrolldeeds_pro`

---

## 📋 Complete Checklist

### Products:
- [ ] `com.scrolldeeds.premium.monthly` toegevoegd
- [ ] `com.scrolldeeds.premium.yearly` toegevoegd
- [ ] Beide zijn type "Subscription"

### Entitlement:
- [ ] `Scrolldeeds Pro` gemaakt
- [ ] Beide products gekoppeld aan entitlement

### Offering:
- [ ] `default` offering gemaakt
- [ ] Beide packages toegevoegd

### Testen:
- [ ] App gebuild zonder errors
- [ ] App gerund
- [ ] Paywall getest
- [ ] Products laden in paywall
- [ ] Console logs gecheckt

---

## 🆘 Troubleshooting

### Products laden niet in app?

**Check:**
1. Product IDs exact overeenkomen? (App Store Connect, RevenueCat, code)
2. Products zijn opgeslagen in RevenueCat?
3. Offering is geconfigureerd?
4. App heeft internet verbinding?

### Entitlement werkt niet?

**Check:**
1. Entitlement ID is exact: `Scrolldeeds Pro` (niet `scrolldeeds pro`)
2. Products zijn gekoppeld aan entitlement?
3. Subscription is actief in App Store Connect?

### Paywall toont geen products?

**Check:**
1. Offering is gemaakt?
2. Packages zijn toegevoegd aan offering?
3. Check console voor errors

---

## 🎯 Volgende Stappen (Na Setup)

1. **Products in App Store Connect:**
   - Zorg dat products ook in App Store Connect staan
   - Product IDs moeten exact overeenkomen

2. **Test met Sandbox:**
   - Maak sandbox test account in App Store Connect
   - Test purchase flow

3. **Production:**
   - Vervang test API key met productie key (`pk_live_...`)
   - Submit app naar App Store

---

**Volg deze stappen en laat weten als je klaar bent of als je hulp nodig hebt!** 🚀

