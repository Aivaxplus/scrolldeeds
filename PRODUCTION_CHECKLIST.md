# ScrollDeeds - Productie Ready Checklist

## ✅ Voltooid

### 1. Info.plist Configuratie
- ✅ `NSFamilyControlsUsageDescription` - Aanwezig
- ✅ `NSUserNotificationsUsageDescription` - Aanwezig  
- ✅ `NSSpeechRecognitionUsageDescription` - **Toegevoegd**
- ✅ `NSMicrophoneUsageDescription` - **Toegevoegd**
- ✅ `UIApplicationSceneManifest` - **Toegevoegd**

### 2. Entitlements
- ✅ `com.apple.developer.family-controls` - Aanwezig
- ✅ `aps-environment` - **Aangepast naar `production`**

### 3. Build Settings
- ✅ Bundle Identifier: `com.scrolldeeds.app`
- ✅ Marketing Version: `1.0`
- ✅ Current Project Version: `1`

### 4. Code Quality
- ✅ Debug logging helpers toegevoegd (alleen in DEBUG mode)
- ✅ Error handling aanwezig (geen force unwraps gevonden)
- ✅ Geen TODO/FIXME comments gevonden

### 5. Functionaliteit
- ✅ 5 minuten unlock timer (was 30 minuten)
- ✅ 3 keer dhikr reciteren (was 33 keer)
- ✅ Automatische shield applicatie na timer expiry
- ✅ Persistent app selection
- ✅ Background task support

### 6. Legal Documents
- ✅ Privacy Policy aangemaakt (`PRIVACY_POLICY.md`)
- ✅ Terms of Service aangemaakt (`TERMS_OF_SERVICE.md`)
- ⚠️ **Actie vereist**: Update contact informatie (email, website URL)
- ✅ Gehost op `https://scrolldeeds.lovable.app/privacy` en `https://scrolldeeds.lovable.app/terms`

## 📋 Pre-App Store Submission Checklist

### Xcode Configuratie
- [ ] App Icon ingesteld (alle sizes)
- [ ] Launch Screen ingesteld
- [ ] Code Signing & Capabilities geconfigureerd
- [ ] Development Team geselecteerd
- [ ] Provisioning Profile aangemaakt voor App Store Distribution

### App Store Connect
- [ ] App aangemaakt in App Store Connect
- [ ] Bundle ID matcht: `com.scrolldeeds.app`
- [ ] App Store screenshots (alle iPhone sizes)
- [ ] App Store description geschreven
- [ ] App Store keywords ingesteld
- [ ] Privacy Policy URL ingevuld
- [ ] Terms of Service URL ingevuld
- [ ] Support URL ingevuld
- [ ] Marketing URL (optioneel)

### Family Controls Approval
- [ ] **CRITICAAL**: Family Controls Distribution Approval aangevraagd bij Apple
  - Dit kan 2-4 weken duren
  - Request via: App Store Connect → App → Features → Family Controls
  - Reason: "Screen time management through Islamic mindfulness practices"

### TestFlight
- [ ] Build geüpload naar TestFlight
- [ ] Beta testers uitgenodigd
- [ ] Testen op echte devices
- [ ] Feedback verzameld

### Final Checks
- [ ] App werkt op iOS 16.0+ (minimum requirement)
- [ ] Alle features getest:
  - [ ] App selection & locking
  - [ ] Dhikr recording & verification
  - [ ] 5 minuten unlock timer
  - [ ] Automatische shield applicatie
  - [ ] Notifications
- [ ] Privacy Policy & Terms of Service beschikbaar
- [ ] Webhook service operationeel en getest

### Build voor Submission
- [ ] Archive gemaakt in Release mode
- [ ] Build geüpload naar App Store Connect
- [ ] App Store review informatie ingevuld
- [ ] Demo account (indien nodig)
- [ ] Review notes geschreven

## 🔧 Technische Details

### Minimum iOS Version
- iOS 16.0+ (required for Family Controls)

### Required Permissions
1. **Family Controls** - Voor app locking
2. **Speech Recognition** - Voor dhikr verificatie
3. **Microphone** - Voor audio recording
4. **Notifications** - Voor reminders

### Dependencies
- Geen externe dependencies (alleen Apple frameworks)

### Backend Services
- Webhook URL: `https://aivaxplus.app.n8n.cloud/webhook/7feb29f5-1a33-47f0-a8c7-9397e2d91e75`
- Service moet operationeel zijn voor dhikr verificatie

## ⚠️ Belangrijke Opmerkingen

1. **Family Controls Approval**: Dit is de meest kritieke stap. Zonder goedkeuring kan de app niet worden gepubliceerd.

2. **Webhook Service**: Zorg dat de n8n webhook service altijd operationeel is. Als deze faalt, kunnen gebruikers geen dhikr verifiëren.

3. **TestFlight**: Test altijd eerst via TestFlight voordat je submit naar App Store review.

4. **Privacy Policy**: Zorg dat de Privacy Policy en Terms of Service beschikbaar zijn op de landing page of een andere URL.

## 📝 Notities

- Debug prints zijn nu alleen actief in DEBUG builds
- Alle copy is aangepast naar 5 minuten en 3 keer dhikr
- Entitlements zijn ingesteld op production mode
- Info.plist bevat alle benodigde privacy descriptions
