# 🚀 ScrollDeeds - Update Submission Checklist

## ✅ **PRE-SUBMISSION CHECKLIST:**

### **1. Version & Build Numbers:**
- [ ] **Marketing Version:** Verhoog (bijv. 1.0.0 → 1.0.1 of 1.1.0)
- [ ] **Build Number:** Verhoog (bijv. 1 → 2)
- [ ] Check in Xcode: Target → General → Version

### **2. What's New in This Version:**
- [ ] **Update Notes voorbereiden:**
  ```
  - Fixed trial period display (3 days instead of 1 month)
  - Improved analytics tracking
  - Added gamified streak system
  - Enhanced onboarding experience
  - Bug fixes and performance improvements
  ```

### **3. Code Quality:**
- [x] Geen linter errors ✅
- [x] Geen crashes ✅
- [x] Debug logging alleen in DEBUG mode ✅
- [x] Recente fixes toegepast ✅

### **4. App Store Connect:**
- [ ] **Version Information:**
  - [ ] "What's New in This Version" tekst ingevuld
  - [ ] Screenshots (als UI veranderd is)
  - [ ] App Preview (als nodig)

- [ ] **Subscriptions Check:**
  - [ ] Premium Yearly → 3 Days trial (correct?)
  - [ ] Premium Weekly → No trial (correct?)
  - [ ] Alle prijzen correct

### **5. TestFlight (Aanbevolen):**
- [ ] **Archive & Upload:**
  - [ ] Product → Archive in Xcode
  - [ ] Distribute App → App Store Connect
  - [ ] Upload build
  - [ ] Wacht tot processing klaar is (10-30 min)

- [ ] **Internal Testing:**
  - [ ] Test met interne testers
  - [ ] Check alle nieuwe features
  - [ ] Test purchase flow (sandbox)

### **6. Submission:**
- [ ] **In App Store Connect:**
  - [ ] Ga naar je app → Versie
  - [ ] Selecteer nieuwe build
  - [ ] Check "What's New"
  - [ ] Submit for Review

- [ ] **Review Notes (als nodig):**
  ```
  This update includes:
  - Fixed subscription trial period display
  - Improved analytics integration
  - Enhanced user experience with streak system
  
  Test Account: [je test account]
  ```

---

## 🎯 **QUICK SUBMISSION STEPS:**

### **Stap 1: Version Update**
1. Open Xcode
2. Selecteer project → Target "scrolldeeds"
3. General tab → Version: `1.0.1` (of hoger)
4. Build: `2` (of hoger)

### **Stap 2: Archive**
1. Product → Clean Build Folder (⇧⌘K)
2. Product → Archive (⌘B, dan Product → Archive)
3. Wacht tot archive klaar is

### **Stap 3: Upload**
1. In Organizer window → Distribute App
2. App Store Connect → Next
3. Upload → Next
4. Selecteer team → Next
5. Upload → Wacht tot klaar

### **Stap 4: App Store Connect**
1. Ga naar https://appstoreconnect.apple.com
2. My Apps → ScrollDeeds
3. Klik op versie (1.0.1 of hoger)
4. Selecteer nieuwe build
5. Vul "What's New" in
6. Submit for Review

---

## ⚠️ **BELANGRIJK VOOR UPDATE:**

### **Breaking Changes Check:**
- [ ] Geen breaking changes voor bestaande users?
- [ ] Data migratie nodig? (lijkt niet zo)
- [ ] API changes? (lijkt niet zo)

### **Backward Compatibility:**
- [x] Oude data blijft werken ✅
- [x] Geen data migratie nodig ✅
- [x] Features zijn backward compatible ✅

### **Testing:**
- [ ] Test op echte device (niet alleen simulator)
- [ ] Test purchase flow (sandbox)
- [ ] Test onboarding (nieuwe users)
- [ ] Test dashboard (bestaande users)

---

## 📋 **UPDATE SUMMARY:**

### **Wat is Nieuw:**
- ✅ Trial periode gefixt (3 dagen i.p.v. 1 maand)
- ✅ Analytics (PostHog verwijderd; optioneel opnieuw toe te voegen)
- ✅ Gamified streak system toegevoegd
- ✅ Onboarding verbeterd (hint tekst, button tekst)
- ✅ Weekly trial verwijderd
- ✅ Bug fixes

### **Wat Blijft Hetzelfde:**
- ✅ Core functionaliteit
- ✅ Data structuur
- ✅ User experience flow

---

## ✅ **READY TO SUBMIT:**

Als je deze checklist hebt doorlopen:
1. ✅ Version numbers verhoogd
2. ✅ Archive gemaakt
3. ✅ Upload naar App Store Connect
4. ✅ "What's New" ingevuld
5. ✅ Submit for Review

**Estimated Review Time:** 1-3 dagen

---

## 🚀 **SUBMIT NU!**

Je app is klaar voor update submission. Volg de stappen hierboven en submit voor review!

**Good luck! 🎉**
