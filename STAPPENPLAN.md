# Stappenplan – na het verwijderen van PostHog

Volg deze stappen in volgorde.

---

## Deel 1: Nu direct doen (zonder PostHog)

### Stap 1: Project in Xcode openen
1. Open **Xcode**.
2. Open het project: **scrolldeeds.xcodeproj** (dubbelklik of File → Open).

### Stap 2: Package cache opruimen (aanbevolen)
1. In het menu: **File** → **Packages** → **Reset Package Caches**.
2. Wacht tot Xcode klaar is (eventueel even laten draaien).

### Stap 3: Bouwen en testen
1. Kies je **simulator** of een **echt apparaat** (bovenin Xcode).
2. Druk op **⌘ + B** (Build) of klik op het play-icoon.
3. Controleer of de app **zonder fouten** bouwt en start.
4. Loop kort door: onboarding, een sessie, instellingen. Alles zou moeten werken; alleen PostHog-events worden niet meer verstuurd.

**Als er een fout over “PostHog” of “PostHogManager” verschijnt:**  
Stuur de foutmelding door; dan kunnen we die gericht oplossen.

---

## Deel 2: Later – PostHog opnieuw toevoegen (nieuwe account)

Doe dit pas als je een **nieuwe PostHog-account** hebt en weer analytics wilt.

### Stap 1: Nieuwe PostHog-account maken
1. Ga naar **[posthog.com](https://posthog.com)**.
2. Klik op **Sign up** / **Get started**.
3. Maak een account (e-mail + wachtwoord, of Google/GitHub).
4. Maak een **nieuw project** (bijv. “ScrollDeeds” of “ScrollDeeds Production”).

### Stap 2: Project API Key kopiëren
1. In PostHog: ga naar **Project Settings** (tandwiel of link onderaan links).
2. Zoek **Project API Key** (of “Project API Key” / “Personal API Key”).
3. Klik op **Copy** of selecteer en kopieer de key.  
   Hij ziet er zo uit: `phc_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`.
4. Bewaar deze key even in een veilige plek (bijv. notities); je hebt hem straks nodig.

### Stap 3: Host-URL noteren
- Voor **Europa**: `https://eu.i.posthog.com`
- Voor **VS**: `https://us.i.posthog.com`  
Meestal gebruik je de EU-URL. Noteer de URL die bij jouw project hoort.

### Stap 4: PostHog-package in Xcode toevoegen
1. Open je project in **Xcode**.
2. Menu: **File** → **Add Package Dependencies...**.
3. Rechtsboven, bij de URL-balk, plak:  
   `https://github.com/PostHog/posthog-ios.git`
4. Klik op **Add Package**.
5. Vink **PostHog** aan (niet alleen de tests).
6. Klik **Add Package** en wacht tot de package is gedownload.

### Stap 5: API key in de app zetten
1. In Xcode: open **Info.plist** (in de map **scrolldeeds**).
2. Klik op **+** om een nieuwe rij toe te voegen.
3. Key: typ `PostHogAPIKey` (of kies “Custom” en vul die naam in).
4. Type: **String**.
5. Value: plak je **Project API Key** (de `phc_...` die je in Stap 2 hebt gekopieerd).
6. Sla op (**⌘ + S**).

**Belangrijk:** Zet **PostHogAPIKey** niet in git als die in een publiek repo staat. Gebruik dan liever een xcconfig of environment variable (zie POSTHOG_SETUP.md).

### Stap 6: Code weer toevoegen
Je hebt weer nodig:
- Een **PostHogManager** (of vergelijkbare class) die:
  - `PostHogSDK.shared.setup(config)` aanroept met je **API key** en **host**.
  - Events stuurt met `PostHogSDK.shared.capture(event, properties: …)`.
- In **scrolldeedsApp.swift**:  
  - `import PostHog`  
  - Bij opstarten: PostHog initialiseren met de key uit `Bundle.main.infoDictionary?["PostHogAPIKey"]` en de host-URL.
- In **AnalyticsManager** (of waar je nu analytics aanroept):  
  - Vanuit daar je PostHogManager aanroepen voor de events die je wilt (onboarding, session, etc.).

Als je wilt, kan ik in een volgende stap de exacte code voor PostHogManager en de init weer uitschrijven op basis van wat er eerder was.

### Stap 7: Testen
1. Build de app (**⌘ + B**) en run (**⌘ + R**).
2. Doe een korte flow (bijv. app openen, stukje onboarding).
3. In PostHog: ga naar **Activity** of **Events** en wacht 1–2 minuten.  
   Je zou daar events moeten zien (bijv. “App Launched”, “Onboarding Started”).

---

## Samenvatting

| Fase | Wat je doet |
|------|-------------|
| **Nu** | Xcode openen → Package cache resetten → Build + run → even testen. |
| **Later (nieuwe PostHog)** | Account + project → API key + host → Package toevoegen → Key in Info.plist → PostHogManager + init + events weer inbouwen → testen in PostHog. |

Als je bij een bepaalde stap vastloopt, zeg bij welke stap (nummer + wat je ziet) en dan kunnen we het gericht oplossen.
