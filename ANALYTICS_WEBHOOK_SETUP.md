# 📊 Analytics Webhook Setup - ScrollDeeds

## Overzicht

Het systeem verzamelt nu **leeftijd** en **referral source** van gebruikers en stuurt deze data naar een webhook URL, inclusief **betaalstatus** (premium/non-premium).

---

## ✅ Wat is geïmplementeerd

### 1. **Nieuwe onboarding vragen** (2 extra stappen)
- **Leeftijd vraag** 🧑
  - "How old are you?"
  - Opties: Under 18, 18-24, 25-34, 35-44, 45+
  
- **Referral source vraag** 📢
  - "How did you hear about us?"
  - Opties: **Instagram, TikTok, YouTube, Twitter/X, Facebook, Reddit, App Store, Friend/Family, Google Search, Other**
  - **Specifieke platformen** zodat je exact weet waar je moet investeren!

### 2. **Data opslag**
- Data wordt opgeslagen in `UserDataManager`
- Properties: `userAge` en `referralSource`
- Persistent via UserDefaults

### 3. **Webhook systeem**
- Nieuwe service: `AnalyticsWebhookService.swift`
- Stuurt data naar een configureerbare webhook URL
- Include payment status (premium/non-premium)

### 4. **Events tracking**
Het systeem stuurt webhooks op deze momenten:
- ✅ **Onboarding completed** (user finished onboarding, nog geen betaling)
- ✅ **Paywall shown** (user ziet de paywall)
- ✅ **User subscribed** (user heeft betaald!)

---

## 🔧 Configuratie

### Webhook URL instellen

Open `scrolldeeds/AnalyticsWebhookService.swift` en update de webhook URL:

```swift
// REGEL 15
private let webhookURL = "https://your-webhook-url.com/analytics"
```

**Vervang `https://your-webhook-url.com/analytics` met jouw eigen webhook endpoint!**

### Aanbevolen webhook services:
- **Webhook.site** (testing)
- **Zapier** (integraties met Google Sheets, Airtable, etc.)
- **Make.com** (geavanceerde automation)
- **Eigen backend** (volledige controle)

---

## 📦 Webhook Payload Format

Alle webhooks worden verstuurd als **JSON POST requests**.

### Payload structuur:

```json
{
  "event": "onboarding_completed | paywall_shown | user_subscribed",
  "timestamp": "2026-01-26T18:30:00Z",
  "user_data": {
    "age_group": "18-24",
    "referral_source": "Social Media",
    "is_premium": false,
    "platform": "iOS",
    "app_version": "1.0"
  }
}
```

### Event types:

| Event | Betekenis | `is_premium` |
|-------|-----------|--------------|
| `onboarding_completed` | User completed onboarding | `false` |
| `paywall_shown` | Paywall werd getoond | `false` |
| `user_subscribed` | User heeft betaald! | `true` ✅ |

---

## 📊 Data analyse

### Vragen die je nu kunt beantwoorden:

1. **Welke leeftijdsgroep downloadt de app?**
   - Tel `onboarding_completed` events per `age_group`

2. **Welke leeftijdsgroep betaalt?**
   - Tel `user_subscribed` events per `age_group`

3. **Conversion rate per leeftijd:**
   - `user_subscribed` / `onboarding_completed` per `age_group`

4. **Beste referral source:**
   - Tel `referral_source` van `user_subscribed` events

5. **ROI per marketing channel:**
   - Vergelijk `user_subscribed` per `referral_source`

### Voorbeeld queries (Google Sheets / Airtable):

```
// Conversie rate 18-24
= COUNTIFS(event, "user_subscribed", age_group, "18-24") / 
  COUNTIFS(event, "onboarding_completed", age_group, "18-24")

// Beste age group voor conversie
= MAX(conversie_rate_per_age_group)

// ROI per platform (SPECIFIEK!)
= COUNTIFS(event, "user_subscribed", referral_source, "Instagram") * average_ltv
= COUNTIFS(event, "user_subscribed", referral_source, "TikTok") * average_ltv
= COUNTIFS(event, "user_subscribed", referral_source, "YouTube") * average_ltv

// Welk platform converteert het best?
Instagram:  = COUNTIFS(source, "Instagram", event, "user_subscribed") / COUNTIFS(source, "Instagram")
TikTok:     = COUNTIFS(source, "TikTok", event, "user_subscribed") / COUNTIFS(source, "TikTok")
YouTube:    = COUNTIFS(source, "YouTube", event, "user_subscribed") / COUNTIFS(source, "YouTube")
```

### 🎯 Marketing Beslissingen op basis van data:

**Scenario 1: TikTok heeft beste conversie**
- TikTok: 50 subscriptions / 100 users = **50% conversie** 🔥
- Instagram: 20 subscriptions / 200 users = **10% conversie**
- YouTube: 30 subscriptions / 150 users = **20% conversie**
- **→ Investeer meer in TikTok marketing!**

**Scenario 2: Instagram heeft meeste volume**
- Instagram: 100 subscriptions (laagste conversie maar hoogste volume)
- TikTok: 50 subscriptions (beste conversie)
- YouTube: 30 subscriptions
- **→ Optimaliseer Instagram content + schaal TikTok op**

**Scenario 3: Age + Platform combinatie**
- TikTok + 18-24 = **60% conversie** 🚀
- Instagram + 25-34 = **45% conversie**
- YouTube + 35-44 = **30% conversie**
- **→ Target specifieke age groups per platform**

---

## 🧪 Testing

### 1. Test webhook URL

Gebruik [webhook.site](https://webhook.site) voor testing:
1. Ga naar webhook.site
2. Kopieer de gegenereerde URL
3. Plak in `AnalyticsWebhookService.swift` (regel 15)
4. Run de app en complete onboarding
5. Check webhook.site voor incoming requests

### 2. Debug logs

Het systeem print debug logs naar de console:
- ✅ `"✅ Webhook sent successfully: onboarding_completed"`
- ⚠️ `"⚠️ Webhook returned status code: 400"`
- ❌ `"❌ Webhook error: ..."`

---

## 🔐 Privacy & GDPR

### Opgeslagen data:
- **Leeftijdsgroep** (range, geen exacte leeftijd)
- **Referral source** (marketing channel)
- **Payment status** (boolean)
- **Geen persoonlijke identificeerbare informatie (PII)**

### Compliant met:
- ✅ GDPR (geen PII)
- ✅ Apple App Store guidelines
- ✅ Privacy-first design

---

## 📈 Aanbevolen setup

### Voor snelle start (5 minuten):

1. **Zapier + Google Sheets:**
   - Maak een Zapier webhook
   - Connect met Google Sheets
   - Automatisch data logging

2. **Airtable:**
   - Maak een Airtable base
   - Gebruik Airtable automation webhook
   - Visualisaties out-of-the-box

### Voor geavanceerde analytics:

1. **Eigen backend + database:**
   - PostgreSQL / MongoDB
   - Grafana dashboards
   - Real-time analytics

2. **Analytics platforms:**
   - Mixpanel
   - Amplitude
   - Segment

---

## 🆘 Troubleshooting

### Webhook niet ontvangen?

1. Check URL is correct (inclusief `https://`)
2. Check debug logs in Xcode console
3. Test met webhook.site eerst
4. Verify internet connectie

### Data komt niet binnen?

1. Check of vragen worden beantwoord in onboarding
2. Verify `UserDataManager` heeft data opgeslagen
3. Check debug logs voor errors

### Incomplete data?

- Gebruikers kunnen vragen overslaan → `"unknown"` values
- Dit is normaal en verwacht

---

## 📝 Voorbeeld Zapier Setup

1. **Trigger:** Webhooks by Zapier - Catch Hook
2. **Action 1:** Google Sheets - Create Row
   - `Event`: {{event}}
   - `Timestamp`: {{timestamp}}
   - `Age Group`: {{user_data__age_group}}
   - `Referral Source`: {{user_data__referral_source}}
   - `Is Premium`: {{user_data__is_premium}}

3. **Action 2 (optional):** Slack - Send Message
   - Trigger op `user_subscribed` events
   - "🎉 New subscriber: {{user_data__age_group}} via {{user_data__referral_source}}"

---

## 🔮 Toekomstige uitbreidingen

Makkelijk toe te voegen:
- Device type (iPhone model)
- OS version
- Install source (organic vs paid)
- First session timestamp
- Trial start/end dates
- Churn events

Laat me weten als je deze wilt toevoegen!

---

## 📞 Support

Voor vragen of problemen:
1. Check debug logs in Xcode
2. Test met webhook.site
3. Verify webhook URL configuratie

**Ready to track your conversions!** 🚀

*Laatste update: 26 januari 2026*
