# PostHog opnieuw instellen (nieuwe account)

Je hebt alle PostHog-code uit het project gehaald. Voor een **nieuwe** PostHog-account heb je het volgende nodig.

---

## Wat je nodig hebt van PostHog

1. **Project API Key (Project API Key / Personal API Key)**  
   - In PostHog: **Project Settings** → **Project API Key**  
   - Ziet eruit als: `phc_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`  
   - Dit is je **geheime key** – niet in git committen; gebruik **Info.plist** of environment variables.

2. **Host URL** (optioneel, standaard EU):  
   - EU: `https://eu.i.posthog.com`  
   - US: `https://us.i.posthog.com`  
   - Of je eigen self-hosted URL.

---

## Stappen voor een nieuwe integratie

1. **Nieuwe PostHog-account**  
   - Ga naar [posthog.com](https://posthog.com) en maak een nieuw project.

2. **Package toevoegen in Xcode**  
   - File → Add Package Dependencies  
   - URL: `https://github.com/PostHog/posthog-ios.git`  
   - Product: **PostHog**

3. **API key bewaren**  
   - In **Info.plist**: voeg een key toe, bijv. `PostHogAPIKey` met waarde je project API key.  
   - Of gebruik een **xcconfig** / environment variable en lees die in je app (geen key in git).

4. **Code**  
   - Maak opnieuw een `PostHogManager` (of vergelijkbare wrapper) die:  
     - `PostHogSDK.shared.setup(config)` aanroept met je API key en host.  
     - Events stuurt met `PostHogSDK.shared.capture(event, properties: …)`.

5. **Events**  
   - Besluit welke events je wilt (bijv. Onboarding Started, Onboarding Step Viewed, Onboarding Completed, App Launched) en stuur die vanuit je app naar PostHog.

---

## Samenvatting

| Wat              | Waar te vinden in PostHog        |
|------------------|-----------------------------------|
| **Project API Key** | Project Settings → Project API Key |
| **Host**         | Meestal `https://eu.i.posthog.com` |

Met alleen de **Project API Key** en de **Host** kun je PostHog opnieuw in je app integreren.
