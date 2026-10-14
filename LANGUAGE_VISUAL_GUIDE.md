# 🎨 TAAL SELECTOR - VISUAL PREVIEW

## 📱 HOE HET ERUITZIET:

### **1. ONBOARDING SCREEN (Vlag Knop)**

```
┌─────────────────────────────────────────┐
│                               🇬🇧 ▼      │ ← Vlag knop
│                                          │
│       BREAK PHONE ADDICTION              │
│      Through the Power of Dhikr         │
│                                          │
│            [Phone Mockup]                │
│                                          │
│   ┌─────────┐  ┌─────────┐             │
│   │ Lock    │  │ Dhikr   │             │
│   │ Apps    │  │ Unlock  │             │
│   └─────────┘  └─────────┘             │
│   ┌─────────┐  ┌─────────┐             │
│   │ Track   │  │ Reclaim │             │
│   │Progress │  │ Focus   │             │
│   └─────────┘  └─────────┘             │
│                                          │
│   ┌────────────────────────────────┐    │
│   │   START YOUR JOURNEY    →      │    │
│   └────────────────────────────────┘    │
│                                          │
└─────────────────────────────────────────┘
```

**Klik op 🇬🇧 → Opens:**

---

### **2. TAAL SELECTOR VIEW**

```
┌─────────────────────────────────────────┐
│  ✕                Language               │
│ ──────────────────────────────────────── │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  🇬🇧   English                 ✓   │ │ ← Selected (Golden glow)
│  │        English                      │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  🇸🇦   العربية                     │ │
│  │        Arabic                       │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  🇳🇱   Nederlands                  │ │
│  │        Dutch                        │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  🇫🇷   Français                    │ │
│  │        French                       │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  🇩🇪   Deutsch                     │ │
│  │        German                       │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  🇷🇺   Русский                     │ │
│  │        Russian                      │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  🇪🇸   Español                     │ │
│  │        Spanish                      │ │
│  └────────────────────────────────────┘ │
│                                          │
└─────────────────────────────────────────┘
```

**Styling Details:**
- ✨ Dark gradient background
- 🎨 Premium glassmorphism cards
- 🌟 Golden gradient border voor selected
- ✓ Golden checkmark voor selected
- 📏 1.02x scale voor selected
- 💫 Smooth animations

---

### **3. SETTINGS (Language Sectie)**

```
┌─────────────────────────────────────────┐
│                SETTINGS            ✕     │
│ ──────────────────────────────────────── │
│                                          │
│  Appearance                              │
│  ┌────────────────────────────────────┐ │
│  │  🌙  Dark Mode              ✓      │ │
│  │  ☀️  Light Mode                    │ │
│  │  ◐  System Default                 │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Language                                │
│  ┌────────────────────────────────────┐ │
│  │  🌍  App Language      🇬🇧  →      │ │ ← Klik hier
│  │      English                        │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Difficulty Level                        │
│  ┌────────────┐  ┌────────────┐        │
│  │   Easy     │  │   Medium   │        │
│  └────────────┘  └────────────┘        │
│                                          │
└─────────────────────────────────────────┘
```

**Klik op Language row → Opens Language Selector**

---

### **4. NA TAAL SWITCH (Bijvoorbeeld: Español)**

```
┌─────────────────────────────────────────┐
│                               🇪🇸 ▼      │ ← Vlag changed!
│                                          │
│    ROMPE LA ADICCIÓN AL TELÉFONO        │ ← Text changed!
│    A través del Poder del Dhikr         │ ← Text changed!
│                                          │
│            [Phone Mockup]                │
│                                          │
│   ┌─────────┐  ┌─────────┐             │
│   │Bloquear │  │ Dhikr   │             │ ← All changed!
│   │ Apps    │  │Desbloquear            │
│   └─────────┘  └─────────┘             │
│   ┌─────────┐  ┌─────────┐             │
│   │ Seguir  │  │Recuperar│             │
│   │Progreso │  │ Enfoque │             │
│   └─────────┘  └─────────┘             │
│                                          │
│   ┌────────────────────────────────┐    │
│   │   COMIENZA TU VIAJE     →      │    │ ← Button changed!
│   └────────────────────────────────┘    │
│                                          │
└─────────────────────────────────────────┘
```

**HELE APP IS NU IN HET SPAANS! 🇪🇸**

---

## 🎬 ANIMATIE FLOW:

### **Scenario 1: Nieuwe Gebruiker (Auto-Detect)**

```
User opent app voor eerste keer
         ↓
Device taal = Nederlands
         ↓
LanguageManager detecteert "nl"
         ↓
Laadt nl.lproj/Localizable.strings
         ↓
ONBOARDING IN NEDERLANDS! 🇳🇱
         ↓
Vlag knop toont: 🇳🇱 ▼
```

---

### **Scenario 2: Taal Switch via Vlag Knop**

```
User ziet 🇬🇧 ▼ rechts bovenaan
         ↓
Tikt op vlag knop
         ↓
Sheet slides up → LanguageSettingsView
         ↓
User ziet 7 talen met vlaggen
         ↓
User tikt op 🇪🇸 Español
         ↓
Haptic feedback (medium)
         ↓
LanguageManager.currentLanguage = "es"
         ↓
UserDefaults.set("es")
         ↓
Sheet auto-dismisses (0.5s delay)
         ↓
HELE APP INSTANTLY IN SPAANS! 🇪🇸
         ↓
Vlag knop nu: 🇪🇸 ▼
```

---

### **Scenario 3: Taal Switch via Settings**

```
User in app → Gaat naar Settings
         ↓
Scrollt naar "Language" sectie
         ↓
Ziet: "🌍 App Language  🇬🇧 →"
         ↓
Tikt op Language row
         ↓
Sheet slides up → LanguageSettingsView
         ↓
User selecteert 🇩🇪 Deutsch
         ↓
LanguageManager update + haptic
         ↓
Sheet dismisses
         ↓
HELE APP NU IN DUITS! 🇩🇪
         ↓
Language row nu: "🌍 App Language  🇩🇪 →"
```

---

## 🎨 DESIGN TOKENS:

### **Vlag Knop (Onboarding)**
```swift
- Background: .white.opacity(0.1)
- Border: .white.opacity(0.15), 1px
- Corner Radius: 20pt
- Padding: 12pt horizontal, 8pt vertical
- Font: System 20pt (flag), 12pt semibold (chevron)
- Color: .white.opacity(0.6) (chevron)
```

### **Language Row (Settings)**
```swift
- Background: AppTheme.card
- Corner Radius: 16pt
- Padding: 16pt horizontal, 14pt vertical
- Icon: globe, 20pt, AppTheme.primary
- Title: "App Language", 16pt, textPrimary
- Subtitle: Current language, 13pt, textSecondary
- Flag: 24pt emoji
- Chevron: right, 14pt semibold, textMuted
```

### **Language Card (Selector)**
```swift
// Normal State:
- Background: .white.opacity(0.04)
- Border: .white.opacity(0.05), 1px
- Corner Radius: 16pt
- Padding: 16pt

// Selected State:
- Background: .white.opacity(0.08)
- Border: Golden gradient (0.4 → 0.1), 1px
- Shadow: Golden glow, radius 12, y: 4
- Scale: 1.02x
- Checkmark: Black circle with golden gradient
```

---

## 📊 USER METRICS TO TRACK:

### **TelemetryDeck Events:**

```swift
// Wanneer language selector wordt geopend
"language_selector_opened"
- source: "onboarding" | "settings"

// Wanneer taal wordt gewijzigd
"language_changed"
- from: "en"
- to: "es"
- method: "manual" | "auto"
- location: "onboarding" | "settings"

// Bij eerste app open
"language_detected"
- device_language: "nl"
- supported: true | false
- fallback_used: false
```

Dit helpt je te zien:
- Welke talen het meest gebruikt worden
- Hoe vaak mensen handmatig switchen
- Welke talen meer conversie geven

---

## 🚀 NEXT STEPS:

1. **Test in Xcode:**
   - Run app
   - Klik vlag rechts bovenaan
   - Probeer alle 7 talen

2. **Test Auto-Detect:**
   - Edit Scheme → App Language → Dutch
   - Run app
   - Moet automatisch Nederlands zijn!

3. **Test Settings:**
   - Ga door onboarding
   - Open Settings
   - Test Language sectie

4. **Voeg Tracking Toe (Optioneel):**
   ```swift
   // In LanguageManager.swift
   AnalyticsManager.shared.track("language_changed", 
       metadata: [
           "from": oldLanguage,
           "to": newLanguage,
           "method": "manual"
       ]
   )
   ```

5. **Build & Deploy:**
   - Product → Archive
   - Distribute to TestFlight
   - Test op echte devices

---

**JE BENT KLAAR! 🎉**

Alle code is geïmplementeerd, alle talen zijn vertaald, UI ziet er premium uit!

**TEST HET NU IN XCODE!** 🚀
