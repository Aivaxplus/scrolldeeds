# 🔧 Weekly Trial Fix: Verwijder Trial Periode

## ❌ Probleem
Apple Pay popup toont nog steeds **"1-week free trial"** voor de weekly subscription, terwijl je de offers hebt verwijderd in App Store Connect.

## ✅ Oplossing

### **Stap 1: Products.storekit (Al gefixt ✅)**

Ik heb de `introductoryOffer` verwijderd uit `Products.storekit`:
- **Voor:** `"introductoryOffer" : { "subscriptionPeriod" : "P1W" }`
- **Na:** `"introductoryOffer" : null`

Dit is voor **local testing** in Xcode.

### **Stap 2: App Store Connect (Check Dit!)**

1. **Ga naar App Store Connect:**
   - https://appstoreconnect.apple.com
   - Login → My Apps → ScrollDeeds

2. **Ga naar Subscriptions:**
   - Klik op "Features" → "Subscriptions"
   - Klik op **"Premium Weekly"**

3. **Check Introductory Offers:**
   - Scroll naar "Introductory Offers"
   - **Als er nog een offer staat:**
     - Klik op de offer
     - Klik "Delete" of "Remove"
     - Bevestig verwijdering

4. **Save**

### **Stap 3: RevenueCat Dashboard**

RevenueCat haalt de trial periode uit App Store Connect:

1. **Ga naar RevenueCat Dashboard:**
   - https://app.revenuecat.com
   - Login → Selecteer project

2. **Ga naar Products:**
   - Klik "Products" → Zoek "Premium Weekly"
   - Check "Introductory Offer"
   - **Als het nog "1 Week" zegt:**
     - Klik "Sync from App Store"
     - Wacht 2-3 minuten
     - Refresh pagina

3. **Force Sync:**
   - Klik "Sync Products" button
   - Wacht 1-2 minuten

### **Stap 4: Test in App**

1. **Delete app volledig van device/simulator**
2. **Reinstall app**
3. **Test met Sandbox account:**
   - Maak nieuwe sandbox test account
   - Test de purchase flow
   - Check of Apple Pay popup nu **geen trial** toont

---

## ⚠️ Belangrijk

**De Apple Pay popup haalt de trial periode direct uit App Store Connect!**

- `Products.storekit` is alleen voor **local testing** in Xcode
- App Store Connect bepaalt wat gebruikers zien in de echte app
- RevenueCat sync't automatisch, maar kan 1-2 uur duren

---

## 🔍 Check of het werkt

**Na wijziging in App Store Connect:**

1. Wacht 1-2 uur (voor sync)
2. Delete app volledig
3. Reinstall
4. Test purchase flow
5. Check Apple Pay popup → zou nu **geen trial** moeten tonen

---

## ✅ Checklist

- [x] `Products.storekit` → `introductoryOffer: null` ✅ (al gedaan)
- [ ] App Store Connect → Premium Weekly → Introductory Offers = **Geen offers**
- [ ] RevenueCat Dashboard → Product synced → Shows **No Introductory Offer**
- [ ] Test met nieuwe sandbox account
- [ ] Apple Pay popup toont **geen trial** ✅

---

**Het belangrijkste is App Store Connect!** Als daar nog een offer staat, zal Apple Pay die ook tonen.
