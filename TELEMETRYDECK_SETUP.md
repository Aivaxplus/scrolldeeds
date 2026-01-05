# TelemetryDeck Setup Guide

TelemetryDeck is een privacy-vriendelijke analytics service die perfect past bij ScrollDeeds.

## Stap 1: Account Aanmaken

1. Ga naar https://telemetrydeck.com
2. Maak een gratis account aan
3. Maak een nieuwe app aan (bijv. "ScrollDeeds")
4. Kopieer je **App ID** (je krijgt deze na het aanmaken)

## Stap 2: SDK Toevoegen aan Xcode

1. Open Xcode → Selecteer je project
2. Ga naar **Package Dependencies** tab
3. Klik op **+** (Add Package)
4. Voer URL in: `https://github.com/TelemetryDeck/SwiftClient`
5. Kies **Up to Next Major Version** met `3.0.0`
6. Klik **Add Package**
7. Selecteer **TelemetryClient** en klik **Add Package**

## Stap 3: SDK Configureren

1. Open `scrolldeedsApp.swift`
2. Voeg toe aan `didFinishLaunchingWithOptions`:

```swift
import TelemetryClient

// In didFinishLaunchingWithOptions, na AnalyticsManager.shared.trackAppLaunch():
let configuration = TelemetryManagerConfiguration(
    appID: "YOUR_APP_ID_HIER" // Vervang met je TelemetryDeck App ID
)
TelemetryManager.start(with: configuration)
```

3. Vervang `YOUR_APP_ID_HIER` met je echte App ID van TelemetryDeck

## Stap 4: AnalyticsManager Activeren

1. Open `AnalyticsManager.swift`
2. Uncomment de import regel:
```swift
import TelemetryClient
```

3. Uncomment de TelemetryManager.send regel in `sendTelemetryDeckEvent`:
```swift
TelemetryManager.send(name, with: parameters)
```

## Stap 5: Testen

1. Run de app
2. Voltooi een dhikr sessie
3. Check je TelemetryDeck dashboard → Je zou events moeten zien

## Events die worden getrackt

- **`session_completed`**: Elke keer dat gebruiker dhikr voltooit
- **`week_retention`**: Na 7 dagen, met parameter `is_active` (true/false)

## Gratis Tier

- **10,000 events per maand** (meer dan genoeg voor ScrollDeeds)
- **Privacy-first**: Geen persoonlijke data
- **GDPR compliant**
- **Geen creditcard nodig**

## Dashboard

In je TelemetryDeck dashboard zie je:
- Totaal aantal events
- Events over tijd
- Week retention percentage (via `week_retention` events)

## Klaar!

Na deze setup wordt alle analytics automatisch naar TelemetryDeck gestuurd. Je kunt de retention zien in je dashboard.

