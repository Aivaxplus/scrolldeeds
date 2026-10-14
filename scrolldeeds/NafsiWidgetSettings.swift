//
//  NafsiWidgetSettings.swift
//  scrolldeeds
//
//  Home Screen and Lock Screen widget preferences, plus the Qur'an reminder times.
//  The widget extension reads a JSON payload from the app group.
//

import Foundation
import Combine
import WidgetKit

nonisolated struct NafsiWidgetQuote: Codable, Identifiable, Equatable, Sendable {
    var id: String
    var kind: String
    var text: String
    var arabic: String
    var reference: String
    var reflection: String
    /// Intentional themes (dhikr, patience, akhirah, …) used for time-of-day ranking.
    var themes: [String]

    enum CodingKeys: String, CodingKey {
        case id, kind, text, arabic, reference, reflection, themes
    }

    init(
        id: String,
        kind: String,
        text: String,
        arabic: String,
        reference: String,
        reflection: String,
        themes: [String] = []
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.arabic = arabic
        self.reference = reference
        self.reflection = reflection
        self.themes = themes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        kind = try c.decode(String.self, forKey: .kind)
        text = try c.decode(String.self, forKey: .text)
        arabic = try c.decodeIfPresent(String.self, forKey: .arabic) ?? ""
        reference = try c.decode(String.self, forKey: .reference)
        reflection = try c.decodeIfPresent(String.self, forKey: .reflection) ?? ""
        themes = try c.decodeIfPresent([String].self, forKey: .themes) ?? []
    }
}

struct NafsiWidgetPayload: Codable {
    var homeEnabled: Bool
    var lockEnabled: Bool
    var homeCategories: [String]
    var lockCategories: [String]
    var homeShowReflection: Bool
    var lockShowReflection: Bool
    var homeShowArabic: Bool
    var lockShowArabic: Bool
    var homeRefreshMinutes: Int
    var lockRefreshMinutes: Int
    var homeTextSize: String
    var lockTextSize: String
    var homeFont: String
    var lockFont: String
    var disabledTitle: String
    var kindLabels: [String: String]
    var quotes: [NafsiWidgetQuote]
}

final class NafsiWidgetSettings: ObservableObject {
    static let shared = NafsiWidgetSettings()
    static let appGroup = "group.com.scrolldeeds.app"
    static let payloadName = "widget-payload.json"
    static let maxReminderTimes = 8
    /// 0 = Custom times. Otherwise fire every N minutes between 08:00–22:00.
    static let reminderCadenceChoices = [30, 60, 120, 180, 240]
    static let reminderIntervalStart = 8 * 60
    static let reminderIntervalEnd = 22 * 60

    static let categories = ["quran", "dua", "hadith"]
    static let refreshChoices = [15, 30, 60, 180]
    static let textSizes = ["small", "standard", "large"]
    static let fonts = ["rounded", "serif"]

    @Published var homeEnabled: Bool
    @Published var lockEnabled: Bool
    @Published var homeCategories: Set<String>
    @Published var lockCategories: Set<String>
    @Published var homeShowReflection: Bool
    @Published var lockShowReflection: Bool
    @Published var homeShowArabic: Bool
    @Published var lockShowArabic: Bool
    @Published var homeRefreshMinutes: Int
    @Published var lockRefreshMinutes: Int
    @Published var homeTextSize: String
    @Published var lockTextSize: String
    @Published var homeFont: String
    @Published var lockFont: String

    @Published var quranRemindersEnabled: Bool
    @Published var reminderMinutes: [Int]
    /// 0 = custom list in `reminderMinutes`; otherwise interval in minutes.
    @Published var reminderCadenceMinutes: Int
    @Published var reminderWeekdays: Set<Int>
    @Published var reminderShowReflection: Bool

    private let defaults = UserDefaults.standard

    private init() {
        homeEnabled = defaults.object(forKey: Key.homeEnabled) as? Bool ?? true
        lockEnabled = defaults.object(forKey: Key.lockEnabled) as? Bool ?? true
        homeCategories = Self.set(defaults, Key.homeCategories, fallback: Self.categories)
        lockCategories = Self.set(defaults, Key.lockCategories, fallback: Self.categories)
        homeShowReflection = defaults.bool(forKey: Key.homeReflection)
        lockShowReflection = defaults.bool(forKey: Key.lockReflection)
        homeShowArabic = defaults.bool(forKey: Key.homeArabic)
        lockShowArabic = defaults.bool(forKey: Key.lockArabic)
        homeRefreshMinutes = defaults.object(forKey: Key.homeRefresh) as? Int ?? 30
        lockRefreshMinutes = defaults.object(forKey: Key.lockRefresh) as? Int ?? 30
        homeTextSize = defaults.string(forKey: Key.homeText) ?? "standard"
        lockTextSize = defaults.string(forKey: Key.lockText) ?? "standard"
        homeFont = defaults.string(forKey: Key.homeFont) ?? "rounded"
        lockFont = defaults.string(forKey: Key.lockFont) ?? "rounded"
        quranRemindersEnabled = defaults.object(forKey: Key.remindersOn) as? Bool ?? true
        reminderShowReflection = defaults.bool(forKey: Key.reminderReflection)
        reminderWeekdays = Self.weekdaySet(defaults)
        reminderCadenceMinutes = defaults.object(forKey: Key.reminderCadence) as? Int ?? 0
        if let saved = defaults.array(forKey: Key.reminderMinutes) as? [Int], !saved.isEmpty {
            reminderMinutes = saved.sorted()
        } else {
            let count = defaults.integer(forKey: "daily_spiritual_notification_count")
            reminderMinutes = Self.spreadMinutes(count: count == 0 ? 4 : count)
        }
        // Sync current flags into the app group as soon as settings load.
        DispatchQueue.main.async { [weak self] in
            self?.publish()
        }
    }

    func save() {
        defaults.set(homeEnabled, forKey: Key.homeEnabled)
        defaults.set(lockEnabled, forKey: Key.lockEnabled)
        defaults.set(Array(homeCategories), forKey: Key.homeCategories)
        defaults.set(Array(lockCategories), forKey: Key.lockCategories)
        defaults.set(homeShowReflection, forKey: Key.homeReflection)
        defaults.set(lockShowReflection, forKey: Key.lockReflection)
        defaults.set(homeShowArabic, forKey: Key.homeArabic)
        defaults.set(lockShowArabic, forKey: Key.lockArabic)
        defaults.set(homeRefreshMinutes, forKey: Key.homeRefresh)
        defaults.set(lockRefreshMinutes, forKey: Key.lockRefresh)
        defaults.set(homeTextSize, forKey: Key.homeText)
        defaults.set(lockTextSize, forKey: Key.lockText)
        defaults.set(homeFont, forKey: Key.homeFont)
        defaults.set(lockFont, forKey: Key.lockFont)
        defaults.set(quranRemindersEnabled, forKey: Key.remindersOn)
        defaults.set(reminderMinutes.sorted(), forKey: Key.reminderMinutes)
        defaults.set(reminderCadenceMinutes, forKey: Key.reminderCadence)
        defaults.set(Array(reminderWeekdays).sorted(), forKey: Key.reminderWeekdays)
        defaults.set(reminderShowReflection, forKey: Key.reminderReflection)
        let count = min(max(effectiveReminderMinutes.count, 1), max(Self.maxReminderTimes, effectiveReminderMinutes.count))
        defaults.set(count, forKey: "daily_spiritual_notification_count")
        // Push to the widget extension immediately — before slower notification work.
        publish()
        NotificationManager.shared.scheduleDailySpiritualReminders()
    }

    func publish() {
        let lang = LanguageManager.shared.currentLanguage
        // After trial/sub ends, Home/Lock widgets show the disabled state until the user pays.
        let premiumAccess = SubscriptionManager.shared.hasPremiumAccess
        let effectiveHomeEnabled = homeEnabled && premiumAccess
        let effectiveLockEnabled = lockEnabled && premiumAccess
        let payload = NafsiWidgetPayload(
            homeEnabled: effectiveHomeEnabled,
            lockEnabled: effectiveLockEnabled,
            homeCategories: Array(homeCategories),
            lockCategories: Array(lockCategories),
            homeShowReflection: homeShowReflection,
            lockShowReflection: lockShowReflection,
            homeShowArabic: homeShowArabic,
            lockShowArabic: lockShowArabic,
            homeRefreshMinutes: homeRefreshMinutes,
            lockRefreshMinutes: lockRefreshMinutes,
            homeTextSize: homeTextSize,
            lockTextSize: lockTextSize,
            homeFont: homeFont,
            lockFont: lockFont,
            disabledTitle: premiumAccess
                ? NSLocalizedString("widget.disabled", comment: "Turn on widgets in Nafsi")
                : NSLocalizedString("widget.disabled.premium", comment: "Subscribe in Nafsi to unlock widgets"),
            kindLabels: [
                "quran": NSLocalizedString("widget.kind.quran", comment: "Qur'an"),
                "dua": NSLocalizedString("widget.kind.dua", comment: "Du'a"),
                "hadith": NSLocalizedString("widget.kind.hadith", comment: "Hadith")
            ],
            quotes: NafsiQuoteCatalog.quotes(language: lang)
        )

        // Fast path: App Group UserDefaults so the extension sees enable/display
        // flags even if the JSON write is delayed or fails.
        if let suite = UserDefaults(suiteName: Self.appGroup) {
            suite.set(effectiveHomeEnabled, forKey: SuiteKey.homeEnabled)
            suite.set(effectiveLockEnabled, forKey: SuiteKey.lockEnabled)
            suite.set(Array(homeCategories), forKey: SuiteKey.homeCategories)
            suite.set(Array(lockCategories), forKey: SuiteKey.lockCategories)
            suite.set(homeShowReflection, forKey: SuiteKey.homeReflection)
            suite.set(lockShowReflection, forKey: SuiteKey.lockReflection)
            suite.set(homeShowArabic, forKey: SuiteKey.homeArabic)
            suite.set(lockShowArabic, forKey: SuiteKey.lockArabic)
            suite.set(homeRefreshMinutes, forKey: SuiteKey.homeRefresh)
            suite.set(lockRefreshMinutes, forKey: SuiteKey.lockRefresh)
            suite.set(homeTextSize, forKey: SuiteKey.homeText)
            suite.set(lockTextSize, forKey: SuiteKey.lockText)
            suite.set(homeFont, forKey: SuiteKey.homeFont)
            suite.set(lockFont, forKey: SuiteKey.lockFont)
            suite.set(payload.disabledTitle, forKey: SuiteKey.disabledTitle)
            suite.set(Date().timeIntervalSince1970, forKey: SuiteKey.updatedAt)
            suite.synchronize()
        }

        if let data = try? JSONEncoder().encode(payload),
           let url = Self.payloadURL {
            try? data.write(to: url, options: .atomic)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "NafsiHomeWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "NafsiLockWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Keys mirrored into the app group for the widget extension.
    enum SuiteKey {
        static let homeEnabled = "nafsi.widget.homeEnabled"
        static let lockEnabled = "nafsi.widget.lockEnabled"
        static let homeCategories = "nafsi.widget.homeCategories"
        static let lockCategories = "nafsi.widget.lockCategories"
        static let homeReflection = "nafsi.widget.homeReflection"
        static let lockReflection = "nafsi.widget.lockReflection"
        static let homeArabic = "nafsi.widget.homeArabic"
        static let lockArabic = "nafsi.widget.lockArabic"
        static let homeRefresh = "nafsi.widget.homeRefresh"
        static let lockRefresh = "nafsi.widget.lockRefresh"
        static let homeText = "nafsi.widget.homeText"
        static let lockText = "nafsi.widget.lockText"
        static let homeFont = "nafsi.widget.homeFont"
        static let lockFont = "nafsi.widget.lockFont"
        static let disabledTitle = "nafsi.widget.disabledTitle"
        static let updatedAt = "nafsi.widget.updatedAt"
    }

    var reminderSlots: [(hour: Int, minute: Int)] {
        effectiveReminderMinutes.map { ($0 / 60, $0 % 60) }
    }

    /// Times that actually fire — interval cadence or the custom list.
    var effectiveReminderMinutes: [Int] {
        if reminderCadenceMinutes > 0 {
            return Self.intervalMinutes(every: reminderCadenceMinutes)
        }
        return reminderMinutes.sorted()
    }

    var isCustomReminderCadence: Bool { reminderCadenceMinutes <= 0 }

    func setReminderCadence(_ minutes: Int) {
        reminderCadenceMinutes = max(0, minutes)
        if reminderCadenceMinutes == 0, reminderMinutes.isEmpty {
            reminderMinutes = Self.spreadMinutes(count: 4)
        }
        save()
    }

    func addReminder(hour: Int, minute: Int) {
        reminderCadenceMinutes = 0
        guard reminderMinutes.count < Self.maxReminderTimes else { return }
        let value = hour * 60 + minute
        guard !reminderMinutes.contains(value) else { return }
        reminderMinutes.append(value)
        reminderMinutes.sort()
        save()
    }

    func removeReminder(minutes: Int) {
        reminderCadenceMinutes = 0
        guard reminderMinutes.count > 1 else { return }
        reminderMinutes.removeAll { $0 == minutes }
        save()
    }

    static func partOfDayKey(minutes: Int) -> String {
        let hour = minutes / 60
        switch hour {
        case 5..<12: return "widget.time.morning"
        case 12..<17: return "widget.time.afternoon"
        case 17..<21: return "widget.time.evening"
        default: return "widget.time.night"
        }
    }

    static func cadenceTitleKey(_ minutes: Int) -> String {
        switch minutes {
        case 30: return "widget.reminders.every.30"
        case 60: return "widget.reminders.every.60"
        case 120: return "widget.reminders.every.120"
        case 180: return "widget.reminders.every.180"
        case 240: return "widget.reminders.every.240"
        default: return "widget.reminders.custom"
        }
    }

    static func intervalMinutes(
        every step: Int,
        start: Int = reminderIntervalStart,
        end: Int = reminderIntervalEnd
    ) -> [Int] {
        guard step > 0 else { return [] }
        var result: [Int] = []
        var t = start
        while t <= end {
            result.append(t)
            t += step
        }
        return result
    }

    static func spreadMinutes(count: Int) -> [Int] {
        let count = min(max(count, 1), maxReminderTimes)
        let start = 8 * 60
        let end = 21 * 60
        if count == 1 { return [9 * 60 + 30] }
        return (0..<count).map { index in
            start + ((end - start) * index) / (count - 1)
        }
    }

    private static var payloadURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent(payloadName)
    }

    private static func set(_ defaults: UserDefaults, _ key: String, fallback: [String]) -> Set<String> {
        if let saved = defaults.stringArray(forKey: key), !saved.isEmpty {
            return Set(saved)
        }
        return Set(fallback)
    }

    private static func weekdaySet(_ defaults: UserDefaults) -> Set<Int> {
        if let saved = defaults.array(forKey: Key.reminderWeekdays) as? [Int], !saved.isEmpty {
            return Set(saved)
        }
        return Set(1...7)
    }

    private enum Key {
        static let homeEnabled = "nafsi.widget.homeEnabled"
        static let lockEnabled = "nafsi.widget.lockEnabled"
        static let homeCategories = "nafsi.widget.homeCategories"
        static let lockCategories = "nafsi.widget.lockCategories"
        static let homeReflection = "nafsi.widget.homeReflection"
        static let lockReflection = "nafsi.widget.lockReflection"
        static let homeArabic = "nafsi.widget.homeArabic"
        static let lockArabic = "nafsi.widget.lockArabic"
        static let homeRefresh = "nafsi.widget.homeRefresh"
        static let lockRefresh = "nafsi.widget.lockRefresh"
        static let homeText = "nafsi.widget.homeText"
        static let lockText = "nafsi.widget.lockText"
        static let homeFont = "nafsi.widget.homeFont"
        static let lockFont = "nafsi.widget.lockFont"
        static let remindersOn = "nafsi.quranReminders.enabled"
        static let reminderMinutes = "nafsi.quranReminders.minutes"
        static let reminderCadence = "nafsi.quranReminders.cadenceMinutes"
        static let reminderWeekdays = "nafsi.quranReminders.weekdays"
        static let reminderReflection = "nafsi.quranReminders.reflection"
    }
}

nonisolated enum NafsiQuoteCatalog {
    /// Collapsed banners still fit; full sources are never truncated for filtering.
    static let notificationTitleLimit = 80
    static let notificationBodyLimit = 140

    /// Time-of-day themes so reminders feel intentional, not random.
    enum Moment {
        case morning, midday, evening, night

        static func current(at date: Date = Date()) -> Moment {
            let hour = Calendar.current.component(.hour, from: date)
            switch hour {
            case 5..<11: return .morning
            case 11..<15: return .midday
            case 15..<20: return .evening
            default: return .night
            }
        }

        var preferredThemes: Set<String> {
            switch self {
            case .morning: return ["gratitude", "intention", "dhikr", "prayer", "start", "presence"]
            case .midday: return ["patience", "self_control", "focus", "speech", "strength", "time"]
            case .evening: return ["akhirah", "return", "mercy", "presence", "time", "focus"]
            case .night: return ["mercy", "tawbah", "trust", "rest", "nearness", "return"]
            }
        }
    }

    static func quotes(language: String) -> [NafsiWidgetQuote] {
        let lang = ["en", "nl", "es", "de", "fr", "ru", "ar"].contains(language) ? language : "en"
        return (seeds + extraSeeds).map { seed in
            let themes = seed.themes.isEmpty ? (defaultThemes[seed.id] ?? []) : seed.themes
            return NafsiWidgetQuote(
                id: seed.id,
                kind: seed.kind,
                text: seed.text[lang] ?? seed.text["en"] ?? "",
                arabic: seed.arabic,
                reference: seed.reference(language: lang),
                reflection: seed.reflection[lang] ?? seed.reflection["en"] ?? "",
                themes: themes
            )
        }
    }

    /// Themes for main-catalog seeds (extra seeds carry their own).
    private static let defaultThemes: [String: [String]] = [
        "q-2-152": ["dhikr", "presence", "start"],
        "q-13-28": ["dhikr", "presence", "rest"],
        "q-94-6": ["mercy", "patience", "trust"],
        "q-2-286": ["patience", "trust", "strength"],
        "q-39-53": ["mercy", "tawbah", "return"],
        "q-2-186": ["nearness", "dua", "presence"],
        "q-102-1m": ["akhirah", "focus", "time"],
        "d-2-201": ["dua", "akhirah", "intention"],
        "d-20-114": ["intention", "start", "gratitude"],
        "d-9-129": ["trust", "rest", "nearness"],
        "h-strong": ["strength", "self_control", "focus"],
        "h-brothers": ["speech", "self_control", "presence"],
        "q-2-153": ["patience", "prayer", "strength"],
        "q-3-139": ["strength", "patience", "trust"],
        "q-13-11": ["intention", "return", "focus"],
        "q-65-3": ["trust", "rest", "nearness"],
        "q-94-5": ["mercy", "patience", "trust"],
        "q-49-10": ["speech", "presence"],
        "q-29-69": ["intention", "strength", "focus"],
        "q-3-173": ["trust", "rest", "nearness"],
        "q-16-97": ["intention", "gratitude", "akhirah"],
        "d-71-28": ["dua", "mercy", "return"],
        "d-2-286b": ["tawbah", "mercy", "return"],
        "d-20-25": ["dua", "start", "presence"],
        "d-3-8": ["dua", "trust", "presence"],
        "d-dhikr": ["dhikr", "gratitude", "prayer"],
        "h-intent": ["intention", "focus", "start"],
        "h-quran": ["intention", "dhikr", "start"],
        "h-smile": ["speech", "presence", "gratitude"],
        "h-speech": ["speech", "self_control", "akhirah"],
        "h-easy": ["speech", "patience", "presence"],
        "h-anger": ["self_control", "patience", "speech"],
    ]

    /// Quotes short enough to show in full on a collapsed iOS notification.
    /// Full source strings are always kept — only the verse/hadith body is length-checked.
    static func notificationQuotes(language: String, kinds: Set<String>) -> [NafsiWidgetQuote] {
        quotes(language: language).filter { quote in
            kinds.contains(quote.kind)
                && !quote.text.isEmpty
                && quote.text.count <= notificationBodyLimit
                && !quote.reference.isEmpty
        }
    }

    /// Prefer quotes that match the hour’s themes; still rotate within that set.
    static func rankedQuotes(_ quotes: [NafsiWidgetQuote], at date: Date) -> [NafsiWidgetQuote] {
        let preferred = Moment.current(at: date).preferredThemes
        return quotes.sorted { lhs, rhs in
            let left = lhs.themes.filter { preferred.contains($0) }.count
            let right = rhs.themes.filter { preferred.contains($0) }.count
            if left != right { return left > right }
            return lhs.id < rhs.id
        }
    }

    /// Pick a meaningful quote for a scheduled slot (moment first, then stable rotation).
    static func quoteForSlot(
        from pool: [NafsiWidgetQuote],
        at date: Date,
        dayKey: String,
        slot: Int
    ) -> NafsiWidgetQuote? {
        guard !pool.isEmpty else { return nil }
        let preferred = Moment.current(at: date).preferredThemes
        let matched = pool.filter { !$0.themes.filter { preferred.contains($0) }.isEmpty }
        let use = matched.isEmpty ? pool : matched
        var mixed = slot &* 17
        mixed = mixed &+ dayKey.utf8.reduce(0) { ($0 &* 31) &+ Int($1) }
        return use[abs(mixed) % use.count]
    }

    nonisolated struct Seed: Sendable {
        let id: String
        let kind: String
        let arabic: String
        let ref: String
        let text: [String: String]
        let reflection: [String: String]
        let themes: [String]

        init(
            id: String,
            kind: String,
            arabic: String,
            ref: String,
            text: [String: String],
            reflection: [String: String],
            themes: [String] = []
        ) {
            self.id = id
            self.kind = kind
            self.arabic = arabic
            self.ref = ref
            self.text = text
            self.reflection = reflection
            self.themes = themes
        }

        func reference(language: String) -> String {
            if Self.isAyahReference(ref) {
                let name = quranName[language] ?? quranName["en"]!
                return "\(name) \(ref)"
            }
            return Self.fullCollectionSource(ref)
        }

        /// Qur'an-style refs like "2:152" (not collection names).
        private static func isAyahReference(_ ref: String) -> Bool {
            let parts = ref.split(separator: ":")
            guard parts.count == 2 else { return false }
            return parts[0].allSatisfy(\.isNumber)
                && parts[1].allSatisfy { $0.isNumber || $0 == "-" || $0 == "–" }
        }

        /// Expand short labels ("Muslim", "Bukhari") to full collection names.
        private static func fullCollectionSource(_ ref: String) -> String {
            let trimmed = ref.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return trimmed }
            // Split dual citations: "Bukhari · Muslim" / "Sahih al-Bukhari · Sahih Muslim"
            let separators = [" · ", "; "]
            var parts: [String] = [trimmed]
            for sep in separators {
                if trimmed.contains(sep) {
                    parts = trimmed.components(separatedBy: sep).map { $0.trimmingCharacters(in: .whitespaces) }
                    break
                }
            }
            return parts.map { expandOneCollection($0) }.joined(separator: " · ")
        }

        private static func expandOneCollection(_ part: String) -> String {
            let part = part.trimmingCharacters(in: .whitespaces)
            guard !part.isEmpty else { return part }

            // Already a full collection name — only normalize apostrophe variants.
            if part.hasPrefix("Sahih ") || part.hasPrefix("Sunan ") || part.hasPrefix("Jami") {
                if part.hasPrefix("Jami at-Tirmidhi") {
                    return "Jami' at-Tirmidhi" + part.dropFirst("Jami at-Tirmidhi".count)
                }
                return part
            }

            let shortMap: [(String, String)] = [
                ("Abu Dawud", "Sunan Abu Dawud"),
                ("Bukhari", "Sahih al-Bukhari"),
                ("Muslim", "Sahih Muslim"),
                ("Tirmidhi", "Jami' at-Tirmidhi")
            ]
            for (short, full) in shortMap {
                if part == short { return full }
                if part.hasPrefix(short + " ") {
                    return full + String(part.dropFirst(short.count))
                }
            }
            return part
        }
    }

    private static let quranName = [
        "en": "Qur'an", "nl": "Koran", "es": "Corán", "de": "Koran",
        "fr": "Coran", "ru": "Коран", "ar": "القرآن"
    ]

    private static let seeds: [Seed] = [
        Seed(id: "q-2-152", kind: "quran", arabic: "فَاذْكُرُونِي أَذْكُرْكُمْ", ref: "2:152",
             text: [
                "en": "So remember Me; I will remember you.",
                "nl": "Gedenk Mij, dan gedenk Ik jou.",
                "es": "Acordaos de Mí, y Yo me acordaré de vosotros.",
                "de": "Gedenkt Meiner, so gedenke Ich euer.",
                "fr": "Rappelez-vous de Moi, Je Me rappellerai de vous.",
                "ru": "Поминайте Меня, и Я буду поминать вас.",
                "ar": "فَاذْكُرُونِي أَذْكُرْكُمْ"
             ],
             reflection: [
                "en": "Before the next scroll — remember Him once.",
                "nl": "Voor de volgende scroll — gedenk Hem één keer.",
                "es": "Antes del próximo scroll — recuérdalo una vez.",
                "de": "Vor dem nächsten Scroll — gedenke Seiner einmal.",
                "fr": "Avant le prochain scroll — évoque-Le une fois.",
                "ru": "Перед следующим скроллом — помяни Его один раз.",
                "ar": "قبل التمرير التالي — اذكره مرة."
             ]),
        Seed(id: "q-13-28", kind: "quran", arabic: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ", ref: "13:28",
             text: [
                "en": "In the remembrance of Allah do hearts find rest.",
                "nl": "In het gedenken van Allah vinden harten rust.",
                "es": "En el recuerdo de Allah hallan sosiego los corazones.",
                "de": "Im Gedenken Allahs finden die Herzen Ruhe.",
                "fr": "C’est par le rappel d’Allah que les cœurs s’apaisent.",
                "ru": "Поминанием Аллаха успокаиваются сердца.",
                "ar": "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ"
             ],
             reflection: [
                "en": "What is your heart holding that the feed cannot put down?",
                "nl": "Wat houdt je hart vast dat de feed niet kan neerleggen?",
                "es": "¿Qué guarda tu corazón que el feed no puede soltar?",
                "de": "Was hält dein Herz fest, das der Feed nicht ablegen kann?",
                "fr": "Que retient ton cœur, que le fil ne peut déposer ?",
                "ru": "Что держит твоё сердце, что лента не может отпустить?",
                "ar": "ما الذي يحمله قلبك ولا يستطيع الشريط أن يضعه؟"
             ]),
        Seed(id: "q-94-6", kind: "quran", arabic: "إِنَّ مَعَ الْعُسْرِ يُسْرًا", ref: "94:6",
             text: [
                "en": "Indeed, with hardship comes ease.",
                "nl": "Voorwaar, bij de zwaarte komt verlichting.",
                "es": "En verdad, con la dificultad viene la facilidad.",
                "de": "Wahrlich, mit der Schwierigkeit kommt Erleichterung.",
                "fr": "Certes, avec la difficulté vient la facilité.",
                "ru": "Воистину, за трудностью приходит облегчение.",
                "ar": "إِنَّ مَعَ الْعُسْرِ يُسْرًا"
             ],
             reflection: [
                "en": "The hard moment is not the whole story.",
                "nl": "Het zware moment is niet het hele verhaal.",
                "es": "El momento difícil no es toda la historia.",
                "de": "Der schwere Moment ist nicht die ganze Geschichte.",
                "fr": "Le moment difficile n’est pas toute l’histoire.",
                "ru": "Тяжёлый момент — не вся история.",
                "ar": "اللحظة الصعبة ليست القصة كلها."
             ]),
        Seed(id: "q-2-286", kind: "quran", arabic: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا", ref: "2:286",
             text: [
                "en": "Allah does not burden a soul beyond what it can bear.",
                "nl": "Allah belast een ziel niet boven wat zij kan dragen.",
                "es": "Allah no impone a nadie una carga mayor de la que puede soportar.",
                "de": "Allah erlegt keiner Seele mehr auf, als sie tragen kann.",
                "fr": "Allah n’impose à aucune âme une charge au-delà de sa capacité.",
                "ru": "Аллах не возлагает на душу сверх её возможностей.",
                "ar": "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا"
             ],
             reflection: [
                "en": "What is in front of you is within what you were given.",
                "nl": "Wat voor je ligt, past bij wat je is gegeven.",
                "es": "Lo que tienes delante cabe en lo que se te ha dado.",
                "de": "Was vor dir liegt, liegt in dem, was dir gegeben wurde.",
                "fr": "Ce qui est devant toi tient dans ce qui t’a été donné.",
                "ru": "То, что перед тобой, по силам тому, что тебе дано.",
                "ar": "ما أمامك داخل فيما أُعطيت."
             ]),
        Seed(id: "q-39-53", kind: "quran", arabic: "لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ", ref: "39:53",
             text: [
                "en": "Do not despair of the mercy of Allah.",
                "nl": "Wanhoop niet aan de barmhartigheid van Allah.",
                "es": "No desesperéis de la misericordia de Allah.",
                "de": "Verzweifelt nicht an der Barmherzigkeit Allahs.",
                "fr": "Ne désespérez pas de la miséricorde d’Allah.",
                "ru": "Не отчаивайтесь в милости Аллаха.",
                "ar": "لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ"
             ],
             reflection: [
                "en": "Mercy is closer than the mistake you keep replaying.",
                "nl": "Barmhartigheid is dichterbij dan de fout die je blijft herhalen.",
                "es": "La misericordia está más cerca que el error que repites.",
                "de": "Barmherzigkeit ist näher als der Fehler, den du wiederholst.",
                "fr": "La miséricorde est plus proche que la faute que tu rejoues.",
                "ru": "Милость ближе, чем ошибка, которую ты прокручиваешь.",
                "ar": "الرحمة أقرب من الخطأ الذي تعيده."
             ]),
        Seed(id: "q-2-186", kind: "quran", arabic: "فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ", ref: "2:186",
             text: [
                "en": "I am near. I answer the call of the caller when he calls upon Me.",
                "nl": "Ik ben nabij. Ik verhoor de roep van wie Mij aanroept.",
                "es": "Estoy cerca. Respondo a quien Me invoca.",
                "de": "Ich bin nahe. Ich erhöre den Ruf dessen, der Mich anruft.",
                "fr": "Je suis tout proche. Je réponds à l’appel de celui qui M’invoque.",
                "ru": "Я близок. Я отвечаю зовущему, когда он взывает ко Мне.",
                "ar": "فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ"
             ],
             reflection: [
                "en": "Make the next thing you ask a real du'a.",
                "nl": "Maak het volgende dat je vraagt een echte du'a.",
                "es": "Que lo próximo que pidas sea una du'a de verdad.",
                "de": "Mach das Nächste, worum du bittest, zu einem echten Du'a.",
                "fr": "Que la prochaine chose que tu demandes soit une vraie du'a.",
                "ru": "Пусть следующее, о чём ты просишь, будет настоящей дуа.",
                "ar": "اجعل طلبك التالي دعاءً حقيقيًا."
             ]),
        Seed(id: "q-102-1m", kind: "quran", arabic: "أَلْهَاكُمُ التَّكَاثُرُ حَتَّىٰ زُرْتُمُ الْمَقَابِرَ", ref: "102:1-2",
             text: [
                "en": "Competition in increase diverts you until you visit the graves.",
                "nl": "Wedijver om meer houdt jullie af totdat jullie de graven bezoeken.",
                "es": "La competencia por aumentar os distrae hasta que visitáis las tumbas.",
                "de": "Das Wetteifern um Mehr hält euch ab, bis ihr die Gräber besucht.",
                "fr": "La course à l’abondance vous distrait jusqu’à ce que vous visitiez les tombes.",
                "ru": "Соревнование в умножении отвлекает вас, пока вы не посетите могилы.",
                "ar": "أَلْهَاكُمُ التَّكَاثُرُ حَتَّىٰ زُرْتُمُ الْمَقَابِرَ"
             ],
             reflection: [
                "en": "What you are racing for on this screen will not follow you.",
                "nl": "Waar je op dit scherm achteraan rent, volgt je niet.",
                "es": "Lo que persigues en esta pantalla no te seguirá.",
                "de": "Wofür du auf diesem Screen rennst, folgt dir nicht.",
                "fr": "Ce que tu cours après sur cet écran ne te suivra pas.",
                "ru": "То, за чем ты гонишься на этом экране, за тобой не пойдёт.",
                "ar": "ما تركض خلفه على هذه الشاشة لن يتبعك."
             ],
             themes: ["akhirah", "focus", "time"]),
        Seed(id: "d-2-201", kind: "dua", arabic: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ", ref: "2:201",
             text: [
                "en": "Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.",
                "nl": "Onze Heer, geef ons het goede in deze wereld en het goede in het Hiernamaals, en behoed ons voor de bestraffing van het Vuur.",
                "es": "Señor nuestro, danos lo bueno en esta vida y lo bueno en la Otra, y protégenos del castigo del Fuego.",
                "de": "Unser Herr, gib uns Gutes im Diesseits und Gutes im Jenseits und bewahre uns vor der Strafe des Feuers.",
                "fr": "Seigneur, accorde-nous une belle part ici-bas et une belle part dans l’au-delà, et protège-nous du châtiment du Feu.",
                "ru": "Господь наш, даруй нам добро в этом мире и добро в мире вечном и защити нас от наказания Огнём.",
                "ar": "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ"
             ],
             reflection: [
                "en": "Ask for both lives, not only the next hour.",
                "nl": "Vraag voor beide levens, niet alleen voor het komende uur.",
                "es": "Pide por las dos vidas, no solo por la próxima hora.",
                "de": "Bitte für beide Leben, nicht nur für die nächste Stunde.",
                "fr": "Demande pour les deux vies, pas seulement pour l’heure qui vient.",
                "ru": "Проси для обеих жизней, не только для следующего часа.",
                "ar": "اسأل للحياتين، لا للساعة القادمة فقط."
             ]),
        Seed(id: "d-20-114", kind: "dua", arabic: "رَّبِّ زِدْنِي عِلْمًا", ref: "20:114",
             text: [
                "en": "My Lord, increase me in knowledge.",
                "nl": "Mijn Heer, vermeerder mijn kennis.",
                "es": "Señor mío, auméntame en conocimiento.",
                "de": "Mein Herr, mehre mein Wissen.",
                "fr": "Seigneur, accroît mes connaissances.",
                "ru": "Господь мой, приумножь моё знание.",
                "ar": "رَّبِّ زِدْنِي عِلْمًا"
             ],
             reflection: [
                "en": "Learning is a du'a you can make before you open anything else.",
                "nl": "Leren is een du'a die je kunt doen voordat je iets anders opent.",
                "es": "Aprender es una du'a que puedes hacer antes de abrir nada más.",
                "de": "Lernen ist ein Du'a, das du sprechen kannst, bevor du etwas anderes öffnest.",
                "fr": "Apprendre est une du'a que tu peux faire avant d’ouvrir quoi que ce soit d’autre.",
                "ru": "Учёба — это дуа, которую можно произнести до того, как открыть что-то ещё.",
                "ar": "العلم دعاء يمكنك قوله قبل أن تفتح أي شيء آخر."
             ]),
        Seed(id: "d-9-129", kind: "dua", arabic: "حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ", ref: "9:129",
             text: [
                "en": "Allah is sufficient for me. There is no god but Him. In Him I put my trust.",
                "nl": "Allah is mij genoeg. Er is geen god dan Hij. Op Hem vertrouw ik.",
                "es": "Allah me basta. No hay más dios que Él. En Él deposito mi confianza.",
                "de": "Allah genügt mir. Es gibt keinen Gott außer Ihm. Auf Ihn vertraue ich.",
                "fr": "Allah me suffit. Il n’y a de dieu que Lui. C’est en Lui que je place ma confiance.",
                "ru": "Довольно мне Аллаха. Нет бога, кроме Него. На Него я уповаю.",
                "ar": "حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ"
             ],
             reflection: [
                "en": "You do not have to carry the next choice alone.",
                "nl": "Je hoeft de volgende keuze niet alleen te dragen.",
                "es": "No tienes que cargar solo con la próxima elección.",
                "de": "Du musst die nächste Entscheidung nicht allein tragen.",
                "fr": "Tu n’as pas à porter seul le prochain choix.",
                "ru": "Тебе не нужно нести следующий выбор одному.",
                "ar": "لست مضطرًا لحمل الاختيار التالي وحدك."
             ]),
        Seed(id: "h-strong", kind: "hadith", arabic: "الْمُؤْمِنُ الْقَوِيُّ خَيْرٌ وَأَحَبُّ إِلَى اللَّهِ مِنَ الْمُؤْمِنِ الضَّعِيفِ", ref: "Sahih Muslim 2664",
             text: [
                "en": "The strong believer is better and more beloved to Allah than the weak believer, while there is good in both.",
                "nl": "De sterke gelovige is beter en geliefder bij Allah dan de zwakke gelovige, en in beiden zit goed.",
                "es": "El creyente fuerte es mejor y más amado por Allah que el creyente débil, y hay bien en ambos.",
                "de": "Der starke Gläubige ist besser und Allah lieber als der schwache Gläubige, und in beiden liegt Gutes.",
                "fr": "Le croyant fort est meilleur et plus aimé d’Allah que le croyant faible, et il y a du bien en tous deux.",
                "ru": "Сильный верующий лучше и любимее Аллаху, чем слабый, и в обоих есть благо.",
                "ar": "الْمُؤْمِنُ الْقَوِيُّ خَيْرٌ وَأَحَبُّ إِلَى اللَّهِ مِنَ الْمُؤْمِنِ الضَّعِيفِ وَفِي كُلٍّ خَيْرٌ"
             ],
             reflection: [
                "en": "Strength here is the next good choice, not a louder voice.",
                "nl": "Sterkte hier is de volgende goede keuze, geen hardere stem.",
                "es": "La fuerza aquí es la próxima buena elección, no una voz más alta.",
                "de": "Stärke heißt hier die nächste gute Entscheidung, keine lautere Stimme.",
                "fr": "La force ici, c’est le prochain bon choix, pas une voix plus forte.",
                "ru": "Сила здесь — следующий верный выбор, а не более громкий голос.",
                "ar": "القوة هنا هي الاختيار الصالح التالي، لا صوتًا أعلى."
             ]),
        Seed(id: "h-brothers", kind: "hadith", arabic: "لَا تَحَاسَدُوا وَلَا تَبَاغَضُوا وَلَا تَدَابَرُوا وَكُونُوا عِبَادَ اللَّهِ إِخْوَانًا", ref: "Sahih al-Bukhari 6065 · Sahih Muslim 2559",
             text: [
                "en": "Do not hate one another, do not envy one another, do not turn your backs on one another. Be, O servants of Allah, brothers.",
                "nl": "Haat elkaar niet, benijd elkaar niet, keer elkaar niet de rug toe. Wees, dienaren van Allah, broeders.",
                "es": "No os odiéis, no os envidiéis, no os deis la espalda. Sed, siervos de Allah, hermanos.",
                "de": "Hasst einander nicht, beneidet einander nicht, kehrt einander nicht den Rücken. Seid, ihr Diener Allahs, Brüder.",
                "fr": "Ne vous haïssez pas, ne vous enviez pas, ne vous tournez pas le dos. Soyez, serviteurs d’Allah, des frères.",
                "ru": "Не ненавидьте друг друга, не завидуйте, не отворачивайтесь. Будьте, о рабы Аллаха, братьями.",
                "ar": "لَا تَحَاسَدُوا وَلَا تَبَاغَضُوا وَلَا تَدَابَرُوا وَكُونُوا عِبَادَ اللَّهِ إِخْوَانًا"
             ],
             reflection: [
                "en": "The scroll can wait. The person in front of you cannot.",
                "nl": "De feed kan wachten. De mens voor je niet.",
                "es": "El feed puede esperar. La persona delante de ti, no.",
                "de": "Der Feed kann warten. Der Mensch vor dir nicht.",
                "fr": "Le fil peut attendre. La personne devant toi, non.",
                "ru": "Лента может подождать. Человек перед тобой — нет.",
                "ar": "الخلاصة يمكن أن تنتظر. والإنسان أمامك لا."
             ]),
        Seed(id: "q-2-153", kind: "quran", arabic: "يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ", ref: "2:153",
             text: [
                "en": "O you who believe, seek help through patience and prayer. Indeed, Allah is with the patient.",
                "nl": "O jullie die geloven, zoek hulp in geduld en gebed. Voorwaar, Allah is met de geduldigen.",
                "es": "¡Creyentes! Buscad ayuda en la paciencia y en la oración. En verdad, Allah está con los pacientes.",
                "de": "O die ihr glaubt, sucht Hilfe in Geduld und Gebet. Wahrlich, Allah ist mit den Geduldigen.",
                "fr": "Ô vous qui croyez, cherchez secours dans la patience et la prière. Allah est certes avec les patients.",
                "ru": "О те, которые уверовали! Ищите помощи в терпении и молитве. Воистину, Аллах — с терпеливыми.",
                "ar": "يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ"
             ],
             reflection: [
                "en": "Patience and prayer are the first help, not the last.",
                "nl": "Geduld en gebed zijn de eerste hulp, niet de laatste.",
                "es": "La paciencia y la oración son la primera ayuda, no la última.",
                "de": "Geduld und Gebet sind die erste Hilfe, nicht die letzte.",
                "fr": "La patience et la prière sont le premier secours, pas le dernier.",
                "ru": "Терпение и молитва — первая помощь, а не последняя.",
                "ar": "الصبر والصلاة عون أول، لا آخر."
             ]),
        Seed(id: "q-3-139", kind: "quran", arabic: "وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ إِن كُنتُم مُّؤْمِنِينَ", ref: "3:139",
             text: [
                "en": "Do not weaken and do not grieve. You will be superior if you are believers.",
                "nl": "Verslap niet en treur niet. Jullie hebben de overhand als jullie gelovigen zijn.",
                "es": "No flaqueéis ni os entristezcáis. Seréis superiores si sois creyentes.",
                "de": "Werdet nicht schwach und trauert nicht. Ihr habt die Oberhand, wenn ihr Gläubige seid.",
                "fr": "Ne faiblissez pas et ne vous affligez pas. Vous aurez le dessus si vous êtes croyants.",
                "ru": "Не слабейте и не печальтесь. Вы будете выше, если вы верующие.",
                "ar": "وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ إِن كُنتُم مُّؤْمِنِينَ"
             ],
             reflection: [
                "en": "Grief is real. Giving up is a choice.",
                "nl": "Verdriet is echt. Opgeven is een keuze.",
                "es": "El dolor es real. Rendirse es una elección.",
                "de": "Trauer ist echt. Aufgeben ist eine Entscheidung.",
                "fr": "La peine est réelle. Abandonner est un choix.",
                "ru": "Печаль настоящая. Сдаться — это выбор.",
                "ar": "الحزن حق. والاستسلام اختيار."
             ]),
        Seed(id: "q-13-11", kind: "quran", arabic: "إِنَّ اللَّهَ لَا يُغَيِّرُ مَا بِقَوْمٍ حَتَّىٰ يُغَيِّرُوا مَا بِأَنفُسِهِمْ", ref: "13:11",
             text: [
                "en": "Allah does not change the condition of a people until they change what is in themselves.",
                "nl": "Allah verandert de toestand van een volk niet totdat zij veranderen wat in henzelf is.",
                "es": "Allah no cambia la condición de un pueblo hasta que ellos cambian lo que hay en sí mismos.",
                "de": "Allah ändert den Zustand eines Volkes nicht, bis sie ändern, was in ihnen selbst ist.",
                "fr": "Allah ne change pas l’état d’un peuple tant qu’il ne change pas ce qui est en lui-même.",
                "ru": "Аллах не меняет положения людей, пока они не изменят самих себя.",
                "ar": "إِنَّ اللَّهَ لَا يُغَيِّرُ مَا بِقَوْمٍ حَتَّىٰ يُغَيِّرُوا مَا بِأَنفُسِهِمْ"
             ],
             reflection: [
                "en": "The next change starts in you, before it shows up outside.",
                "nl": "De volgende verandering begint in jou, voordat ze buiten zichtbaar wordt.",
                "es": "El próximo cambio empieza en ti, antes de verse fuera.",
                "de": "Die nächste Veränderung beginnt in dir, bevor sie draußen sichtbar wird.",
                "fr": "Le prochain changement commence en toi, avant de se voir dehors.",
                "ru": "Следующая перемена начинается в тебе, прежде чем станет видна снаружи.",
                "ar": "التغيير التالي يبدأ فيك قبل أن يظهر خارجك."
             ]),
        Seed(id: "q-65-3", kind: "quran", arabic: "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ", ref: "65:3",
             text: [
                "en": "And whoever relies upon Allah — then He is sufficient for him.",
                "nl": "En wie op Allah vertrouwt, voor hem is Hij voldoende.",
                "es": "Y quien confía en Allah, Él le basta.",
                "de": "Und wer auf Allah vertraut, dem genügt Er.",
                "fr": "Et quiconque place sa confiance en Allah, Il lui suffit.",
                "ru": "А кто уповает на Аллаха, тому Его довольно.",
                "ar": "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ"
             ],
             reflection: [
                "en": "Trust is handing the outcome over, then still doing your part.",
                "nl": "Vertrouwen is de uitkomst overgeven en toch je deel doen.",
                "es": "Confiar es entregar el resultado y aun así hacer tu parte.",
                "de": "Vertrauen heißt, das Ergebnis abzugeben und trotzdem deinen Teil zu tun.",
                "fr": "Faire confiance, c’est remettre l’issue, tout en faisant ta part.",
                "ru": "Упование — отдать исход и всё же сделать свою часть.",
                "ar": "التوكل أن تسلم النتيجة ثم تقوم بنصيبك."
             ]),
        Seed(id: "q-94-5", kind: "quran", arabic: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا", ref: "94:5",
             text: [
                "en": "For indeed, with hardship comes ease.",
                "nl": "Want voorwaar, bij de zwaarte komt verlichting.",
                "es": "Porque, en verdad, con la dificultad viene la facilidad.",
                "de": "Denn wahrlich, mit der Schwierigkeit kommt Erleichterung.",
                "fr": "Car certes, avec la difficulté vient la facilité.",
                "ru": "Ведь, воистину, за трудностью приходит облегчение.",
                "ar": "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا"
             ],
             reflection: [
                "en": "Ease is promised with the hardship, not after you have given up.",
                "nl": "Verlichting is beloofd bij de zwaarte, niet pas nadat je hebt opgegeven.",
                "es": "La facilidad está prometida con la dificultad, no después de rendirte.",
                "de": "Erleichterung ist mit der Schwierigkeit versprochen, nicht erst nachdem du aufgibst.",
                "fr": "La facilité est promise avec la difficulté, pas après que tu aies abandonné.",
                "ru": "Облегчение обещано вместе с трудностью, а не после того как ты сдался.",
                "ar": "اليسر موعود مع العسر، لا بعد أن تستسلم."
             ]),
        Seed(id: "q-49-10", kind: "quran", arabic: "إِنَّمَا الْمُؤْمِنُونَ إِخْوَةٌ", ref: "49:10",
             text: [
                "en": "The believers are but brothers.",
                "nl": "De gelovigen zijn slechts broeders.",
                "es": "Los creyentes no son sino hermanos.",
                "de": "Die Gläubigen sind ja Brüder.",
                "fr": "Les croyants ne sont que des frères.",
                "ru": "Верующие — братья друг другу.",
                "ar": "إِنَّمَا الْمُؤْمِنُونَ إِخْوَةٌ"
             ],
             reflection: [
                "en": "A brother is someone you return to, not someone you scroll past.",
                "nl": "Een broeder is iemand naar wie je terugkeert, niet iemand die je voorbij scrolt.",
                "es": "Un hermano es alguien a quien vuelves, no alguien a quien pasas de largo.",
                "de": "Ein Bruder ist jemand, zu dem du zurückkehrst, nicht jemand, an dem du vorbeiscrollst.",
                "fr": "Un frère est quelqu’un vers qui tu reviens, pas quelqu’un que tu fais défiler.",
                "ru": "Брат — тот, к кому ты возвращаешься, а не тот, кого ты пролистываешь.",
                "ar": "الأخ من تعود إليه، لا من تمرّ عليه."
             ]),
        Seed(id: "q-29-69", kind: "quran", arabic: "وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا", ref: "29:69",
             text: [
                "en": "Those who strive for Us — We will surely guide them to Our ways.",
                "nl": "Zij die zich voor Ons inspannen, hen zullen Wij zeker naar Onze wegen leiden.",
                "es": "A quienes se esfuerzan por Nosotros, les guiaremos ciertamente por Nuestros caminos.",
                "de": "Die sich für Uns bemühen, die werden Wir ganz gewiss Unsere Wege führen.",
                "fr": "Ceux qui luttent pour Notre cause, Nous les guiderons certes vers Nos chemins.",
                "ru": "А тех, кто усердствует ради Нас, Мы непременно поведём Нашими путями.",
                "ar": "وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا"
             ],
             reflection: [
                "en": "Guidance follows the effort. It does not replace it.",
                "nl": "Leiding volgt de inspanning. Ze vervangt haar niet.",
                "es": "La guía sigue al esfuerzo. No lo sustituye.",
                "de": "Führung folgt der Anstrengung. Sie ersetzt sie nicht.",
                "fr": "La guidance suit l’effort. Elle ne le remplace pas.",
                "ru": "Прямой путь следует за усилием. Он его не заменяет.",
                "ar": "الهداية تتبع السعي. لا تغني عنه."
             ]),
        Seed(id: "q-3-173", kind: "quran", arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ", ref: "3:173",
             text: [
                "en": "Allah is sufficient for us, and He is the best Disposer of affairs.",
                "nl": "Allah is ons genoeg, en Hij is de beste Voogd.",
                "es": "Allah nos basta, y Él es el mejor Protector.",
                "de": "Allah genügt uns, und Er ist der beste Sachwalter.",
                "fr": "Allah nous suffit, Il est notre meilleur garant.",
                "ru": "Довольно нам Аллаха, и как прекрасен этот Попечитель.",
                "ar": "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ"
             ],
             reflection: [
                "en": "Say it when the next worry shows up, before you open an app.",
                "nl": "Zeg het als de volgende zorg opkomt, voordat je een app opent.",
                "es": "Dilo cuando aparezca la próxima preocupación, antes de abrir una app.",
                "de": "Sag es, wenn die nächste Sorge kommt, bevor du eine App öffnest.",
                "fr": "Dis-le quand le prochain souci arrive, avant d’ouvrir une app.",
                "ru": "Скажи это, когда придёт следующая тревога, до того как откроешь приложение.",
                "ar": "قلها حين يأتي الهم التالي، قبل أن تفتح تطبيقًا."
             ]),
        Seed(id: "q-16-97", kind: "quran", arabic: "مَنْ عَمِلَ صَالِحًا مِّن ذَكَرٍ أَوْ أُنثَىٰ وَهُوَ مُؤْمِنٌ فَلَنُحْيِيَنَّهُ حَيَاةً طَيِّبَةً", ref: "16:97",
             text: [
                "en": "Whoever does righteousness, whether male or female, while a believer — We will surely give them a good life.",
                "nl": "Wie goed doet, man of vrouw, en gelovig is, hem zullen Wij zeker een goed leven geven.",
                "es": "A quien obre bien, sea hombre o mujer, y sea creyente, le daremos una buena vida.",
                "de": "Wer Gutes tut, ob Mann oder Frau, und gläubig ist, dem werden Wir ganz gewiss ein gutes Leben geben.",
                "fr": "Quiconque, homme ou femme, fait le bien tout en étant croyant, Nous lui donnerons certes une bonne vie.",
                "ru": "Мужчине или женщине, которые поступят праведно, будучи верующими, Мы даруем благую жизнь.",
                "ar": "مَنْ عَمِلَ صَالِحًا مِّن ذَكَرٍ أَوْ أُنثَىٰ وَهُوَ مُؤْمِنٌ فَلَنُحْيِيَنَّهُ حَيَاةً طَيِّبَةً"
             ],
             reflection: [
                "en": "A good life is built from the next right deed, not the next scroll.",
                "nl": "Een goed leven wordt gebouwd uit de volgende goede daad, niet de volgende scroll.",
                "es": "Una buena vida se construye con la próxima buena obra, no con el próximo scroll.",
                "de": "Ein gutes Leben entsteht aus der nächsten guten Tat, nicht aus dem nächsten Scrollen.",
                "fr": "Une bonne vie se construit par la prochaine bonne action, pas par le prochain défilement.",
                "ru": "Благая жизнь строится из следующего доброго дела, а не из следующей ленты.",
                "ar": "الحياة الطيبة تُبنى من العمل الصالح التالي، لا من التمرير التالي."
             ]),
        Seed(id: "d-71-28", kind: "dua", arabic: "رَّبِّ اغْفِرْ لِي وَلِوَالِدَيَّ", ref: "71:28",
             text: [
                "en": "My Lord, forgive me and my parents.",
                "nl": "Mijn Heer, vergeef mij en mijn ouders.",
                "es": "Señor mío, perdóname a mí y a mis padres.",
                "de": "Mein Herr, vergib mir und meinen Eltern.",
                "fr": "Seigneur, pardonne-moi ainsi qu’à mes parents.",
                "ru": "Господь мой, прости меня и моих родителей.",
                "ar": "رَّبِّ اغْفِرْ لِي وَلِوَالِدَيَّ"
             ],
             reflection: [
                "en": "A short du'a can carry the people who carried you.",
                "nl": "Een korte du'a kan de mensen dragen die jou gedragen hebben.",
                "es": "Una du'a breve puede sostener a quienes te sostuvieron.",
                "de": "Ein kurzes Du'a kann die Menschen tragen, die dich getragen haben.",
                "fr": "Une courte du'a peut porter ceux qui t’ont porté.",
                "ru": "Короткая дуа может нести тех, кто нёс тебя.",
                "ar": "دعاء قصير يحمل من حملك."
             ]),
        Seed(id: "d-2-286b", kind: "dua", arabic: "رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا", ref: "2:286",
             text: [
                "en": "Our Lord, do not take us to task if we forget or make a mistake.",
                "nl": "Onze Heer, bestraf ons niet als wij vergeten of een fout maken.",
                "es": "Señor nuestro, no nos pidas cuentas si olvidamos o nos equivocamos.",
                "de": "Unser Herr, belange uns nicht, wenn wir vergessen oder einen Fehler machen.",
                "fr": "Seigneur, ne nous tiens pas rigueur si nous oublions ou commettons une erreur.",
                "ru": "Господь наш, не наказывай нас, если мы забыли или ошиблись.",
                "ar": "رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا"
             ],
             reflection: [
                "en": "Forgetting is human. Returning is the worship.",
                "nl": "Vergeten is menselijk. Terugkeren is de aanbidding.",
                "es": "Olvidar es humano. Volver es la adoración.",
                "de": "Vergessen ist menschlich. Zurückkehren ist die Anbetung.",
                "fr": "Oublier est humain. Revenir est l’adoration.",
                "ru": "Забыть — по-человечески. Вернуться — это поклонение.",
                "ar": "النسيان بشري. والرجوع عبادة."
             ]),
        Seed(id: "d-20-25", kind: "dua", arabic: "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي", ref: "20:25",
             text: [
                "en": "My Lord, expand my chest for me and ease my task for me.",
                "nl": "Mijn Heer, verruim mijn borst voor mij en maak mijn zaak voor mij gemakkelijk.",
                "es": "Señor mío, ábreme el pecho y facilítame mi asunto.",
                "de": "Mein Herr, weite mir meine Brust und erleichtere mir meine Angelegenheit.",
                "fr": "Seigneur, ouvre-moi la poitrine et facilite-moi ma tâche.",
                "ru": "Господь мой, раскрой мне грудь и облегчи мне моё дело.",
                "ar": "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي"
             ],
             reflection: [
                "en": "Ask for ease before you ask for speed.",
                "nl": "Vraag om gemak voordat je om snelheid vraagt.",
                "es": "Pide facilidad antes de pedir rapidez.",
                "de": "Bitte um Leichtigkeit, bevor du um Tempo bittest.",
                "fr": "Demande la facilité avant de demander la vitesse.",
                "ru": "Проси лёгкости раньше, чем скорости.",
                "ar": "اسأل اليسر قبل أن تسأل السرعة."
             ]),
        Seed(id: "d-3-8", kind: "dua", arabic: "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا", ref: "3:8",
             text: [
                "en": "Our Lord, do not let our hearts deviate after You have guided us.",
                "nl": "Onze Heer, laat onze harten niet afwijken nadat U ons geleid hebt.",
                "es": "Señor nuestro, no desvíes nuestros corazones después de habernos guiado.",
                "de": "Unser Herr, lass unsere Herzen nicht abirren, nachdem Du uns rechtgeleitet hast.",
                "fr": "Seigneur, ne fais pas dévier nos cœurs après nous avoir guidés.",
                "ru": "Господь наш, не уклоняй наши сердца после того, как Ты наставил нас.",
                "ar": "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا"
             ],
             reflection: [
                "en": "A guided heart still needs to be asked for every day.",
                "nl": "Een geleid hart moet nog elke dag gevraagd worden.",
                "es": "Un corazón guiado sigue necesitando pedirse cada día.",
                "de": "Ein geleitetes Herz muss trotzdem jeden Tag erbeten werden.",
                "fr": "Un cœur guidé a encore besoin d’être demandé chaque jour.",
                "ru": "Наставленное сердце всё равно нужно просить каждый день.",
                "ar": "القلب المهدي ما زال يحتاج أن يُطلب كل يوم."
             ]),
        Seed(id: "d-dhikr", kind: "dua", arabic: "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ", ref: "Sunan Abu Dawud 1522",
             text: [
                "en": "O Allah, help me to remember You, to thank You, and to worship You well.",
                "nl": "O Allah, help mij U te gedenken, U te danken en U goed te aanbidden.",
                "es": "Oh Allah, ayúdame a recordarte, a agradecerte y a adorarte bien.",
                "de": "O Allah, hilf mir, Dich zu gedenken, Dir zu danken und Dich gut anzubeten.",
                "fr": "Ô Allah, aide-moi à me souvenir de Toi, à Te remercier et à T’adorer comme il se doit.",
                "ru": "О Аллах, помоги мне поминать Тебя, благодарить Тебя и хорошо поклоняться Тебе.",
                "ar": "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ"
             ],
             reflection: [
                "en": "This is a du'a for the ordinary hour, not only the hard one.",
                "nl": "Dit is een du'a voor het gewone uur, niet alleen het zware.",
                "es": "Esta es una du'a para la hora ordinaria, no solo para la difícil.",
                "de": "Das ist ein Du'a für die gewöhnliche Stunde, nicht nur für die schwere.",
                "fr": "C’est une du'a pour l’heure ordinaire, pas seulement pour l’heure dure.",
                "ru": "Это дуа для обычного часа, а не только для тяжёлого.",
                "ar": "هذا دعاء للساعة العادية، لا للصعبة فقط."
             ]),
        Seed(id: "h-intent", kind: "hadith", arabic: "إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ", ref: "Sahih al-Bukhari 1 · Sahih Muslim 1907",
             text: [
                "en": "Actions are only by intentions, and every person will have only what they intended.",
                "nl": "Daden zijn slechts naar de intenties, en ieder mens krijgt alleen wat hij heeft bedoeld.",
                "es": "Las obras son según las intenciones, y cada persona tendrá solo lo que pretendió.",
                "de": "Die Taten gelten nur nach den Absichten, und jeder Mensch erhält nur, was er beabsichtigt hat.",
                "fr": "Les actions ne valent que par les intentions, et chacun n’aura que ce qu’il a eu l’intention de faire.",
                "ru": "Дела оцениваются только по намерениям, и каждому человеку достанется лишь то, что он намеревался.",
                "ar": "إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى"
             ],
             reflection: [
                "en": "Before this unlock — what did you intend?",
                "nl": "Voor dit ontgrendelen — wat was je intentie?",
                "es": "Antes de este desbloqueo — ¿qué pretendías?",
                "de": "Vor diesem Entsperren — was war deine Absicht?",
                "fr": "Avant ce déverrouillage — quelle était ton intention ?",
                "ru": "Перед этой разблокировкой — каково было намерение?",
                "ar": "قبل هذا الفتح — ماذا نويت؟"
             ]),
        Seed(id: "h-quran", kind: "hadith", arabic: "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ", ref: "Sahih al-Bukhari 5027",
             text: [
                "en": "The best of you are those who learn the Qur'an and teach it.",
                "nl": "De besten onder jullie zijn zij die de Koran leren en hem onderwijzen.",
                "es": "Los mejores de vosotros son quienes aprenden el Corán y lo enseñan.",
                "de": "Die Besten unter euch sind die, die den Koran lernen und ihn lehren.",
                "fr": "Les meilleurs d’entre vous sont ceux qui apprennent le Coran et l’enseignent.",
                "ru": "Лучшие из вас — те, кто изучает Коран и обучает ему.",
                "ar": "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ"
             ],
             reflection: [
                "en": "One ayah learned today is already a share of that good.",
                "nl": "Eén aya die je vandaag leert, is al een deel van dat goede.",
                "es": "Un aleya aprendido hoy ya es parte de ese bien.",
                "de": "Ein Ayat, den du heute lernst, ist schon ein Anteil an diesem Guten.",
                "fr": "Un verset appris aujourd’hui est déjà une part de ce bien.",
                "ru": "Один аят, выученный сегодня, уже доля этого блага.",
                "ar": "آية تتعلمها اليوم نصيب من ذلك الخير."
             ]),
        Seed(id: "h-smile", kind: "hadith", arabic: "تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ صَدَقَةٌ", ref: "Jami' at-Tirmidhi 1956",
             text: [
                "en": "Your smile toward your brother is a charity.",
                "nl": "Jouw glimlach naar je broeder is een liefdadigheid.",
                "es": "Tu sonrisa hacia tu hermano es una caridad.",
                "de": "Dein Lächeln gegenüber deinem Bruder ist eine Spende.",
                "fr": "Ton sourire envers ton frère est une aumône.",
                "ru": "Твоя улыбка брату — милостыня.",
                "ar": "تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ صَدَقَةٌ"
             ],
             reflection: [
                "en": "Not every good deed needs a screen.",
                "nl": "Niet elke goede daad heeft een scherm nodig.",
                "es": "No toda buena obra necesita una pantalla.",
                "de": "Nicht jede gute Tat braucht einen Bildschirm.",
                "fr": "Toute bonne action n’a pas besoin d’un écran.",
                "ru": "Не каждое доброе дело нуждается в экране.",
                "ar": "ليس كل عمل صالح يحتاج شاشة."
             ]),
        Seed(id: "h-speech", kind: "hadith", arabic: "مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ", ref: "Sahih al-Bukhari 6018 · Sahih Muslim 47",
             text: [
                "en": "Whoever believes in Allah and the Last Day, let him speak good or remain silent.",
                "nl": "Wie in Allah en de Laatste Dag gelooft, laat hem iets goeds zeggen of zwijgen.",
                "es": "Quien cree en Allah y en el Último Día, que diga el bien o que calle.",
                "de": "Wer an Allah und den Jüngsten Tag glaubt, der sage Gutes oder schweige.",
                "fr": "Quiconque croit en Allah et au Jour dernier, qu’il dise le bien ou qu’il se taise.",
                "ru": "Кто верует в Аллаха и в Последний день, пусть говорит благое или молчит.",
                "ar": "مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ"
             ],
             reflection: [
                "en": "Silence can be the cleaner deed.",
                "nl": "Zwijgen kan de schonere daad zijn.",
                "es": "Callar puede ser la obra más limpia.",
                "de": "Schweigen kann die reinere Tat sein.",
                "fr": "Se taire peut être l’acte le plus propre.",
                "ru": "Молчание может быть более чистым делом.",
                "ar": "الصمت قد يكون العمل الأنقى."
             ]),
        Seed(id: "h-easy", kind: "hadith", arabic: "يَسِّرُوا وَلَا تُعَسِّرُوا وَبَشِّرُوا وَلَا تُنَفِّرُوا", ref: "Sahih al-Bukhari 69 · Sahih Muslim 1734",
             text: [
                "en": "Make things easy and do not make them difficult. Give glad tidings and do not drive people away.",
                "nl": "Maak het gemakkelijk en maak het niet moeilijk. Verkondig verheugende tijdingen en jaag de mensen niet weg.",
                "es": "Facilitad y no dificultéis. Dad buenas nuevas y no ahuyentéis.",
                "de": "Macht es leicht und nicht schwer. Verkündet frohe Botschaft und schreckt die Menschen nicht ab.",
                "fr": "Facilitez et ne rendez pas les choses difficiles. Annoncez la bonne nouvelle et ne faites pas fuir.",
                "ru": "Облегчайте и не усложняйте. Радуйте и не отталкивайте.",
                "ar": "يَسِّرُوا وَلَا تُعَسِّرُوا وَبَشِّرُوا وَلَا تُنَفِّرُوا"
             ],
             reflection: [
                "en": "The path to Allah should feel possible to the person next to you.",
                "nl": "De weg naar Allah moet mogelijk voelen voor de mens naast je.",
                "es": "El camino hacia Allah debe parecer posible a quien está a tu lado.",
                "de": "Der Weg zu Allah soll sich für den Menschen neben dir möglich anfühlen.",
                "fr": "Le chemin vers Allah doit sembler possible à la personne à côté de toi.",
                "ru": "Путь к Аллаху должен казаться возможным человеку рядом с тобой.",
                "ar": "طريق الله ينبغي أن يبدو ممكنًا لمن بجانبك."
             ]),
        Seed(id: "h-anger", kind: "hadith", arabic: "لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ", ref: "Sahih al-Bukhari 6114 · Sahih Muslim 2609",
             text: [
                "en": "The strong man is not the one who wrestles people down. The strong man is the one who controls himself when angry.",
                "nl": "De sterke is niet degene die mensen neerwerpt. De sterke is degene die zichzelf beheerst als hij boos is.",
                "es": "El fuerte no es quien derriba a la gente. El fuerte es quien se controla cuando se enfada.",
                "de": "Der Starke ist nicht, wer Menschen niederwirft. Der Starke ist, wer sich beherrscht, wenn er zornig ist.",
                "fr": "Le fort n’est pas celui qui terrasse les gens. Le fort est celui qui se maîtrise quand il est en colère.",
                "ru": "Силён не тот, кто валит людей. Силён тот, кто владеет собой в гневе.",
                "ar": "لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ"
             ],
             reflection: [
                "en": "The strong one holds the urge — not the reply, not the scroll.",
                "nl": "De sterke houdt de drang vast — niet het antwoord, niet de scroll.",
                "es": "El fuerte sostiene el impulso — no la respuesta, no el scroll.",
                "de": "Der Starke hält den Drang — nicht die Antwort, nicht den Scroll.",
                "fr": "Le fort retient l’envie — pas la réponse, pas le scroll.",
                "ru": "Сильный удерживает порыв — не ответ, не скролл.",
                "ar": "القوي يمسك الرغبة — لا الرد، لا التمرير."
             ])
    ]
}