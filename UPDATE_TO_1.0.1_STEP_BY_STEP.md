# 📱 App Store Update Guide - Versie 1.0.1

## Stap 1: Versie Nummer Updaten in Xcode

1. **Open Xcode** en open je project
2. **Selecteer het project** in de navigator (bovenaan links, "scrolldeeds")
3. **Selecteer het target** "scrolldeeds" (onder TARGETS)
4. **Ga naar de "General" tab**
5. **Update de versie nummers:**
   - **Version:** `1.0.1` (was 1.1)
   - **Build:** `7` (of verhoog naar 8 als 7 al bestaat)
6. **Sla op** (⌘S)

## Stap 2: Archive Maken

1. **Selecteer "Any iOS Device"** in de device selector (bovenaan naast de play button)
   - **NIET** een simulator of fysiek device
2. **Product menu → Clean Build Folder** (⌘⇧K)
3. **Product menu → Archive** (⌘B werkt niet, moet Archive zijn)
4. **Wacht** tot het archive klaar is (kan 2-5 minuten duren)

## Stap 3: Archive Uploaden naar App Store Connect

1. **Organizer venster opent automatisch** (of: Window → Organizer)
2. **Selecteer je nieuwe archive** (meest recente, met versie 1.0.1)
3. **Klik op "Distribute App"**
4. **Selecteer "App Store Connect"** → Next
5. **Selecteer "Upload"** → Next
6. **Distribution Options:**
   - ✅ "Upload your app's symbols" (aanbevolen)
   - ✅ "Manage Version and Build Number" (laat Xcode dit doen)
   - Next
7. **App Thinning:**
   - Selecteer "All compatible device variants"
   - Next
8. **Review:** Check dat alles klopt → Upload
9. **Wacht** tot upload klaar is (kan 5-15 minuten duren)

## Stap 4: App Store Connect - Nieuwe Versie Aanmaken

1. **Ga naar App Store Connect:** https://appstoreconnect.apple.com
2. **Mijn Apps** → Selecteer "ScrollDeeds"
3. **Versies** tab (links)
4. **Klik op "+" naast "iOS App"** (of "Nieuwe versie" button)
5. **Selecteer versie:** `1.0.1`
6. **Klik "Maken"**

## Stap 5: Build Selecteren

1. **Scroll naar "Build" sectie**
2. **Klik "Selecteren" naast Build**
3. **Selecteer je nieuwe build** (versie 1.0.1, build 7)
4. **Als je build niet ziet:**
   - Wacht 5-10 minuten (processing tijd)
   - Refresh de pagina
   - Check of upload succesvol was in Xcode Organizer

## Stap 6: Wat is Nieuw in Deze Versie (Release Notes)

**Nederlands:**
```
• Verbeterde navigatie met bottom bar
• Nieuwe progress tracking met grafieken
• Verbeterde feedback popup na 3 unlocks
• Share functionaliteit toegevoegd
• Bug fixes en performance verbeteringen
```

**Engels:**
```
• Improved navigation with bottom bar
• New progress tracking with charts
• Enhanced feedback popup after 3 unlocks
• Added share functionality
• Bug fixes and performance improvements
```

## Stap 7: Submit voor Review

1. **Check alle verplichte velden:**
   - ✅ Build geselecteerd
   - ✅ "Wat is nieuw" ingevuld
   - ✅ Export Compliance (meestal automatisch)
   - ✅ Advertising Identifier (als je ads gebruikt, anders N/A)

2. **Klik "Verzenden ter beoordeling"** (of "Submit for Review")

3. **Beantwoord eventuele vragen:**
   - Export Compliance: Meestal "No" (geen encryptie)
   - Advertising: "No" (als je geen ads hebt)

4. **Bevestig verzending**

## Stap 8: Wachten op Review

- **Processing:** 15 minuten - 2 uur
- **In Review:** 1-3 dagen (meestal 24-48 uur)
- **Ready for Sale:** App wordt automatisch gepubliceerd (of op je gekozen datum)

## Belangrijk: Check Before Submitting

- ✅ Versie nummer: 1.0.1
- ✅ Build nummer: 7 (of hoger)
- ✅ Alle nieuwe features werken
- ✅ Geen crashes tijdens testen
- ✅ Screenshots up-to-date (optioneel, maar aanbevolen)

## Troubleshooting

**Build niet zichtbaar in App Store Connect?**
- Wacht 10-15 minuten
- Check Xcode Organizer → Upload status
- Check App Store Connect → Activity → All Builds

**Upload failed?**
- Check internet verbinding
- Check of je ingelogd bent met juiste Apple ID
- Check signing & capabilities in Xcode

**Versie nummer conflict?**
- Zorg dat versie 1.0.1 nog niet bestaat in App Store Connect
- Of gebruik 1.0.2 als 1.0.1 al bestaat

---

**Succes met de update! 🚀**

