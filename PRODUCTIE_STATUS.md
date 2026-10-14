# ScrollDeeds – Productie status

**Code:** ✅ Klaar voor productie (na onderstaande checks).

---

## ✅ In de app aangepast (productie-ready)

- **Unlockduur:** Gebruikt weer echte minuten (30/60/90 op basis van gekozen moeilijkheid), geen 30 seconden meer.
- **RevenueCat:** `logLevel` is in Release op `.warn` (geen `.debug`).
- **Launch logging:** Overbodige `debugPrint` bij opstarten verwijderd (PostHog/RevenueCat init).
- **DebugPrint:** Overal `#if DEBUG` – in Release builds komt er geen debug-log meer in de console.
- **CustomerCenter debug:** Debug-info in Settings staat in `#if DEBUG` – niet zichtbaar in Release.

---

## 📋 Wat jij nog moet controleren (niet in code)

### 1. App Store Connect & metadata
- [ ] **Subscription metadata** – Geen “Missing Metadata” voor Monthly/Yearly.
- [ ] **App Store-tekst** – Beschrijving klopt met de app (bijv. “recite dhikr” 1/3/33×, unlock 30/60/90 min).
- [ ] **Review notes** – Vermeld hoe unlock werkt: taak kiezen → dhikr (aantal afhankelijk van taak) → unlock 30/60/90 min.

### 2. Externe services
- [ ] **Webhook (n8n)** – Blijft bereikbaar; bij storing keurt de app dhikr automatisch goed (fallback).
- [ ] **Privacy Policy & Terms** – URLs blijven bereikbaar: `https://scrolldeeds.lovable.app/privacy` en `/terms`.
- [ ] **RevenueCat** – Productie-API key, entitlement “Scrolldeeds Pro”, subscriptions gekoppeld.

### 3. Xcode & build
- [ ] **Signing** – Release gebruikt Apple Distribution, Family Controls (Production) zichtbaar.
- [ ] **Build number** – Verhoogd voor elke nieuwe upload.
- [ ] **Archive & Validate** – Geen fouten bij “Validate App”.

### 4. Optioneel maar aanbevolen
- [ ] **PostHog API key** – Staat nu als fallback in code; voor scheiding dev/prod liever in Info.plist of xcconfig (zie STAPPENPLAN.md).
- [ ] **TestFlight** – Eén keer volledige flow testen op een fysiek toestel (onboarding → taak → dhikr → unlock → timer).

---

## Wat de app nu doet (voor copy & review)

- **Onboarding:** Get Started → vragenlijst → paywall → (na aankoop) thank you.
- **Unlock:** Gebruiker kiest een taak (easy/medium/hard) → dhikr (1, 3 of 33× afhankelijk van taak) → unlock 30 / 60 / 90 minuten.
- **Timer:** Unlocktijd blijft behouden bij sluiten app/telefoon; daarna automatisch weer lock + notificaties.

Als je deze punten afvinkt, is de app productie-ready; de rest is configuratie en App Store-invulwerk, geen code-aanpassingen meer.
