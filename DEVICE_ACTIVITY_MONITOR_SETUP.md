# 📱 DeviceActivityMonitor Extension Setup Guide

## Wat is DeviceActivityMonitor?

DeviceActivityMonitor is een App Extension die automatisch shields toepast wanneer een DeviceActivitySchedule eindigt, **zelfs wanneer de app gesloten is**. Dit is de enige manier om 100% automatische shield-toepassing te krijgen zonder dat de app actief hoeft te zijn.

## Stap 1: Nieuwe Target Toevoegen in Xcode

1. **Open Xcode** en selecteer je project (`scrolldeeds.xcodeproj`)

2. **Klik op je project** in de navigator (bovenaan links)

3. **Klik op de "+" knop** onder "TARGETS" (of rechts-klik op "TARGETS" → "Add Target...")

4. **Selecteer "App Extension"** → **"Device Activity Monitor Extension"**

5. **Configureer de extension:**
   - **Product Name:** `ScrollDeedsMonitor`
   - **Bundle Identifier:** `com.scrolldeeds.app.ScrollDeedsMonitor`
   - **Language:** Swift
   - **Team:** Selecteer je development team
   - **Klik "Finish"**

6. **Als Xcode vraagt om "Activate Scheme":** Klik "Activate"

## Stap 2: Entitlements Configureren

1. **Selecteer het nieuwe target** `ScrollDeedsMonitor` in de target lijst

2. **Ga naar "Signing & Capabilities" tab**

3. **Klik op "+ Capability"** en voeg toe:
   - **Family Controls** (als deze nog niet bestaat)

4. **Check of de entitlements file bestaat:**
   - Er zou een `ScrollDeedsMonitor.entitlements` file moeten zijn
   - Als deze niet bestaat, maak deze aan:
     - Rechts-klik op `ScrollDeedsMonitor` folder → "New File" → "Property List"
     - Noem het `ScrollDeedsMonitor.entitlements`
     - Voeg toe aan het `ScrollDeedsMonitor` target

5. **Open `ScrollDeedsMonitor.entitlements`** en voeg toe:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.family-controls</key>
	<true/>
</dict>
</plist>
```

## Stap 3: Code Schrijven voor de Extension

1. **Open de automatisch gegenereerde file:**
   - `ScrollDeedsMonitor/DeviceActivityMonitorExtension.swift`

2. **Vervang de code** met de volgende code:

```swift
import DeviceActivity
import ManagedSettings
import FamilyControls

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    // This is called when the schedule starts
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        debugPrint("📱 DeviceActivityMonitor: Interval started for \(activity)")
    }
    
    // This is called when the schedule ends - THIS IS WHERE WE APPLY THE SHIELD!
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        debugPrint("🔒🔒🔒 DeviceActivityMonitor: Interval ENDED - APPLYING SHIELD NOW! 🔒🔒🔒")
        
        // Load saved app selection
        let defaults = UserDefaults(suiteName: "group.com.scrolldeeds.app")
        guard let data = defaults?.data(forKey: "familyActivitySelection") else {
            debugPrint("⚠️ No saved selection found")
            return
        }
        
        do {
            // Decode FamilyActivitySelection
            let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            
            // Apply shield using ManagedSettingsStore
            let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("scrolldeeds.shield"))
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
            
            // Clear unlock time
            defaults?.removeObject(forKey: "unlockEndTime")
            
            debugPrint("✅✅✅ SHIELD APPLIED AUTOMATICALLY by DeviceActivityMonitor!")
            debugPrint("✅ This works even when the app is closed!")
        } catch {
            debugPrint("❌ Failed to apply shield: \(error)")
        }
    }
    
    // This is called periodically while the schedule is active
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        debugPrint("📊 DeviceActivityMonitor: Event reached threshold")
    }
}

#if DEBUG
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#else
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // No-op in production
}
#endif
```

## Stap 4: App Groups Configureren (CRITICAL!)

Om data te delen tussen de app en de extension, moeten we App Groups gebruiken:

1. **Selecteer het `scrolldeeds` target** (niet de extension)

2. **Ga naar "Signing & Capabilities" tab**

3. **Klik "+ Capability"** en voeg toe:
   - **App Groups**

4. **Klik "+"** en voeg een nieuwe App Group toe:
   - **Group Name:** `group.com.scrolldeeds.app`
   - **Klik "OK"**

5. **Selecteer nu het `ScrollDeedsMonitor` target**

6. **Ga naar "Signing & Capabilities" tab**

7. **Klik "+ Capability"** en voeg toe:
   - **App Groups**

8. **Vink dezelfde App Group aan:**
   - `group.com.scrolldeeds.app`

## Stap 5: ShieldManager Aanpassen voor App Groups

We moeten `ShieldManager` aanpassen om App Groups te gebruiken:

1. **Open `ShieldManager.swift`**

2. **Zoek de `defaults` property** en verander deze naar:

```swift
private let defaults = UserDefaults(suiteName: "group.com.scrolldeeds.app") ?? UserDefaults.standard
```

3. **Zoek `saveLockedApps()` en `loadLockedApps()`** - deze gebruiken al `defaults`, dus die werken automatisch met App Groups

## Stap 6: DeviceActivitySchedule Aanpassen

De `scheduleDeviceActivityShield` functie moet worden aangepast om de juiste activity name te gebruiken:

1. **Open `ShieldManager.swift`**

2. **Zoek `scheduleDeviceActivityShield` functie**

3. **Verander deze regel:**
```swift
let activity = DeviceActivityName("scrolldeeds.shield")
```

**Naar:**
```swift
// Activity name moet overeenkomen met wat we in de extension gebruiken
// We gebruiken de schedule name als activity
```

Eigenlijk, de DeviceActivitySchedule werkt anders. Laat me de juiste implementatie geven:

## Stap 7: Correcte DeviceActivitySchedule Implementatie

De `scheduleDeviceActivityShield` functie moet worden aangepast:

```swift
#if canImport(DeviceActivity)
@available(iOS 16.0, *)
private func scheduleDeviceActivityShield(endTime: Date) {
    guard !selectedApplications.isEmpty else {
        debugPrint("⚠️ No apps selected - cannot schedule DeviceActivity")
        return
    }
    
    let center = DeviceActivityCenter()
    let scheduleName = DeviceActivitySchedule.Name("scrolldeeds.unlock")
    let activityName = DeviceActivityName("scrolldeeds.shield")
    
    // Calculate schedule times
    let calendar = Calendar.current
    let now = Date()
    let scheduleStart = calendar.dateComponents([.hour, .minute, .second], from: now)
    let scheduleEnd = calendar.dateComponents([.hour, .minute, .second], from: endTime)
    
    // Create schedule
    let schedule = DeviceActivitySchedule(
        intervalStart: scheduleStart,
        intervalEnd: scheduleEnd,
        repeats: false,
        warningTime: nil
    )
    
    do {
        // Stop any existing schedule
        try center.stopMonitoring([scheduleName])
        
        // Start monitoring - when schedule ends, DeviceActivityMonitor extension will be called
        try center.startMonitoring(scheduleName, during: schedule)
        
        debugPrint("✅✅✅ DeviceActivitySchedule STARTED")
        debugPrint("📱 Shield will auto-apply at \(endTime) via DeviceActivityMonitor extension!")
    } catch {
        debugPrint("❌ Failed to schedule DeviceActivity: \(error)")
    }
}
#endif
```

## Stap 8: Testen

1. **Build en run de app** (niet de extension!)

2. **Doe dhikr en unlock apps**

3. **Wacht tot de timer verloopt** (of test met een korte timer)

4. **Check de console logs** - je zou moeten zien:
   - `DeviceActivitySchedule STARTED`
   - `DeviceActivityMonitor: Interval ENDED - APPLYING SHIELD NOW!`
   - `SHIELD APPLIED AUTOMATICALLY`

## Belangrijke Notities

- **De extension wordt automatisch uitgevoerd door iOS** wanneer de schedule eindigt
- **Je hoeft de extension niet handmatig te runnen** - iOS doet dit automatisch
- **De extension werkt zelfs wanneer de app gesloten is**
- **App Groups zijn CRITICAL** - zonder deze kan de extension de app selection niet lezen

## Troubleshooting

### Extension wordt niet uitgevoerd:
- Check of App Groups correct zijn geconfigureerd
- Check of de schedule correct is gestart (check console logs)
- Check of Family Controls permission is gegeven

### Shield wordt niet toegepast:
- Check of `familyActivitySelection` correct is opgeslagen in App Groups
- Check console logs van de extension
- Check of ManagedSettingsStore correct is geconfigureerd

### Build errors:
- Check of alle imports correct zijn
- Check of Family Controls capability is toegevoegd aan beide targets
- Check of App Groups zijn geconfigureerd voor beide targets

## Volgende Stappen

Na het toevoegen van de extension:
1. Test of het werkt met een korte timer (bijv. 30 seconden)
2. Test of het werkt wanneer de app gesloten is
3. Test of het werkt in App Store builds

De pre-emptive shield (na 4 minuten) blijft werken als backup, maar DeviceActivityMonitor zorgt voor 100% automatische shield-toepassing!

