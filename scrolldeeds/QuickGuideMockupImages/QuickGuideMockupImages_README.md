# Quick Guide mockup images (localized)

Use this folder: `scrolldeeds/QuickGuideMockupImages/`.

## Naming format

For each page (1-4), use:

- `QuickGuidePage1_<lang>.png`
- `QuickGuidePage2_<lang>.png`
- `QuickGuidePage3_<lang>.png`
- `QuickGuidePage4_<lang>.png`

Supported extensions: `png`, `jpg`, `jpeg`, `heic`, `webp`.

## 7-language file names

### English (`en`)
- `QuickGuidePage1_en.png`
- `QuickGuidePage2_en.png`
- `QuickGuidePage3_en.png`
- `QuickGuidePage4_en.png`

### Arabic (`ar`)
- `QuickGuidePage1_ar.png`
- `QuickGuidePage2_ar.png`
- `QuickGuidePage3_ar.png`
- `QuickGuidePage4_ar.png`

### Dutch (`nl`)
- `QuickGuidePage1_nl.png`
- `QuickGuidePage2_nl.png`
- `QuickGuidePage3_nl.png`
- `QuickGuidePage4_nl.png`

### French (`fr`)
- `QuickGuidePage1_fr.png`
- `QuickGuidePage2_fr.png`
- `QuickGuidePage3_fr.png`
- `QuickGuidePage4_fr.png`

### German (`de`)
- `QuickGuidePage1_de.png`
- `QuickGuidePage2_de.png`
- `QuickGuidePage3_de.png`
- `QuickGuidePage4_de.png`

### Russian (`ru`)
- `QuickGuidePage1_ru.png`
- `QuickGuidePage2_ru.png`
- `QuickGuidePage3_ru.png`
- `QuickGuidePage4_ru.png`

### Spanish (`es`)
- `QuickGuidePage1_es.png`
- `QuickGuidePage2_es.png`
- `QuickGuidePage3_es.png`
- `QuickGuidePage4_es.png`

## Fallback order

For each page, the app tries:

1. `QuickGuidePageX_<language-region/script>` (if present)
2. `QuickGuidePageX_<language>`
3. `QuickGuidePageX` (default, no suffix)

If no image is found, it falls back to the onboarding demo video.
