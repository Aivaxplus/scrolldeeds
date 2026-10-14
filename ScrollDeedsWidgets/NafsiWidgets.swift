//
//  NafsiWidgets.swift
//  ScrollDeedsWidgets
//
//  Home Screen and Lock Screen verses. Content comes from the app group payload
//  that Nafsi writes when settings or language change.
//

import WidgetKit
import SwiftUI

private struct WidgetQuote: Codable, Identifiable {
    var id: String
    var kind: String
    var text: String
    var arabic: String
    var reference: String
    var reflection: String
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

private struct WidgetPayload: Codable {
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
    var quotes: [WidgetQuote]
}

private enum WidgetStore {
    static let appGroup = "group.com.scrolldeeds.app"
    static let fallback = WidgetQuote(
        id: "fallback",
        kind: "quran",
        text: "So remember Me; I will remember you.",
        arabic: "فَاذْكُرُونِي أَذْكُرْكُمْ",
        reference: "Qur'an 2:152",
        reflection: "Before the next scroll — remember Him once.",
        themes: ["dhikr", "presence", "start"]
    )

    static var suite: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    static func load() -> WidgetPayload? {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent("widget-payload.json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetPayload.self, from: data)
    }

    /// App Group flags are written first from the app — prefer them so toggles
    /// apply instantly even if the JSON payload is briefly stale.
    static func enabled(surface: String, payload: WidgetPayload?) -> Bool {
        let key = surface == "lock" ? "nafsi.widget.lockEnabled" : "nafsi.widget.homeEnabled"
        if let suite, suite.object(forKey: key) != nil {
            return suite.bool(forKey: key)
        }
        return surface == "lock" ? (payload?.lockEnabled ?? true) : (payload?.homeEnabled ?? true)
    }

    static func showReflection(surface: String, payload: WidgetPayload?) -> Bool {
        let key = surface == "lock" ? "nafsi.widget.lockReflection" : "nafsi.widget.homeReflection"
        if let suite, suite.object(forKey: key) != nil {
            return suite.bool(forKey: key)
        }
        return surface == "lock" ? (payload?.lockShowReflection ?? false) : (payload?.homeShowReflection ?? false)
    }

    static func showArabic(surface: String, payload: WidgetPayload?) -> Bool {
        let key = surface == "lock" ? "nafsi.widget.lockArabic" : "nafsi.widget.homeArabic"
        if let suite, suite.object(forKey: key) != nil {
            return suite.bool(forKey: key)
        }
        return surface == "lock" ? (payload?.lockShowArabic ?? false) : (payload?.homeShowArabic ?? false)
    }

    static func refreshMinutes(surface: String, payload: WidgetPayload?) -> Int {
        let key = surface == "lock" ? "nafsi.widget.lockRefresh" : "nafsi.widget.homeRefresh"
        if let suite, suite.object(forKey: key) != nil {
            let value = suite.integer(forKey: key)
            return value > 0 ? value : 30
        }
        return surface == "lock" ? (payload?.lockRefreshMinutes ?? 30) : (payload?.homeRefreshMinutes ?? 30)
    }

    static func textSize(surface: String, payload: WidgetPayload?) -> String {
        let key = surface == "lock" ? "nafsi.widget.lockText" : "nafsi.widget.homeText"
        if let suite, let value = suite.string(forKey: key), !value.isEmpty {
            return value
        }
        return surface == "lock" ? (payload?.lockTextSize ?? "standard") : (payload?.homeTextSize ?? "standard")
    }

    static func font(surface: String, payload: WidgetPayload?) -> String {
        let key = surface == "lock" ? "nafsi.widget.lockFont" : "nafsi.widget.homeFont"
        if let suite, let value = suite.string(forKey: key), !value.isEmpty {
            return value
        }
        return surface == "lock" ? (payload?.lockFont ?? "rounded") : (payload?.homeFont ?? "rounded")
    }

    static func categories(surface: String, payload: WidgetPayload?) -> [String] {
        let key = surface == "lock" ? "nafsi.widget.lockCategories" : "nafsi.widget.homeCategories"
        if let suite, let saved = suite.stringArray(forKey: key), !saved.isEmpty {
            return saved
        }
        return surface == "lock"
            ? (payload?.lockCategories ?? ["quran", "dua", "hadith"])
            : (payload?.homeCategories ?? ["quran", "dua", "hadith"])
    }

    static func disabledTitle(payload: WidgetPayload?) -> String {
        if let suite, let title = suite.string(forKey: "nafsi.widget.disabledTitle"), !title.isEmpty {
            return title
        }
        return payload?.disabledTitle ?? "Turn on widgets in Nafsi"
    }
}

private struct VerseEntry: TimelineEntry {
    let date: Date
    let quote: WidgetQuote
    let enabled: Bool
    let showReflection: Bool
    let showArabic: Bool
    let textSize: String
    let font: String
    let disabledTitle: String
    let kindLabel: String
}

private struct VerseProvider: TimelineProvider {
    let surface: String

    func placeholder(in context: Context) -> VerseEntry {
        entry(at: Date(), index: 0, payload: WidgetStore.load())
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(entry(at: Date(), index: 0, payload: WidgetStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let payload = WidgetStore.load()
        let minutes = WidgetStore.refreshMinutes(surface: surface, payload: payload)
        let step = max(15, minutes) * 60
        let pool = Self.pool(surface: surface, payload: payload)
        let count = min(56, max(pool.count, 16))
        let now = Date()
        let entries = (0..<count).map { index in
            entry(at: now.addingTimeInterval(Double(index) * Double(step)), index: index, payload: payload)
        }
        let next = now.addingTimeInterval(Double(count) * Double(step))
        completion(Timeline(entries: entries, policy: .after(next)))
    }

    private func entry(at date: Date, index: Int, payload: WidgetPayload?) -> VerseEntry {
        _ = index
        let enabled = WidgetStore.enabled(surface: surface, payload: payload)
        let quotes = Self.ordered(Self.pool(surface: surface, payload: payload), at: date, surface: surface)
        let step = max(15, WidgetStore.refreshMinutes(surface: surface, payload: payload)) * 60
        let slot = Int(date.timeIntervalSince1970 / Double(step))
        let quote = quotes[abs(slot) % quotes.count]
        return VerseEntry(
            date: date,
            quote: quote,
            enabled: enabled,
            showReflection: WidgetStore.showReflection(surface: surface, payload: payload),
            showArabic: WidgetStore.showArabic(surface: surface, payload: payload),
            textSize: WidgetStore.textSize(surface: surface, payload: payload),
            font: WidgetStore.font(surface: surface, payload: payload),
            disabledTitle: WidgetStore.disabledTitle(payload: payload),
            kindLabel: payload?.kindLabels[quote.kind] ?? quote.kind.uppercased()
        )
    }

    private static func pool(surface: String, payload: WidgetPayload?) -> [WidgetQuote] {
        let categories = WidgetStore.categories(surface: surface, payload: payload)
        let pool = (payload?.quotes ?? [WidgetStore.fallback]).filter { categories.contains($0.kind) }
        return pool.isEmpty ? [WidgetStore.fallback] : pool
    }

    /// Prefer quotes that match this hour’s themes, then rotate daily / per surface.
    private static func ordered(_ quotes: [WidgetQuote], at date: Date, surface: String) -> [WidgetQuote] {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let salt = surface == "lock" ? 17 : 3
        let preferred = momentThemes(at: date)
        return quotes.sorted { lhs, rhs in
            let leftMatch = lhs.themes.filter { preferred.contains($0) }.count
            let rightMatch = rhs.themes.filter { preferred.contains($0) }.count
            if leftMatch != rightMatch { return leftMatch > rightMatch }
            let left = mix(lhs.id, day: day, salt: salt)
            let right = mix(rhs.id, day: day, salt: salt)
            if left == right { return lhs.id < rhs.id }
            return left < right
        }
    }

    private static func momentThemes(at date: Date) -> Set<String> {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return ["gratitude", "intention", "dhikr", "prayer", "start", "presence"]
        case 11..<15: return ["patience", "self_control", "focus", "speech", "strength", "time"]
        case 15..<20: return ["akhirah", "return", "mercy", "presence", "time", "focus"]
        default: return ["mercy", "tawbah", "trust", "rest", "nearness", "return"]
        }
    }

    private static func mix(_ id: String, day: Int, salt: Int) -> Int {
        var hash = day &* 31 &+ salt
        for scalar in id.unicodeScalars {
            hash = hash &* 33 &+ Int(scalar.value)
        }
        return hash
    }
}

private enum WidgetInk {
    static let green = Color(red: 0.13, green: 0.45, blue: 0.32)
    static let ink = Color(red: 0.11, green: 0.15, blue: 0.13)
    static let muted = Color(red: 0.36, green: 0.44, blue: 0.39)
}

private enum WidgetPose {
    /// Qur'an reads, du'a offers, sunnah stands or rises. Stable per quote.
    static func name(kind: String, id: String) -> String {
        let pool: [String]
        switch kind {
        case "dua":
            pool = ["NafsiPoseOffer", "NafsiPoseSit"]
        case "hadith":
            pool = ["NafsiPoseRise", "NafsiPoseReach", "NafsiPoseStand"]
        default:
            pool = ["NafsiPoseRead", "NafsiPoseWatch", "NafsiPoseCrouch"]
        }
        let hash = id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return pool[abs(hash) % pool.count]
    }
}

private struct NafsiWidgetFigure: View {
    var pose: String
    var height: CGFloat

    var body: some View {
        Image(pose)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(height: height)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .accessibilityHidden(true)
    }
}

private struct HomeVerseView: View {
    let entry: VerseEntry
    @Environment(\.widgetFamily) private var family

    private var compact: Bool { family == .systemSmall }
    private var pose: String { WidgetPose.name(kind: entry.quote.kind, id: entry.quote.id) }
    private var figureHeight: CGFloat { compact ? 52 : 72 }

    var body: some View {
        if entry.enabled {
            verseRow
        } else {
            HStack(alignment: .bottom, spacing: 6) {
                Text(entry.disabledTitle)
                    .font(.system(size: compact ? 12 : 13.5, weight: .semibold, design: .rounded))
                    .foregroundColor(WidgetInk.green)
                    .multilineTextAlignment(.leading)
                    .lineLimit(compact ? 7 : 9)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                NafsiWidgetFigure(pose: "NafsiPoseSit", height: compact ? 52 : 68)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var verseRow: some View {
        HStack(alignment: .bottom, spacing: compact ? 2 : 4) {
            VStack(alignment: .leading, spacing: compact ? 5 : 6) {
                kindLabel
                Text(entry.quote.text)
                    .font(verseFont)
                    .foregroundColor(WidgetInk.ink)
                    .lineLimit(24)
                    .minimumScaleFactor(0.22)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                if !compact && entry.showArabic {
                    Text(entry.quote.arabic)
                        .font(.system(size: 14))
                        .foregroundColor(WidgetInk.green)
                        .lineLimit(4)
                        .minimumScaleFactor(0.4)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                if !compact && entry.showReflection {
                    Text(entry.quote.reflection)
                        .font(.system(size: 12, weight: .medium, design: fontDesign))
                        .foregroundColor(WidgetInk.muted)
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                }
                Text(entry.quote.reference)
                    .font(.system(size: compact ? 11 : 12, weight: .medium, design: .rounded))
                    .foregroundColor(WidgetInk.muted)
                    .lineLimit(3)
                    .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            NafsiWidgetFigure(pose: pose, height: figureHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var kindLabel: some View {
        Text(entry.kindLabel.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(WidgetInk.green)
            .lineLimit(1)
    }

    private var fontDesign: Font.Design { entry.font == "serif" ? .serif : .rounded }

    private var verseFont: Font {
        let size: CGFloat = {
            switch entry.textSize {
            case "small": return family == .systemSmall ? 14 : 16
            case "large": return family == .systemSmall ? 18 : 22
            default: return family == .systemSmall ? 16 : 19
            }
        }()
        return .system(size: size, weight: .semibold, design: fontDesign)
    }
}

private struct LockVerseView: View {
    let entry: VerseEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(entry.enabled ? entry.quote.text : shortDisabledTitle(entry.disabledTitle))
                .lineLimit(1)
                .minimumScaleFactor(0.45)
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                if entry.enabled {
                    VStack(spacing: 1) {
                        Text(entry.kindLabel.uppercased())
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                        Text(entry.quote.text)
                            .font(.system(size: circularSize, weight: .semibold, design: entry.font == "serif" ? .serif : .rounded))
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .minimumScaleFactor(0.32)
                            .allowsTightening(true)
                    }
                    .padding(5)
                } else {
                    Text(shortDisabledTitle(entry.disabledTitle))
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .minimumScaleFactor(0.45)
                        .padding(4)
                }
            }
        default:
            HStack(alignment: .bottom, spacing: 4) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.enabled ? entry.quote.reference : "Nafsi")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(entry.enabled ? entry.quote.text : entry.disabledTitle)
                        .font(.system(size: entry.enabled ? lockSize : max(11, lockSize - 2), weight: .semibold, design: entry.font == "serif" ? .serif : .rounded))
                        .lineLimit(entry.enabled ? 6 : 8)
                        .minimumScaleFactor(0.5)
                        .allowsTightening(true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    if entry.enabled && entry.showReflection {
                        Text(entry.quote.reflection)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                NafsiWidgetFigure(
                    pose: entry.enabled ? WidgetPose.name(kind: entry.quote.kind, id: entry.quote.id) : "NafsiPoseSit",
                    height: 22
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    /// Tiny Lock Screen families can't fit the full pride message.
    private func shortDisabledTitle(_ full: String) -> String {
        let first = full.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? full
        return first.isEmpty ? full : first
    }

    private var lockSize: CGFloat {
        switch entry.textSize {
        case "small": return 13
        case "large": return 16
        default: return 14
        }
    }

    private var circularSize: CGFloat {
        switch entry.textSize {
        case "small": return 9
        case "large": return 11
        default: return 10
        }
    }
}

struct NafsiHomeWidget: Widget {
    let kind = "NafsiHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VerseProvider(surface: "home")) { entry in
            HomeVerseView(entry: entry)
                .nafsiWidgetBackground(home: true)
        }
        .configurationDisplayName(NSLocalizedString("widget.gallery.home", comment: "Nafsi"))
        .description(NSLocalizedString("widget.gallery.home.desc", comment: "Verses on your Home Screen"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NafsiLockWidget: Widget {
    let kind = "NafsiLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VerseProvider(surface: "lock")) { entry in
            LockVerseView(entry: entry)
                .nafsiWidgetBackground(home: false)
        }
        .configurationDisplayName(NSLocalizedString("widget.gallery.lock", comment: "Nafsi"))
        .description(NSLocalizedString("widget.gallery.lock.desc", comment: "A verse on your Lock Screen"))
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

private extension View {
    @ViewBuilder
    func nafsiWidgetBackground(home: Bool) -> some View {
        if #available(iOS 17.0, *) {
            if home {
                containerBackground(for: .widget) {
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.97, blue: 0.94),
                                Color(red: 0.99, green: 0.98, blue: 0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        RadialGradient(
                            colors: [
                                Color(red: 0.18, green: 0.62, blue: 0.42).opacity(0.22),
                                Color.clear
                            ],
                            center: .bottomTrailing,
                            startRadius: 4,
                            endRadius: 150
                        )
                    }
                }
            } else {
                containerBackground(for: .widget) { Color.clear }
            }
        } else if home {
            background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.97, blue: 0.94),
                            Color(red: 0.99, green: 0.98, blue: 0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [
                            Color(red: 0.18, green: 0.62, blue: 0.42).opacity(0.22),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 4,
                        endRadius: 150
                    )
                }
            )
        } else {
            self
        }
    }
}

@main
struct NafsiWidgetBundle: WidgetBundle {
    var body: some Widget {
        NafsiHomeWidget()
        NafsiLockWidget()
    }
}
