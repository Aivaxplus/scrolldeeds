## Localized mockup videos

Drop your per-language onboarding mockup videos into the **app target** using the naming below.

### File naming

- **Language-only**:
  - `OnboardingDemo_nl.mp4`
  - `OnboardingDemo_en.mp4`
  - `OnboardingDemo_ar.mp4`
- **Language + region/script** (optional):
  - `OnboardingDemo_pt-BR.mp4`
  - `OnboardingDemo_zh-Hans.mp4`

### How the app picks the video

It tries, in order:

1. `OnboardingDemo_<preferredLocalization>.mp4` (most specific first)
2. `OnboardingDemo_<baseLanguage>.mp4`
3. `OnboardingDemo_<currentLanguage>.mp4` (fallback hint)
4. `OnboardingDemo.mp4` (default)

### Example

If the device language is Dutch:

- `OnboardingDemo_nl.mp4` → used if present
- otherwise `OnboardingDemo_en.mp4` (if English is a preferred localization)
- otherwise `OnboardingDemo.mp4`

