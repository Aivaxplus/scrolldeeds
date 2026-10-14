# Paywall mockup images (localized)

Put your per-language paywall mockup images in this folder:

`scrolldeeds/PaywallMockupImages/`

## Naming

Base name: `PaywallMockupImage`

Use:

- `PaywallMockupImage_<lang>.png`
- `PaywallMockupImage_<lang-region>.png` (optional)

Supported extensions: `png`, `jpg`, `jpeg`, `heic`, `webp`.

## 7-language file names

- `PaywallMockupImage_en.png`
- `PaywallMockupImage_ar.png`
- `PaywallMockupImage_nl.png`
- `PaywallMockupImage_fr.png`
- `PaywallMockupImage_de.png`
- `PaywallMockupImage_ru.png`
- `PaywallMockupImage_es.png`

Optional default fallback:
- `PaywallMockupImage.png` (no suffix)

## Fallback order

1. `PaywallMockupImage_<language-region/script>`
2. `PaywallMockupImage_<language>`
3. `PaywallMockupImage`

