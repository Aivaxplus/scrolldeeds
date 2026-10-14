# 🔧 Mixpanel Troubleshooting Guide

## ❌ Probleem: Geen events zichtbaar in Mixpanel Dashboard

### Stap 1: Check Console Logs

1. **Open Xcode**
2. **Run je app** (CMD + R)
3. **Check de console** voor deze berichten:

**✅ Goed (Mixpanel werkt):**
```
🔧 Mixpanel: Initializing with token: 8c50dd71...
✅ Mixpanel initialized successfully
📊 Mixpanel: Event 'App Launched' tracked with properties: [:]
📊 Mixpanel: Flushed event 'App Launched' immediately
```

**❌ Slecht (Mixpanel werkt niet):**
```
⚠️ Mixpanel token not found in Info.plist. Mixpanel tracking disabled.
⚠️ Info.plist keys: ...
```

**Als je de ⚠️ waarschuwing ziet:**
- Check of `MixpanelToken` in Info.plist staat
- Check of de token correct is (zonder spaties)
- Rebuild de app (Product → Clean Build Folder, dan CMD + B)

---

### Stap 2: Test Mixpanel Manueel

1. **Open de app**
2. **Voer deze acties uit:**
   - Open de app (trackt "App Launched")
   - Start onboarding (trackt "Onboarding Started")
   - Voltooi een sessie (trackt "Session Completed")

3. **Check console** - Je zou moeten zien:
   ```
   📊 Mixpanel: Event 'App Launched' tracked
   📊 Mixpanel: Event 'Onboarding Started' tracked
   📊 Mixpanel: Event 'Session Completed' tracked
   ```

---

### Stap 3: Check Mixpanel Dashboard

1. **Ga naar [Mixpanel Dashboard](https://eu.mixpanel.com)**
2. **Selecteer je project** (Scrolldeeds)
3. **Ga naar "Live View"** (links in sidebar)
4. **Wacht 1-2 minuten** - Events kunnen een paar minuten duren om te verschijnen

**Als je nog steeds niets ziet:**

---

### Stap 4: Verificatie Checklist

- [ ] **Mixpanel SDK is toegevoegd** (Package Dependencies → Mixpanel 5.1.4)
- [ ] **Token is in Info.plist** (Key: `MixpanelToken`, Value: `8c50dd71a34c46bbd37f03b1efc48361`)
- [ ] **App is opnieuw gebuild** (Product → Clean Build Folder, dan CMD + B)
- [ ] **App is gerund** (CMD + R)
- [ ] **Console toont "✅ Mixpanel initialized successfully"**
- [ ] **Console toont tracking events** (📊 Mixpanel: Event...)
- [ ] **Je hebt 1-2 minuten gewacht** in Mixpanel Dashboard

---

### Stap 5: Test Event Manueel Versturen

Als je nog steeds niets ziet, test dan of Mixpanel überhaupt werkt:

1. **Open Xcode**
2. **Run je app**
3. **In de console, type dit** (of voeg tijdelijk toe aan code):

```swift
// Test event
MixpanelManager.shared.track(event: "Test Event", properties: [
    "test_property": "test_value"
])
```

4. **Check console** - Je zou moeten zien:
   ```
   📊 Mixpanel: Event 'Test Event' tracked with properties: ["test_property": "test_value"]
   ```

5. **Check Mixpanel Dashboard** → Live View
6. **Zoek naar "Test Event"**

---

### Stap 6: Check Mixpanel Project Settings

1. **Ga naar Mixpanel Dashboard**
2. **Settings** (rechts boven) → **Project Settings**
3. **Check "Project Token"** - Moet zijn: `8c50dd71a34c46bbd37f03b1efc48361`
4. **Check "Data Residency"** - Moet zijn: **EU** (omdat je eu.mixpanel.com gebruikt)

**⚠️ BELANGRIJK:** Als je `eu.mixpanel.com` gebruikt, moet je Mixpanel configureren voor EU data residency!

---

### Stap 7: Fix EU Data Residency (Als nodig)

Als je `eu.mixpanel.com` gebruikt, moet Mixpanel geconfigureerd worden voor EU:

**Update MixpanelManager.swift:**

```swift
// In init(), na Mixpanel.initialize():
if let mixpanel = self.mixpanel {
    // Set EU server
    mixpanel.serverURL = "https://api-eu.mixpanel.com"
}
```

---

### Stap 8: Check Network/Firewall

Mixpanel events worden via HTTPS verstuurd. Check of:
- Je internet werkt
- Geen firewall Mixpanel blokkeert
- Je niet op een VPN zit die Mixpanel blokkeert

---

### Stap 9: Force Flush Events

Voeg tijdelijk toe aan `MixpanelManager.swift`:

```swift
func forceFlush() {
    guard let mixpanel = mixpanel, isEnabled else { return }
    mixpanel.flush()
    debugPrint("📊 Mixpanel: Force flushed all events")
}
```

Roep dit aan na belangrijke events om te testen.

---

### Stap 10: Check Mixpanel SDK Versie

1. **In Xcode** → Package Dependencies
2. **Check Mixpanel versie** - Moet zijn: **5.1.4** of hoger
3. **Als ouder:** Update naar nieuwste versie

---

## 🐛 Veelvoorkomende Problemen

### Probleem 1: "Mixpanel token not found"
**Oplossing:**
- Check Info.plist → `MixpanelToken` bestaat
- Rebuild app (Clean Build Folder)
- Check of token geen spaties heeft

### Probleem 2: Events verschijnen niet
**Oplossing:**
- Wacht 1-2 minuten (events worden gebatched)
- Check "Live View" in Mixpanel (niet "Events")
- Check console voor tracking logs
- Force flush events

### Probleem 3: "Cannot track event - Mixpanel not enabled"
**Oplossing:**
- Check of token correct is in Info.plist
- Rebuild app
- Check console voor init errors

---

## ✅ Als Alles Werkt

Je zou moeten zien in Mixpanel Dashboard:

1. **Live View:**
   - "App Launched" events
   - "Onboarding Started" events
   - "Session Completed" events

2. **Events:**
   - Lijst van alle events
   - Event counts
   - Timestamps

3. **Users:**
   - User properties (age_group, referral_source, etc.)
   - User identification

---

## 📞 Nog Steeds Problemen?

Als je na alle stappen nog steeds niets ziet:

1. **Check Xcode console** voor errors
2. **Check Mixpanel Dashboard** → Settings → Project Settings
3. **Test met een simpel test event** (zie Stap 5)
4. **Check of je in het juiste Mixpanel project zit**

---

**Laat me weten wat je ziet in de console en ik help je verder!** 🚀
