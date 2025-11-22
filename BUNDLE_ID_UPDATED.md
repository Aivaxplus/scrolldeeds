# ✅ Bundle Identifier Updated!

## **🎯 Nieuwe Bundle Identifier:**
```
com.scrolldeeds.app
```

**Oude waarde:** `com.yourname.scrolldeeds`  
**Nieuwe waarde:** `com.scrolldeeds.app`

---

## **✅ WAT ER IS VERANDERD:**

De Bundle Identifier is aangepast in:
- ✅ Debug configuration
- ✅ Release configuration
- ✅ Xcode project settings

---

## **🔴 BELANGRIJK: JE MOET NOG DOEN IN XCODE!**

### **Stap 1: Refresh Xcode**
1. **Sluit Xcode** (Cmd + Q)
2. **Open Xcode opnieuw**
3. Open je scrolldeeds project

### **Stap 2: Controleer de Bundle ID**
1. Klik op **scrolldeeds** (project, bovenaan links)
2. Klik op **scrolldeeds** onder TARGETS
3. Ga naar **Signing & Capabilities** tab
4. Check dat **Bundle Identifier** nu is: `com.scrolldeeds.app`

### **Stap 3: Fix Signing**
Als je een waarschuwing ziet:

```
⚠️ "Failed to register bundle identifier"
```

Dan moet je:
1. Ga naar **Apple Developer Portal**: [developer.apple.com/account](https://developer.apple.com/account)
2. Ga naar **Certificates, Identifiers & Profiles**
3. Klik op **Identifiers** (links)
4. Klik **+ (plus)** knop
5. Selecteer **App IDs** → Continue
6. Vul in:
   - **Description:** ScrollDeeds
   - **Bundle ID:** `com.scrolldeeds.app`
   - **Capabilities:** ✅ Family Controls
7. Klik **Continue** → **Register**

### **Stap 4: Nieuwe Provisioning Profile**
1. Nog in Developer Portal
2. Ga naar **Profiles** (links)
3. Klik **+ (plus)** knop
4. Selecteer **iOS App Development** → Continue
5. Selecteer je nieuwe App ID: `com.scrolldeeds.app`
6. Selecteer je certificate
7. Selecteer je devices
8. Download de .mobileprovision file
9. Dubbelklik om te installeren

### **Stap 5: In Xcode**
1. Ga terug naar **Signing & Capabilities**
2. Klik **Download Manual Profiles** (of laat Xcode automatisch doen)
3. Selecteer je nieuwe provisioning profile

---

## **🎉 NA DIT:**

Build en test je app:
```bash
1. Clean Build Folder (Cmd + Shift + K)
2. Build (Cmd + B)
3. Run op je iPhone (Cmd + R)
```

---

## **📋 CHECKLIST:**

- [ ] Xcode gesloten en opnieuw geopend
- [ ] Bundle ID gecontroleerd in Xcode
- [ ] App ID aangemaakt in Developer Portal
- [ ] Family Controls capability toegevoegd aan App ID
- [ ] Provisioning Profile aangemaakt
- [ ] App gebuild zonder errors
- [ ] Getest op iPhone

---

## **💡 TIP:**

Als je **automatische signing** gebruikt (Automatically manage signing):
- Xcode zal proberen alles automatisch te regelen
- Maar voor **Family Controls** moet je handmatig de capability aanvragen bij Apple!

---

**Je nieuwe Bundle ID is:** `com.scrolldeeds.app` ✨

Deze blijft **permanent** gekoppeld aan je app in de App Store!

