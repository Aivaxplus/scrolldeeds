# Quick Guide — mockup-afbeeldingen (How it works)

Elk van de 4 schermen kan een **eigen afbeelding** in de iPhone-mockup tonen.

## Optie A — aparte map (aanbevolen, zichtbaar in Finder)

1. Open de map **`scrolldeeds/QuickGuideMockupImages/`** op je Mac (staat naast je Swift-bestanden).
2. Zet daar bestanden met deze namen: `QuickGuidePage1.png` … `QuickGuidePage4.png` (ook `.jpg` / `.jpeg` / `.heic` / `.webp` kan).
3. Zie **`QuickGuideMockupImages/QuickGuideMockupImages_README.md`** voor details.

De app zoekt **eerst** in die map, **daarna** in Assets (zie optie B).

## Optie B — Asset Catalog

1. Open in Xcode het project **scrolldeeds**.
2. Ga naar **`scrolldeeds/Assets.xcassets`** (Asset Catalog).
3. Klik rechts in de lijst → **New Image Set** (of sleep PNG’s naar de catalog; Xcode maakt dan een set).
4. Hernoem de image set **exact** zo (dit moet overeenkomen met de code):

| Pagina | Image Set naam in Assets |
|--------|---------------------------|
| 1      | `QuickGuidePage1`         |
| 2      | `QuickGuidePage2`         |
| 3      | `QuickGuidePage3`         |
| 4      | `QuickGuidePage4`         |

5. Sleep je PNG (of PDF) in de **1x** (en optioneel **2x** / **3x**) slot van die set.
6. Zorg dat de image set **bij target “scrolldeeds”** hoort (Target Membership in File Inspector).

## Formaat (aanbevolen)

- **Portret**, vergelijkbaar met telefoonscherm (ca. **9:19.5** of screenshot van je app).
- De inhoud wordt **ingevuld en bijgesneden** (`aspectFill`) in het mockup-scherm.

## Als er nog geen afbeelding is

Dan gebruikt de app automatisch **`OnboardingDemoVideoView()`** (zelfde als Get Started), net als nu.
