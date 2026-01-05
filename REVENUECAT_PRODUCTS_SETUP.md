# RevenueCat Products Setup - Correcte Product IDs

## ❌ Wat er nu staat (verkeerd):
- `Monthly monthly` - verkeerde Product ID
- `Yearly yearly` - verkeerde Product ID  
- `Lifetime lifetime` - niet nodig voor nu

## ✅ Wat je moet doen:

### Stap 1: Verwijder bestaande products (optioneel)

1. In RevenueCat Dashboard → **Product catalog** → **Products**
2. Klik op elk product (Monthly, Yearly, Lifetime)
3. Klik op **"Delete"** of **"Remove"** knop
4. Bevestig verwijdering

**OF** laat ze staan en voeg gewoon de juiste toe (kan geen kwaad)

---

### Stap 2: Voeg correcte products toe

1. Klik op **"+ New"** of **"New product"** knop

2. **Product 1: Monthly Subscription**
   - **Product ID:** `com.scrolldeeds.premium.monthly`
   - **Store Product ID:** `com.scrolldeeds.premium.monthly` (moet exact overeenkomen met App Store Connect!)
   - **Type:** `Subscription` (selecteer uit dropdown)
   - **Store:** `Apple App Store`
   - Klik **"Save"** of **"Create"**

3. **Product 2: Yearly Subscription**
   - Klik opnieuw **"+ New"** of **"New product"**
   - **Product ID:** `com.scrolldeeds.premium.yearly`
   - **Store Product ID:** `com.scrolldeeds.premium.yearly` (moet exact overeenkomen met App Store Connect!)
   - **Type:** `Subscription`
   - **Store:** `Apple App Store`
   - Klik **"Save"** of **"Create"**

---

### Stap 3: Maak Entitlement

1. Ga naar tab **"Entitlements"** (naast Products)
2. Klik **"+ New"** of **"New entitlement"**
3. **Entitlement ID:** `premium`
4. **Description:** `Premium access to all features`
5. **Koppel products:**
   - Voeg `com.scrolldeeds.premium.monthly` toe
   - Voeg `com.scrolldeeds.premium.yearly` toe
6. Klik **"Save"**

---

### Stap 4: Maak Offering (optioneel, maar aanbevolen)

1. Ga naar tab **"Offerings"**
2. Klik **"+ New"** of **"New offering"**
3. **Offering ID:** `default` (of laat leeg voor default)
4. **Description:** `Default offering`
5. **Add packages:**
   - Voeg `com.scrolldeeds.premium.monthly` toe
   - Voeg `com.scrolldeeds.premium.yearly` toe
6. Klik **"Save"**

---

## ⚠️ BELANGRIJK:

**Product IDs moeten EXACT overeenkomen:**
- ✅ RevenueCat: `com.scrolldeeds.premium.monthly`
- ✅ App Store Connect: `com.scrolldeeds.premium.monthly`
- ✅ Je code: `com.scrolldeeds.premium.monthly`

Als ze niet overeenkomen, werkt het niet!

---

## 📝 Checklist:

- [ ] Oude products verwijderd (optioneel)
- [ ] `com.scrolldeeds.premium.monthly` toegevoegd
- [ ] `com.scrolldeeds.premium.yearly` toegevoegd
- [ ] Entitlement `premium` gemaakt
- [ ] Beide products gekoppeld aan `premium` entitlement
- [ ] Offering gemaakt (optioneel)

---

**Laat weten als je klaar bent!** 🚀

