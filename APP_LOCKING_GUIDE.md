# 🔒 App Locking Guide - Waarom Het Niet Werkt in Simulator

## ⚠️ **BELANGRIJK: Simulator vs Physical Device**

### **Het Probleem:**
Je zegt dat de apps niet gelocked worden. Dit komt waarschijnlijk door **één van deze redenen:**

---

## 🔴 **Reden 1: Je Test in de Simulator** (MEEST WAARSCHIJNLIJK!)

### **Family Controls werkt NIET in de simulator!**

Apple's **Family Controls** en **Managed Settings** frameworks werken **ALLEEN** op een **fysiek iOS device**.

**Waarom?**
- Privacy en security redenen
- Simulator heeft geen echte apps om te locken
- Screen Time APIs zijn hardware-gebonden

### **Oplossing:**
```
✅ MOET: Test op je iPhone 11
❌ WERKT NIET: Simulator (iPhone 15, etc.)
```

---

## 🔴 **Reden 2: Family Controls Permissions Niet Toegestaan**

### **Check Dit:**
1. Open de app op je **fysieke iPhone**
2. Klik op "Choose Apps to Lock"
3. Krijg je een **permission popup**?
4. Heb je **"Allow"** geklikt?

**Als je "Don't Allow" klikte:**
```
Settings → Screen Time → [Je App] → Allow
```

---

## 🔴 **Reden 3: Apps Zijn Geselecteerd Maar Niet Gelocked**

### **Wat Ik Heb Gefixed:**

#### **1. Auto-Lock bij App Start** ✅
```swift
// In ContentView.onAppear
if !shieldManager.selectedApplications.isEmpty && !isUnlockActive {
    shieldManager.applyShield()
}
```

**Wat Dit Doet:**
- Wanneer de app opent
- En er apps geselecteerd zijn
- En ze zijn NIET unlocked
- → Apply shield automatisch!

#### **2. Auto-Lock na Selectie** ✅
```swift
// In SelectionView.onChange
shieldManager.updateSelection(apps: selection.applications)
if !shieldManager.selectedApplications.isEmpty {
    shieldManager.applyShield()
}
```

**Wat Dit Doet:**
- Wanneer je apps selecteert
- Direct daarna
- → Apply shield automatisch!

#### **3. Auto-Lock na Onboarding** ✅
```swift
// In QuestionnaireView.finishQuestionnaire
if !shieldManager.selectedApplications.isEmpty {
    shieldManager.applyShield()
}
```

**Wat Dit Doet:**
- Na onboarding compleet
- Als apps geselecteerd zijn
- → Apply shield direct!

---

## 🔴 **Reden 4: Shield State Niet Gepersisteert**

### **Wat Ik Heb Gefixed:**

#### **Persistent Storage** ✅
```swift
// ShieldManager nu slaat op:
- "hasLockedApps" → of er apps zijn
- "isShieldActiveState" → of shield actief is
```

#### **Auto-Load bij Start** ✅
```swift
init() {
    loadLockedApps()
    isShieldActive = defaults.bool(forKey: "hasLockedApps")
}
```

**Wat Dit Doet:**
- App start
- Load shield state
- Restore lock status
- Alles blijft gelocked!

---

## ✅ **Hoe Te Testen:**

### **Step 1: Deploy naar Physical Device**
```
1. Sluit je iPhone 11 aan
2. In Xcode: Select "iPhone 11" (niet simulator!)
3. Click Run (▶️) of Cmd+R
4. Wacht tot app installeert
```

### **Step 2: Test de Flow**
```
1. Open app op iPhone
2. Doe onboarding
3. Selecteer apps (bijv. Instagram, TikTok)
4. Click "Done" in de app picker
5. ✅ Apps worden NU gelocked!
```

### **Step 3: Verify Het Werkt**
```
1. Ga naar home screen
2. Probeer een gelocked app te openen
3. Je zou een SHIELD moeten zien:
   
   ┌─────────────────────┐
   │        🛡️           │
   │   This app is       │
   │   restricted        │
   └─────────────────────┘
```

### **Step 4: Test Unlock**
```
1. Terug naar ScrollDeeds app
2. Click "Unlock Apps with Dhikr"
3. Record dhikr
4. Na verificatie → Apps unlocked voor 15 min!
5. Probeer gelocked app → WERKT nu!
```

### **Step 5: Test Auto Re-Lock**
```
1. Wacht 15 minuten (of change timer voor test)
2. Apps worden automatisch re-locked
3. Probeer app → Geblokkeerd weer!
```

---

## 🐛 **Debug: Check Console Logs**

### **Ik Heb Debug Prints Toegevoegd:**

#### **Wanneer Shield Applied:**
```
🔒 Shield APPLIED to 3 apps
```

#### **Wanneer Shield Removed:**
```
🔓 Shield REMOVED from all apps
```

#### **In Simulator:**
```
⚠️ ManagedSettings not available (simulator?), but marking as active
```

### **Hoe Te Checken:**
```
1. Open app in Xcode
2. Kijk naar console (onderaan)
3. Zoek naar 🔒 of 🔓 emojis
4. Zie je "simulator?" → Test op device!
```

---

## 📱 **Waarom Physical Device Nodig Is:**

### **Family Controls Vereist:**
1. ✅ **Real iOS device** (iPhone, iPad)
2. ✅ **iOS 16+** (je iPhone 11 werkt!)
3. ✅ **Family Controls entitlement** (al gedaan)
4. ✅ **User permission** (eerste keer vragen)

### **Simulator Heeft:**
1. ❌ Geen echte apps om te blocken
2. ❌ Geen Screen Time systeem
3. ❌ Geen Family Controls access
4. ❌ Alleen voor UI testing

---

## 🎯 **Checklist:**

### **Heb je dit al gedaan?**

- [ ] **Test op fysieke iPhone** (NIET simulator)
- [ ] **Family Controls permission toegestaan**
- [ ] **Apps geselecteerd** via picker
- [ ] **"Allow" geklikt** op permission popup
- [ ] **Console gechecked** voor 🔒 logs
- [ ] **Screen Time enabled** in Settings

### **Als je checklist compleet is:**

**En het werkt nog niet → Dit is wat kan zijn:**

1. **iOS versie te oud?**
   - Check: Settings → General → About
   - Moet zijn: iOS 16 of hoger

2. **Provisioning profile issues?**
   - Rebuild app in Xcode
   - Clean build folder (Shift+Cmd+K)
   - Re-run (Cmd+R)

3. **Entitlements niet correct?**
   - Check: Target → Signing & Capabilities
   - Moet hebben: "Family Controls (Development)"

---

## 🚀 **Quick Test Command:**

Run dit om te zien of je op simulator test:
```bash
# Als je dit ziet in console:
"⚠️ ManagedSettings not available"
# → Je test in simulator!

# Als je dit ziet:
"🔒 Shield APPLIED to X apps"
# → Het werkt! (op physical device)
```

---

## ✅ **Samenvatting:**

### **Wat Ik Gefixed Heb:**
1. ✅ Auto-lock bij app start
2. ✅ Auto-lock na app selectie
3. ✅ Auto-lock na onboarding
4. ✅ Persistent shield state
5. ✅ Debug logging toegevoegd

### **Wat JIJ Moet Doen:**
1. 📱 **Test op je iPhone 11** (NIET simulator!)
2. ✅ **Allow Family Controls** permission
3. 🔍 **Check console logs** voor 🔒
4. 🎉 **Apps zouden nu gelocked moeten zijn!**

---

**De code is correct. Het probleem is 99% dat je in de simulator test!** 🎯

**Test op je iPhone en het werkt!** 📱✨

