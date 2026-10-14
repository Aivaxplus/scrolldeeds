# 🔧 Trial Periode Fix: 1 Maand → 3 Dagen

## ❌ Probleem
Apple Pay popup toont nog steeds "1 maand free trial" in plaats van "3 dagen free trial" voor de yearly subscription.

## ✅ Oplossing

### **Stap 1: App Store Connect (BELANGRIJKSTE!)**

De Apple Pay popup haalt de trial periode **direct uit App Store Connect**, niet uit je code!

**Wat je moet doen:**

1. **Ga naar App Store Connect:**
   - https://appstoreconnect.apple.com
   - Login → My Apps → ScrollDeeds

2. **Ga naar Subscriptions:**
   - Klik op "Features" → "Subscriptions"
   - Klik op "Premium Yearly" (of je subscription group)

3. **Check Introductory Offer:**
   - Scroll naar "Introductory Offers"
   - Klik op de bestaande offer (of maak nieuwe aan)

4. **Wijzig Duration:**
   - **Huidige waarde:** 1 Month (1 maand)
   - **Nieuwe waarde:** 3 Days (3 dagen)
   - **Type:** Free Trial
   - **Price:** €0.00 (automatisch)

5. **Save & Submit:**
   - Klik "Save"
   - Als nodig: Submit voor review (kan 24-48 uur duren)

### **Stap 2: RevenueCat Dashboard**

RevenueCat haalt de trial periode uit App Store Connect, maar soms moet je het handmatig syncen:

1. **Ga naar RevenueCat Dashboard:**
   - https://app.revenuecat.com
   - Login → Selecteer je project

2. **Ga naar Products:**
   - Klik "Products" in het menu
   - Zoek "Premium Yearly" (com.scrolldeeds.premium.yearly)

3. **Check Product Details:**
   - Kijk naar "Introductory Offer"
   - Als het nog "1 Month" zegt, klik op "Sync from App Store"

4. **Force Sync:**
   - Klik op "Sync Products" button
   - Wacht 1-2 minuten
   - Refresh de pagina

### **Stap 3: Test in App**

1. **Delete app van device/simulator**
2. **Reinstall app**
3. **Test met Sandbox account:**
   - Maak nieuwe sandbox test account
   - Test de purchase flow
   - Check of Apple Pay popup nu "3 dagen" toont

### **Stap 4: Code Updates (Al gedaan ✅)**

Ik heb al aangepast:
- ✅ `Products.storekit` → `P3D` (3 dagen) in plaats van `P1M` (1 maand)
- ✅ Alle localized strings → "3 dagen" in plaats van "1 maand"

---

## ⚠️ Belangrijk

**De Apple Pay popup toont ALTIJD wat in App Store Connect staat!**

- Code strings zijn alleen voor UI tekst in je app
- Apple Pay popup haalt trial periode direct uit App Store Connect
- RevenueCat sync't automatisch, maar kan 1-2 uur duren

---

## 🔍 Check of het werkt

**Na wijziging in App Store Connect:**

1. Wacht 1-2 uur (voor sync)
2. Delete app volledig
3. Reinstall
4. Test purchase flow
5. Check Apple Pay popup → zou nu "3 dagen" moeten tonen

---

## 📝 Als het nog steeds niet werkt

**Mogelijke oorzaken:**

1. **Wijziging nog niet goedgekeurd:**
   - Check App Store Connect → Status
   - Wacht op Apple's goedkeuring (24-48 uur)

2. **RevenueCat niet gesynced:**
   - Force sync in RevenueCat dashboard
   - Wacht 1-2 uur

3. **Cache probleem:**
   - Delete app volledig
   - Restart device
   - Reinstall app

4. **Verkeerde subscription:**
   - Check of je de juiste subscription test (yearly, niet monthly)
   - Check product ID: `com.scrolldeeds.premium.yearly`

---

## ✅ Checklist

- [ ] App Store Connect → Premium Yearly → Introductory Offer = **3 Days**
- [ ] RevenueCat Dashboard → Product synced → Shows **3 Days**
- [ ] `Products.storekit` → `subscriptionPeriod: "P3D"` ✅ (al gedaan)
- [ ] Alle localized strings → "3 dagen" ✅ (al gedaan)
- [ ] Test met nieuwe sandbox account
- [ ] Apple Pay popup toont "3 dagen" ✅

---

**Het belangrijkste is App Store Connect!** Als dat nog "1 Month" zegt, zal Apple Pay dat ook tonen, ongeacht wat je code zegt.
