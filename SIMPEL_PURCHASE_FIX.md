# Simpel: Purchase Button Fix 🛒

## 🎯 **Het Probleem:**
De purchase button werkt niet. Dit komt meestal door 1 van deze 3 dingen:

1. ❌ Geen packages geladen (RevenueCat heeft geen producten gevonden)
2. ❌ Geen package geselecteerd (button is disabled)
3. ❌ Geen sandbox account (kan niet testen)

---

## ✅ **Oplossing in 3 Simpele Stappen:**

### **STAP 1: Check of Packages Geladen zijn (2 minuten)**

1. **Open je app** in Xcode
2. **Druk op de mic knop** → Paywall verschijnt
3. **Kijk naar de paywall:**
   - ✅ **Zie je 2 knoppen?** (Monthly en Yearly) → Ga naar Stap 2
   - ❌ **Zie je "No packages available"?** → Ga naar Stap 3

**Als je "No packages available" ziet:**
- Dit betekent dat RevenueCat geen producten kan vinden
- **Oplossing:** Check RevenueCat Dashboard (zie Stap 3)

---

### **STAP 2: Check of Package Geselecteerd is (30 seconden)**

1. **Kijk naar de paywall**
2. **Zie je een package met een vinkje?** (groene cirkel met checkmark)
   - ✅ **JA** → Ga naar Stap 3
   - ❌ **NEE** → Klik op een package (Monthly of Yearly) om te selecteren

**Als de button nog steeds disabled is:**
- Check of de button transparant/grijs is
- Als ja → Package is niet geladen (ga naar Stap 3)

---

### **STAP 3: Fix RevenueCat Configuratie (5 minuten)**

Dit is de meest waarschijnlijke oorzaak. RevenueCat kan je producten niet vinden.

#### **3.1 Check RevenueCat Dashboard:**

1. **Ga naar:** https://app.revenuecat.com
2. **Login** met je account
3. **Klik op "ScrollDeeds"** (je app)
4. **Klik op "Products"** (linker menu)
5. **Check:**
   - ✅ Zie je 2 producten? (`com.scrolldeeds.premium.monthly` en `com.scrolldeeds.premium.yearly`)
   - ✅ Zijn ze "Active"?
   - ❌ **Als NEE** → Producten zijn niet gesynchroniseerd

#### **3.2 Check Offerings:**

1. **Klik op "Offerings"** (linker menu)
2. **Check:**
   - ✅ Zie je een "Default" offering?
   - ✅ Zijn er packages gekoppeld aan de offering?
   - ❌ **Als NEE** → Maak een offering aan

#### **3.3 Maak Offering aan (als die er niet is):**

1. **Klik "+" → "New Offering"**
2. **Naam:** `default` (kleine letters)
3. **Identifier:** `default`
4. **Klik "Create"**
5. **Klik op de offering** die je net gemaakt hebt
6. **Klik "+" → "Add Package"**
7. **Selecteer beide packages:**
   - Monthly package
   - Yearly package
8. **Klik "Save"**

#### **3.4 Synchroniseer Producten (als ze er niet zijn):**

1. **Ga naar "Products"**
2. **Klik "+" → "Add Product"**
3. **Product ID:** `com.scrolldeeds.premium.monthly`
   - Dit MOET exact hetzelfde zijn als in App Store Connect!
4. **Klik "Add"**
5. **Herhaal voor yearly:**
   - Product ID: `com.scrolldeeds.premium.yearly`

---

## 🧪 **Test Purchase (Na Fix):**

### **Voor Simulator/Device:**

1. **Log uit van je echte Apple ID:**
   - Settings → App Store → Apple ID → Sign Out

2. **Open je app**
3. **Druk op mic knop** → Paywall verschijnt
4. **Klik op "Start Premium"** (of "Start Free Trial")
5. **Je krijgt popup:** "Sign In to the iTunes Store"
6. **Gebruik Sandbox Test Account:**
   - Email: (maak aan in App Store Connect → Users and Access → Sandbox Testers)
   - Password: (je sandbox password)
7. **Bevestig purchase**
8. **✅ Klaar!**

---

## 🆘 **Als het nog steeds niet werkt:**

### **Check Xcode Console:**

1. **Open Xcode**
2. **Run je app** (Cmd+R)
3. **Open Console** (Cmd+Shift+Y)
4. **Ga naar paywall**
5. **Kijk naar de logs:**
   - ✅ Zie je "✅ Offerings loaded"?
   - ❌ Zie je "❌ No current offering found"?
   - ❌ Zie je errors?

**Deel de logs met mij, dan kan ik precies zien wat er mis is!**

---

## 📋 **Quick Checklist:**

Voor je test, check:

- [ ] RevenueCat Dashboard → Products → 2 producten zichtbaar?
- [ ] RevenueCat Dashboard → Offerings → "default" offering bestaat?
- [ ] RevenueCat Dashboard → Offerings → Packages gekoppeld?
- [ ] App → Paywall → Zie je 2 packages?
- [ ] App → Paywall → Is een package geselecteerd (vinkje)?
- [ ] App → Paywall → Is button enabled (niet grijs)?

**Als alles ✅ is → Button zou moeten werken!**

---

## 💡 **Meest Waarschijnlijke Oorzaak:**

**90% van de tijd is het dit:**
- RevenueCat heeft geen "default" offering
- Of packages zijn niet gekoppeld aan de offering

**Fix:**
1. Ga naar RevenueCat Dashboard
2. Maak "default" offering aan
3. Koppel packages eraan
4. Test opnieuw

---

## 🚀 **Nog steeds problemen?**

**Stuur mij:**
1. Screenshot van RevenueCat Dashboard → Offerings
2. Screenshot van RevenueCat Dashboard → Products
3. Screenshot van je paywall in de app
4. Xcode Console logs (copy/paste)

**Dan kan ik precies zien wat er mis is en je helpen fixen!**

---

**Je kunt dit! Het is meestal gewoon een configuratie dingetje in RevenueCat. 💪**

