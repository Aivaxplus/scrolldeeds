//
//  WidgetSettingsPages.swift
//  scrolldeeds
//
//  Home Screen widgets, Lock Screen widgets, and Qur'an reminder times.
//

import SwiftUI

enum NafsiWidgetSurface {
    case home, lock
}

struct WidgetSettingsPage: View {
    let surface: NafsiWidgetSurface
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = NafsiWidgetSettings.shared
    @State private var picker: PickerKind?

    enum PickerKind: String, Identifiable {
        case categories, display, refresh, textSize, font
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            SDPageBackground()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        preview
                        Text(title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(subtitle)
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        howToAddCard

                        Text(NSLocalizedString("widget.customize.section", comment: "Customize"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primary)
                            .tracking(0.6)

                        card {
                            toggleRow
                            divider
                            navRow(NSLocalizedString("widget.categories", comment: "Categories"), value: categorySummary) { picker = .categories }
                            divider
                            navRow(NSLocalizedString("widget.display", comment: "Verse display"), value: displayTitle) { picker = .display }
                            divider
                            navRow(NSLocalizedString("widget.refresh", comment: "Refresh"), value: refreshTitle) { picker = .refresh }
                            divider
                            navRow(NSLocalizedString("widget.textsize", comment: "Text size"), value: textSizeTitle) { picker = .textSize }
                            divider
                            navRow(NSLocalizedString("widget.font", comment: "Font"), value: fontTitle) { picker = .font }
                            divider
                            arabicRow
                        }

                        Text(NSLocalizedString("widget.howto.note", comment: ""))
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                }
            }
        }
        .sheet(item: $picker) { kind in
            WidgetOptionSheet(kind: kind, surface: surface)
        }
        .onAppear {
            settings.publish()
        }
    }

    private var header: some View {
        HStack {
            Button {
                HapticManager.shared.soft()
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text(NSLocalizedString("widget.back", comment: "Back"))
                }
                .foregroundColor(AppTheme.primary)
            }
            Spacer()
            Text(surface == .home
                 ? NSLocalizedString("settings.widgets.home", comment: "Home Screen widgets")
                 : NSLocalizedString("settings.widgets.lock", comment: "Lock Screen widgets"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Color.clear.frame(width: 64, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var preview: some View {
        if surface == .home {
            homePreview
        } else {
            lockPreview
        }
    }

    private var homePreview: some View {
        let quote = currentQuote
        return Group {
            if enabled {
                HStack(alignment: .bottom, spacing: 8) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text((settingsLabel(quote?.kind ?? "quran")).uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.13, green: 0.45, blue: 0.32))
                        Text(quote?.text ?? "")
                            .font(.system(size: previewSize, weight: .semibold, design: previewDesign))
                            .foregroundColor(Color(red: 0.11, green: 0.15, blue: 0.13))
                            .fixedSize(horizontal: false, vertical: true)
                        if showArabic, let arabic = quote?.arabic {
                            Text(arabic)
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.primary)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                        if showReflection, let reflection = quote?.reflection {
                            Text(reflection)
                                .font(.system(size: 13, weight: .medium, design: previewDesign))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Text(quote?.reference ?? "")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.36, green: 0.44, blue: 0.39))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(widgetPose(kind: quote?.kind ?? "quran", id: quote?.id ?? "quran"))
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(height: 92)
                }
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    Text(NSLocalizedString("widget.disabled", comment: "Turn on widgets in Nafsi"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.13, green: 0.45, blue: 0.32))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image("NafsiPoseStand")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(height: 72)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
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
                    colors: [AppTheme.primary.opacity(0.16), Color.clear],
                    center: .bottomTrailing,
                    startRadius: 4,
                    endRadius: 160
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
        .animation(.easeInOut(duration: 0.2), value: enabled)
        .animation(.easeInOut(duration: 0.2), value: showArabic)
        .animation(.easeInOut(duration: 0.2), value: showReflection)
        .animation(.easeInOut(duration: 0.2), value: previewSize)
        .animation(.easeInOut(duration: 0.2), value: previewDesign == .serif)
    }

    private var lockPreview: some View {
        let quote = currentQuote
        return VStack(spacing: 8) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            Text(Date.now.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 64, weight: .light, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            HStack(alignment: .bottom, spacing: 8) {
                if enabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quote?.reference ?? "")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                        Text(quote?.text ?? "")
                            .font(.system(size: previewSize, weight: .medium, design: previewDesign))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        if showReflection, let reflection = quote?.reflection {
                            Text(reflection)
                                .font(.system(size: 13))
                                .multilineTextAlignment(.leading)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(widgetPose(kind: quote?.kind ?? "quran", id: quote?.id ?? "quran"))
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(height: 64)
                } else {
                    Text(NSLocalizedString("widget.disabled", comment: "Turn on widgets in Nafsi"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image("NafsiPoseStand")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(height: 56)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: enabled)
        .animation(.easeInOut(duration: 0.2), value: showReflection)
        .animation(.easeInOut(duration: 0.2), value: previewSize)
    }

    private func widgetPose(kind: String, id: String) -> String {
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

    private var currentQuote: NafsiWidgetQuote? {
        let allowed = surface == .home ? settings.homeCategories : settings.lockCategories
        return NafsiQuoteCatalog.quotes(language: LanguageManager.shared.currentLanguage)
            .first { allowed.contains($0.kind) }
    }

    private var enabled: Bool {
        surface == .home ? settings.homeEnabled : settings.lockEnabled
    }

    private var showReflection: Bool {
        surface == .home ? settings.homeShowReflection : settings.lockShowReflection
    }

    private var showArabic: Bool {
        surface == .home ? settings.homeShowArabic : settings.lockShowArabic
    }

    private var previewDesign: Font.Design {
        let font = surface == .home ? settings.homeFont : settings.lockFont
        return font == "serif" ? .serif : .rounded
    }

    private var previewSize: CGFloat {
        let size = surface == .home ? settings.homeTextSize : settings.lockTextSize
        switch size {
        case "small": return 15
        case "large": return 22
        default: return 18
        }
    }

    private var title: String {
        NSLocalizedString("widget.page.title", comment: "Quotes, du'a and ayah")
    }

    private var subtitle: String {
        surface == .home
            ? NSLocalizedString("widget.home.body", comment: "")
            : NSLocalizedString("widget.lock.body", comment: "")
    }

    private var howToSteps: [(title: String, body: String)] {
        let prefix = surface == .home ? "widget.howto.home" : "widget.howto.lock"
        return (1...3).map { index in
            (
                NSLocalizedString("\(prefix).step\(index).title", comment: ""),
                NSLocalizedString("\(prefix).step\(index).body", comment: "")
            )
        }
    }

    private var howToAddCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: surface == .home ? "square.grid.2x2.fill" : "lock.rectangle.stack.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppTheme.primary.opacity(0.12)))
                Text(NSLocalizedString("widget.howto.title", comment: "How to add it"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(howToSteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(AppTheme.primary))
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(step.title)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                            Text(step.body)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.primary.opacity(0.18), lineWidth: 1)
        )
    }

    private var categorySummary: String {
        let count = surface == .home ? settings.homeCategories.count : settings.lockCategories.count
        return String(format: NSLocalizedString("widget.categories.count", comment: "%d categories"), count)
    }

    private var displayTitle: String {
        showReflection
            ? NSLocalizedString("widget.display.reflection", comment: "")
            : NSLocalizedString("widget.display.translation", comment: "")
    }

    private var refreshTitle: String {
        let minutes = surface == .home ? settings.homeRefreshMinutes : settings.lockRefreshMinutes
        return String(format: NSLocalizedString("widget.refresh.minutes", comment: "Every %d minutes"), minutes)
    }

    private var textSizeTitle: String {
        let key = surface == .home ? settings.homeTextSize : settings.lockTextSize
        return NSLocalizedString("widget.textsize.\(key)", comment: "")
    }

    private var fontTitle: String {
        let key = surface == .home ? settings.homeFont : settings.lockFont
        return NSLocalizedString("widget.font.\(key)", comment: "")
    }

    private var toggleRow: some View {
        HStack {
            Text(NSLocalizedString("widget.enable", comment: "Enable widgets"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Toggle("", isOn: Binding(
                get: { enabled },
                set: { newValue in
                    HapticManager.shared.selection()
                    if surface == .home { settings.homeEnabled = newValue } else { settings.lockEnabled = newValue }
                    settings.save()
                }
            ))
            .labelsHidden()
            .tint(AppTheme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var arabicRow: some View {
        HStack {
            Text(NSLocalizedString("widget.arabic", comment: "Show Arabic"))
                .font(.system(size: 17))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Toggle("", isOn: Binding(
                get: { showArabic },
                set: { newValue in
                    HapticManager.shared.selection()
                    if surface == .home { settings.homeShowArabic = newValue } else { settings.lockShowArabic = newValue }
                    settings.save()
                }
            ))
            .labelsHidden()
            .tint(AppTheme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func navRow(_ title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.soft()
            action()
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text(value)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textMuted)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Divider().padding(.leading, 16)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func settingsLabel(_ kind: String) -> String {
        switch kind {
        case "dua": return NSLocalizedString("widget.kind.dua", comment: "")
        case "hadith": return NSLocalizedString("widget.kind.hadith", comment: "")
        default: return NSLocalizedString("widget.kind.quran", comment: "")
        }
    }
}

private struct WidgetOptionSheet: View {
    let kind: WidgetSettingsPage.PickerKind
    let surface: NafsiWidgetSurface
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = NafsiWidgetSettings.shared

    var body: some View {
        NavigationView {
            List {
                switch kind {
                case .categories:
                    ForEach(NafsiWidgetSettings.categories, id: \.self) { category in
                        Button {
                            toggle(category)
                        } label: {
                            HStack {
                                Text(label(category))
                                Spacer()
                                if selected.contains(category) {
                                    Image(systemName: "checkmark").foregroundColor(AppTheme.primary)
                                }
                            }
                        }
                    }
                case .display:
                    choice(NSLocalizedString("widget.display.translation", comment: ""), selected: !reflection) {
                        setReflection(false)
                    }
                    choice(NSLocalizedString("widget.display.reflection", comment: ""), selected: reflection) {
                        setReflection(true)
                    }
                case .refresh:
                    ForEach(NafsiWidgetSettings.refreshChoices, id: \.self) { minutes in
                        choice(String(format: NSLocalizedString("widget.refresh.minutes", comment: ""), minutes), selected: refresh == minutes) {
                            setRefresh(minutes)
                        }
                    }
                case .textSize:
                    ForEach(NafsiWidgetSettings.textSizes, id: \.self) { size in
                        choice(NSLocalizedString("widget.textsize.\(size)", comment: ""), selected: textSize == size) {
                            setText(size)
                        }
                    }
                case .font:
                    ForEach(NafsiWidgetSettings.fonts, id: \.self) { font in
                        choice(NSLocalizedString("widget.font.\(font)", comment: ""), selected: fontName == font) {
                            setFont(font)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.ok", comment: "OK")) { dismiss() }
                }
            }
        }
    }

    private var title: String {
        switch kind {
        case .categories: return NSLocalizedString("widget.categories", comment: "")
        case .display: return NSLocalizedString("widget.display", comment: "")
        case .refresh: return NSLocalizedString("widget.refresh", comment: "")
        case .textSize: return NSLocalizedString("widget.textsize", comment: "")
        case .font: return NSLocalizedString("widget.font", comment: "")
        }
    }

    private var selected: Set<String> {
        surface == .home ? settings.homeCategories : settings.lockCategories
    }

    private var reflection: Bool {
        surface == .home ? settings.homeShowReflection : settings.lockShowReflection
    }

    private var refresh: Int {
        surface == .home ? settings.homeRefreshMinutes : settings.lockRefreshMinutes
    }

    private var textSize: String {
        surface == .home ? settings.homeTextSize : settings.lockTextSize
    }

    private var fontName: String {
        surface == .home ? settings.homeFont : settings.lockFont
    }

    private func label(_ kind: String) -> String {
        switch kind {
        case "dua": return NSLocalizedString("widget.kind.dua", comment: "")
        case "hadith": return NSLocalizedString("widget.kind.hadith", comment: "")
        default: return NSLocalizedString("widget.kind.quran", comment: "")
        }
    }

    private func toggle(_ category: String) {
        HapticManager.shared.selection()
        if surface == .home {
            if settings.homeCategories.contains(category), settings.homeCategories.count > 1 {
                settings.homeCategories.remove(category)
            } else {
                settings.homeCategories.insert(category)
            }
        } else if settings.lockCategories.contains(category), settings.lockCategories.count > 1 {
            settings.lockCategories.remove(category)
        } else {
            settings.lockCategories.insert(category)
        }
        settings.save()
    }

    private func setReflection(_ value: Bool) {
        if surface == .home { settings.homeShowReflection = value } else { settings.lockShowReflection = value }
        settings.save()
        dismiss()
    }

    private func setRefresh(_ value: Int) {
        if surface == .home { settings.homeRefreshMinutes = value } else { settings.lockRefreshMinutes = value }
        settings.save()
        dismiss()
    }

    private func setText(_ value: String) {
        if surface == .home { settings.homeTextSize = value } else { settings.lockTextSize = value }
        settings.save()
        dismiss()
    }

    private func setFont(_ value: String) {
        if surface == .home { settings.homeFont = value } else { settings.lockFont = value }
        settings.save()
        dismiss()
    }

    private func choice(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack {
                Text(title).foregroundColor(AppTheme.textPrimary)
                Spacer()
                if selected { Image(systemName: "checkmark").foregroundColor(AppTheme.primary) }
            }
        }
    }
}

struct QuranReminderSettingsPage: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = NafsiWidgetSettings.shared
    @ObservedObject private var notifications = NotificationManager.shared
    @State private var showAddTime = false
    @State private var newTime = Date()
    @State private var customExpanded = false

    var body: some View {
        ZStack {
            SDPageBackground()
            VStack(spacing: 0) {
                HStack {
                    Button {
                        HapticManager.shared.soft()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                            Text(NSLocalizedString("widget.back", comment: "Back"))
                        }
                        .foregroundColor(AppTheme.primary)
                    }
                    Spacer()
                    Text(NSLocalizedString("widget.reminders.title", comment: "Reminders"))
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Color.clear.frame(width: 64, height: 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text(NSLocalizedString("widget.reminders.toggle", comment: "Qur'an reminders"))
                                .font(.system(size: 17, weight: .semibold))
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { settings.quranRemindersEnabled },
                                set: { settings.quranRemindersEnabled = $0; settings.save() }
                            ))
                            .labelsHidden()
                            .tint(AppTheme.primary)
                        }
                        .padding(16)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        Text(summary)
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        sectionLabel(NSLocalizedString("widget.reminders.frequency", comment: "Frequency"))
                        frequencyCard

                        if settings.isCustomReminderCadence && customExpanded {
                            Text(NSLocalizedString("widget.reminders.limit", comment: ""))
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if !settings.isCustomReminderCadence {
                            Text(NSLocalizedString("widget.reminders.interval.hint", comment: ""))
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        sectionLabel(NSLocalizedString("widget.reminders.days", comment: "Days"))
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                ForEach(orderedWeekdays, id: \.self) { day in
                                    let on = settings.reminderWeekdays.contains(day)
                                    Button {
                                        HapticManager.shared.selection()
                                        if on, settings.reminderWeekdays.count > 1 {
                                            settings.reminderWeekdays.remove(day)
                                        } else {
                                            settings.reminderWeekdays.insert(day)
                                        }
                                        settings.save()
                                    } label: {
                                        Text(shortWeekday(day))
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(on ? .white : AppTheme.textPrimary)
                                            .frame(width: 36, height: 36)
                                            .background(Circle().fill(on ? AppTheme.primary : AppTheme.muted))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            Text(daySummary)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        sectionLabel(NSLocalizedString("widget.reminders.says", comment: "What it says"))
                        VStack(spacing: 0) {
                            saysRow(
                                NSLocalizedString("widget.display.translation", comment: ""),
                                NSLocalizedString("widget.display.translation.hint", comment: ""),
                                selected: !settings.reminderShowReflection
                            ) { settings.reminderShowReflection = false; settings.save() }
                            Divider().padding(.leading, 16)
                            saysRow(
                                NSLocalizedString("widget.display.reflection", comment: ""),
                                NSLocalizedString("widget.display.reflection.hint", comment: ""),
                                selected: settings.reminderShowReflection
                            ) { settings.reminderShowReflection = true; settings.save() }
                        }
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        sectionLabel(NSLocalizedString("settings.spiritual_type", comment: "Notification type"))
                        VStack(spacing: 0) {
                            ForEach(SpiritualContentFilter.allCases) { filter in
                                Button {
                                    HapticManager.shared.selection()
                                    notifications.setDailySpiritualFilter(filter)
                                } label: {
                                    HStack {
                                        Text(filter.title).foregroundColor(AppTheme.textPrimary)
                                        Spacer()
                                        if notifications.dailySpiritualFilter == filter {
                                            Image(systemName: "checkmark").foregroundColor(AppTheme.primary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(.plain)
                                if filter != SpiritualContentFilter.allCases.last { Divider().padding(.leading, 16) }
                            }
                        }
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            customExpanded = settings.isCustomReminderCadence
        }
        .sheet(isPresented: $showAddTime) {
            NavigationView {
                DatePicker("", selection: $newTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .navigationTitle(NSLocalizedString("widget.reminders.add", comment: ""))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(NSLocalizedString("widget.back", comment: "Back")) { showAddTime = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(NSLocalizedString("common.ok", comment: "OK")) {
                                let parts = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                                settings.addReminder(hour: parts.hour ?? 9, minute: parts.minute ?? 0)
                                showAddTime = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }

    private var frequencyCard: some View {
        VStack(spacing: 0) {
            ForEach(NafsiWidgetSettings.reminderCadenceChoices, id: \.self) { cadence in
                cadenceRow(
                    title: NSLocalizedString(NafsiWidgetSettings.cadenceTitleKey(cadence), comment: ""),
                    selected: settings.reminderCadenceMinutes == cadence
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) { customExpanded = false }
                    settings.setReminderCadence(cadence)
                }
                Divider().padding(.leading, 16)
            }

            Button {
                HapticManager.shared.selection()
                withAnimation(.easeInOut(duration: 0.25)) {
                    if settings.isCustomReminderCadence {
                        customExpanded.toggle()
                    } else {
                        settings.setReminderCadence(0)
                        customExpanded = true
                    }
                }
            } label: {
                HStack {
                    Text(NSLocalizedString("widget.reminders.custom", comment: "Custom"))
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    if settings.isCustomReminderCadence {
                        Image(systemName: "checkmark")
                            .foregroundColor(AppTheme.primary)
                    }
                    Image(systemName: customExpanded && settings.isCustomReminderCadence ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if settings.isCustomReminderCadence && customExpanded {
                Divider().padding(.leading, 16)
                customTimesList
            }
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var customTimesList: some View {
        VStack(spacing: 0) {
            ForEach(settings.reminderMinutes, id: \.self) { minutes in
                HStack {
                    Text(NSLocalizedString(NafsiWidgetSettings.partOfDayKey(minutes: minutes), comment: ""))
                        .font(.system(size: 17))
                    Spacer()
                    Text(clock(minutes))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(AppTheme.muted))
                    Button {
                        HapticManager.shared.soft()
                        settings.removeReminder(minutes: minutes)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.red.opacity(0.85))
                    }
                    .disabled(settings.reminderMinutes.count <= 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                if minutes != settings.reminderMinutes.last { Divider().padding(.leading, 16) }
            }
            if settings.reminderMinutes.count < NafsiWidgetSettings.maxReminderTimes {
                Divider()
                Button {
                    newTime = Date()
                    showAddTime = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill").foregroundColor(AppTheme.primary)
                        Text(NSLocalizedString("widget.reminders.add", comment: "Add a time"))
                            .foregroundColor(AppTheme.primary)
                        Spacer()
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func cadenceRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark").foregroundColor(AppTheme.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var orderedWeekdays: [Int] {
        [2, 3, 4, 5, 6, 7, 1]
    }

    private var summary: String {
        guard settings.quranRemindersEnabled else {
            return NSLocalizedString("widget.reminders.off", comment: "Reminders are off.")
        }
        let times = settings.effectiveReminderMinutes
        return String(
            format: NSLocalizedString("widget.reminders.summary", comment: "You'll get %d reminders a day. Next one at %@."),
            times.count,
            nextTimeLabel
        )
    }

    private var nextTimeLabel: String {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let days = settings.reminderWeekdays
        let times = settings.effectiveReminderMinutes
        for offset in 0..<8 {
            let day = ((weekday - 1 + offset) % 7) + 1
            guard days.contains(day) else { continue }
            let candidates = times.filter { offset > 0 || $0 > nowMinutes }
            if let next = candidates.min() {
                return clock(next)
            }
        }
        return clock(times.min() ?? 9 * 60)
    }

    private var daySummary: String {
        if settings.reminderWeekdays.count == 7 {
            return NSLocalizedString("widget.reminders.everyday", comment: "Every day")
        }
        return orderedWeekdays.filter { settings.reminderWeekdays.contains($0) }.map(shortWeekday).joined(separator: " ")
    }

    private func shortWeekday(_ day: Int) -> String {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        let index = day - 1
        guard symbols.indices.contains(index) else { return "" }
        return symbols[index]
    }

    private func clock(_ minutes: Int) -> String {
        var parts = DateComponents()
        parts.hour = minutes / 60
        parts.minute = minutes % 60
        let date = Calendar.current.date(from: parts) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(AppTheme.primary)
            .tracking(0.6)
    }

    private func saysRow(_ title: String, _ hint: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                    Text(hint).font(.system(size: 14)).foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(selected ? AppTheme.primary : AppTheme.textMuted)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}
