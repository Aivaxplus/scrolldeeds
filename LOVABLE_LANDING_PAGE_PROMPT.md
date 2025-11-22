# 🎨 ScrollDeeds Landing Page Prompt (≤750 lines)

**Gebruik deze prompt in Lovable voor een landing page die exact aansluit bij de iOS-app.**

---

## 📋 Lovable Prompt
```
Create a premium, mobile-first landing page for ScrollDeeds — een islamitische mindfulness-app die afleidende apps vergrendelt en 15 minuten toegang geeft na geverifieerde dhikr. Houd vast aan de ScrollDeeds iOS esthetiek en benadruk dat alarms blijven afgaan totdat de gebruiker terugkeert om te relocken.

### DESIGN DNA (APPLE/NOTION STYLE)
- Minimalistisch, veel witruimte, subtiele schaduwen
- Mobile-first (320–768px) → daarna schaal naar tablet & desktop
- Fonts: Inter of SF Pro; duidelijke hiërarchie (Hero 40/64px, Section 32/48px, Body 16/18px)
- Kleuren (HEX exact):
  - Primary Green #388862
  - Accent Gold #E0AE52
  - Background #F7FAF7 (light) / #141F19 (dark)
  - Card #FFFFFF, Tekst #1A1A1A / #666666
- Buttons ≥48px hoog, afgeronde hoeken 10px, hover = iets donkerder
- Animaties: zachte fade-in (0.6s ease-out), hover = #FAFAFA; geen parallax of heavy effects
- Icons: line-icons, groen/goud accent
- Subtiele islamitische hints (sparkle/crescent), geen drukke patronen
- Dark mode via `prefers-color-scheme` (achtergrond #1A1A1A, cards #252525, tekst 90% wit)

### PAGINA-STRUCTUUR (MOBILE FIRST)
1. **Hero**
   - Header: “✨ ScrollDeeds”, hamburger rechts
   - Sparkle icon (32px, gold)
   - Titel “ScrollDeeds” (gradient op “Deeds” subtiel)
   - Tagline: “Transform Screen Time into Spiritual Time”
   - Beschrijving: “Lock distracting apps. Unlock through Islamic mindfulness. Earn 15 minutes by reciting dhikr 3 times.”
   - CTA’s: Primary “Download on App Store” (gold gradient) + secondary “Try Interactive Demo”
   - Trust row: “100% Privacy-First” • “No Data Collection”
   - iPhone mockup met dashboard screenshot (statich, 280px breed)

2. **How ScrollDeeds Works** (3 kaarten, stacked mobiel)
   - Titel “How ScrollDeeds Works” + subtitel “Three steps to mindful screen time”
   - Card 1: Lock Distracting Apps — kies apps, Family Controls
   - Card 2: Unlock Through Dhikr — reciteer Subhanallah/Alhamdulillah/Allahu Akbar/Astaghfirullah 3x, AI verificatie
   - Card 3: 15 Minutes Access — timer, na afloop relock + aanhoudende alarms tot gebruiker terugkeert
   - Kaarten: witte achtergrond, shadow 0 1px 3px rgba(0,0,0,0.08), radius 12px

3. **Why ScrollDeeds?**
   - Lichtgroene achtergrond (#F7FAF7)
   - Quote kaart met vers 3:185 (NL/EN + optioneel Arabisch)
   - Tekst: “Every second counts in the Akhira. ScrollDeeds laat je bewust pauzeren en Allah gedenken voor je weer doorgaat.”

4. **Interactive Demo**
   - Witte kaart, geen glassmorphism
   - Dropdown dhikr, record-knop (gold gradient, 120px), counter, timer (15:00 productie, 00:30 demo optie)
   - App icons grid (Instagram/TikTok/YouTube/Twitter/Facebook/Snapchat) met locked/unlocked animaties
   - Bij 0 → relock + melding

5. **Privacy First**
   - Titel “100% Private & Local”
   - Bullet card: “Alles lokaal”, “Geen analytics”, “Audio direct verwijderd”, “Family Controls integratie”

6. **Testimonials / Metrics (optioneel, kort)**
   - “15 minutes mindful focus”, “Alarms keep me accountable”

7. **FAQ (kort)**
   - “Hoe lang krijg ik toegang?” → 15 minuten + alarms
   - “Blijven de alarms afgaan?” → ja, elke 15s tot je herlockt
   - “Welke dhikr?” → 4 varianten
   - “Verzamelen jullie data?” → nee, alles lokaal

8. **Privacy Policy & Terms**
   - Toon volledige teksten (accordion of scrollable card). Gebruik contact: Sabri.makhoukhi@gmail.com / https://scrolldeeds.com

9. **Footer**
   - Donkergroen achtergrond
   - Logo + tagline “Transform Screen Time into Spiritual Time”
   - Links: Features • Try Demo • Privacy Policy • Terms • Support
   - “© 2025 ScrollDeeds. Made with 🤲 for the Ummah.”

### COPY HIGHLIGHTS
- 15 minuten toegang (geen 5 minuten verwijzingen)
- Benoem dat alarms elke 15 seconden blijven afgaan tot gebruiker terugkeert
- Dhikr: Subhanallah, Alhamdulillah, Allahu Akbar, Astaghfirullah
- Volledig privacy-first, geen accounts of tracking

### IMPLEMENTATIE HINTS (OPTIONEEL VOOR LOVABLE)
- import Inter; `font-display: swap`
- Buttons: `.btn-primary { background: linear-gradient(90deg,#33715C,#47A570); }`
- Cards: `box-shadow: 0 1px 3px rgba(0,0,0,0.08); border-radius:12px;`
- Responsief via CSS Grid/Flex; mobiel = single column
- Alarm copy: “If you ignore the timer, ScrollDeeds will keep sounding alarms every 15 seconds until you return.”

### CHECKLIST
- [ ] Mobile-first layout (24px side padding)
- [ ] Hero met CTA’s, iPhone mockup
- [ ] Features tonen 3 stappen + 15-min + aanhoudende alarmen
- [ ] Privacysectie met bullets
- [ ] FAQ of metric card
- [ ] Privacy Policy & Terms geïntegreerd
- [ ] Footer met contactlinks
- [ ] Dark mode support
- [ ] Subtle animations & hover states
- [ ] Tekst consistent met 15 minuten messaging

### EXTRA PROMPTS (OPTIONEEL)
- “Add subtle fade-in animations on scroll.”
- “Implement automatic dark mode based on user preference.”
- “Ensure mobile layout stacks everything with generous spacing.”
- “Use SVG line icons in green (#388862) and gold (#E0AE52).”
```

---

## ✅ Gebruik in Lovable
1. Start een nieuw project in Lovable.
2. Plak de prompt (inclusief checklist) in het promptveld.
3. Voeg optioneel app-screenshots toe.
4. Generate → verfijn met extra prompts of handmatige tweaks.

Succes! Deze compacte prompt (<750 regels) bevat alle essentiële richtlijnen voor een perfecte ScrollDeeds landing page. 🚀

