# Legal Documents Setup Guide

## 📄 Documenten Aangemaakt

1. **PRIVACY_POLICY.md** - Privacy Policy voor ScrollDeeds
2. **TERMS_OF_SERVICE.md** - Terms of Service voor ScrollDeeds

## ⚠️ Acties Vereist

### 1. Contact Informatie Invullen

Beide documenten bevatten placeholder tekst die je moet aanpassen:

**Zoek en vervang in beide bestanden:**
- `[Your support email]` → Jouw echte support email
- `[Your website URL]` → Jouw website URL (bijv. `https://scrolldeeds.com`)
- `[Your Jurisdiction]` (alleen in Terms) → Jouw jurisdictie/land

### 2. Website Hosting

De app linkt naar:
- `https://scrolldeeds.lovable.app/privacy` - Privacy Policy
- `https://scrolldeeds.lovable.app/terms` - Terms of Service

**Je moet deze pagina's hosten op je website.**

#### Optie A: Direct Markdown naar HTML
- Converteer de `.md` bestanden naar HTML
- Upload naar `/privacy` en `/terms` routes op je website

#### Optie B: Gebruik een Static Site Generator
- Als je website een static site generator gebruikt (Jekyll, Hugo, etc.)
- Plaats de `.md` bestanden in de juiste directory
- Ze worden automatisch geconverteerd naar HTML

#### Optie C: Handmatig HTML
- Maak HTML versies van beide documenten
- Zorg voor goede styling en leesbaarheid
- Upload naar je web server

### 3. App Store Connect

In App Store Connect moet je invullen:
- **Privacy Policy URL**: `https://scrolldeeds.lovable.app/privacy`
- **Terms of Service URL**: `https://scrolldeeds.lovable.app/terms` (optioneel, maar aanbevolen)

## 📋 Checklist

- [ ] Contact email ingevuld in beide documenten
- [ ] Website URL ingevuld in beide documenten
- [ ] Jurisdictie ingevuld in Terms of Service
- [x] Privacy Policy gehost op `https://scrolldeeds.lovable.app/privacy`
- [x] Terms of Service gehost op `https://scrolldeeds.lovable.app/terms`
- [ ] Links getest in de app (OnboardingView)
- [ ] URLs ingevuld in App Store Connect

## 🔍 Document Inhoud

### Privacy Policy Bevat:
- ✅ Data verzameling (audio, app selection, usage)
- ✅ Hoe data wordt gebruikt
- ✅ Data storage en security
- ✅ Third-party services (n8n webhook, Apple frameworks)
- ✅ User rights en choices
- ✅ GDPR/CCPA compliance notities
- ✅ Contact informatie

### Terms of Service Bevat:
- ✅ Service beschrijving
- ✅ User responsibilities
- ✅ App functionality
- ✅ Intellectual property
- ✅ Disclaimers en liability
- ✅ Third-party services
- ✅ Termination clause
- ✅ Contact informatie

## 🎨 Styling Tips

Als je HTML versies maakt, zorg voor:
- Goede leesbaarheid (duidelijke fonts, spacing)
- Mobiele responsive design
- Dark mode support (optioneel)
- ScrollDeeds branding/kleuren

## ⚖️ Legal Compliance

De documenten zijn geschreven om te voldoen aan:
- ✅ Apple App Store Review Guidelines
- ✅ GDPR principes (voor EU gebruikers)
- ✅ CCPA principes (voor Californië gebruikers)
- ✅ Apple's privacy requirements

**Let op**: Deze documenten zijn templates. Voor professionele legal compliance, overweeg een jurist te raadplegen, vooral als je:
- Gebruikersdata verzamelt buiten wat hier beschreven staat
- Internationale markten target
- Betaalde features of subscriptions toevoegt

## 📞 Support

Als je vragen hebt over de documenten:
1. Lees beide documenten zorgvuldig door
2. Pas aan waar nodig voor jouw specifieke use case
3. Test de links in de app
4. Zorg dat alles gehost is voordat je naar App Store submit

