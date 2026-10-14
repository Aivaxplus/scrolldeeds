import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    /// Plain stored value — never `@Published`. Publishing from init (or a
    /// double `objectWillChange`) recursed in `AppSceneDelegate.responds(to:)`
    /// after: dashboard → Settings → change language → kill → reopen.
    private(set) var currentLanguage: String

    /// The only published signal. Views that observe `LanguageManager` refresh
    /// when this bumps; `currentLanguage` itself stays silent during launch.
    @Published private(set) var languageEpoch: Int = 0

    // All supported languages with their display info (only these appear in the picker).
    static let supportedLanguages: [LanguageInfo] = [
        LanguageInfo(code: "en", name: "English", nativeName: "English", flag: "🇬🇧"),
        LanguageInfo(code: "ar", name: "Arabic", nativeName: "العربية", flag: "🇸🇦"),
        LanguageInfo(code: "nl", name: "Dutch", nativeName: "Nederlands", flag: "🇳🇱"),
        LanguageInfo(code: "fr", name: "French", nativeName: "Français", flag: "🇫🇷"),
        LanguageInfo(code: "de", name: "German", nativeName: "Deutsch", flag: "🇩🇪"),
        LanguageInfo(code: "ru", name: "Russian", nativeName: "Русский", flag: "🇷🇺"),
        LanguageInfo(code: "es", name: "Spanish", nativeName: "Español", flag: "🇪🇸")
    ]

    /// ISO-style codes that ship in the app (must match `supportedLanguages` only).
    static let supportedLanguageCodes: Set<String> = Set(supportedLanguages.map(\.code))

    /// Collapses any stored / incoming code to one of `supportedLanguageCodes` (never e.g. `ja` or `pt-BR`).
    static func normalizeLanguageCode(_ code: String?) -> String {
        if let raw = code?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !raw.isEmpty {
            if supportedLanguageCodes.contains(raw) { return raw }
            if let dash = raw.firstIndex(of: "-") {
                let base = String(raw[..<dash])
                if supportedLanguageCodes.contains(base) { return base }
            }
        }
        let detected = Locale.current.language.languageCode?.identifier ?? "en"
        return mapToSupportedLanguage(detected)
    }

    func setLanguage(_ code: String) {
        let normalized = Self.normalizeLanguageCode(code)
        guard normalized != currentLanguage else { return }
        currentLanguage = normalized
        persistLanguage(normalized)
        languageEpoch += 1
        // Deferred so the property is fully set before observers react
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
            NotificationManager.shared.refreshPendingNotificationsForCurrentLanguage()
            NafsiWidgetSettings.shared.publish()
        }
    }

    private init() {
        Self.clearSystemLanguageOverride()
        currentLanguage = Self.resolveStoredLanguage()
        persistLanguage(currentLanguage)
    }

    private static func resolveStoredLanguage() -> String {
        if let saved = UserDefaults.standard.string(forKey: "AppLanguage") {
            return normalizeLanguageCode(saved)
        }
        let detected = Locale.current.language.languageCode?.identifier ?? "en"
        return mapToSupportedLanguage(detected)
    }

    /// Drop the leftover `AppleLanguages` write from older builds. Must run before
    /// SwiftUI connects a scene — otherwise the next launch after a language change crashes.
    static func clearSystemLanguageOverride() {
        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
    }

    /// Main app + App Group so extensions (lock shield, auto-lock notifications) follow the in-app language.
    /// Do not write `AppleLanguages` at runtime — UIKit can crash or reload mid-render when that key changes.
    private func persistLanguage(_ code: String) {
        UserDefaults.standard.set(code, forKey: "AppLanguage")
        UserDefaults(suiteName: "group.com.scrolldeeds.app")?.set(code, forKey: "AppLanguage")
        Self.clearSystemLanguageOverride()
    }

    // Map device language codes to our supported languages
    // If device language is not supported, default to English
    static func mapToSupportedLanguage(_ languageCode: String) -> String {
        switch languageCode {
        case "en": return "en"
        case "es": return "es"
        case "ru": return "ru"
        case "de": return "de"
        case "nl": return "nl"
        case "ar": return "ar"
        case "fr": return "fr"
        default: return "en" // Default to English if not supported
        }
    }

    // Get localized string with current language
    func localizedString(_ key: String) -> String {
        guard let bundlePath = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else {
            return NSLocalizedString(key, comment: "")
        }
        let localized = bundle.localizedString(forKey: key, value: "", table: nil)
        if !localized.isEmpty, localized != key { return localized }
        if currentLanguage != "en",
           let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let enBundle = Bundle(path: enPath) {
            let fallback = enBundle.localizedString(forKey: key, value: "", table: nil)
            if !fallback.isEmpty { return fallback }
        }
        return NSLocalizedString(key, comment: "")
    }
}

struct LanguageInfo: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let nativeName: String
    let flag: String
}
