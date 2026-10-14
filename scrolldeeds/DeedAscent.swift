//
//  DeedAscent.swift
//  scrolldeeds
//
//  Same-session climb: each completed deed raises a level and replaces
//  the unlock timer with that level’s minutes. Resets when apps lock again.
//

import Foundation
import Combine

struct BarakahCard: Identifiable {
    let id: String
    let arabic: String
    let meaningKey: String
}

struct DeedAscentResult {
    let level: Int
    let minutes: Int
    let card: BarakahCard
}

@MainActor
final class DeedAscentManager: ObservableObject {
    static let shared = DeedAscentManager()

    static let maxLevel = 4

    /// Minutes granted when that level is reached. Higher replaces the timer.
    static let minutesByLevel = [1: 15, 2: 25, 3: 40, 4: 60]

    @Published private(set) var currentLevel: Int = 0
    @Published private(set) var openedCardIDs: [String] = []

    private let levelKey = "deed_ascent_level"
    private let cardsKey = "deed_ascent_opened_cards"
    private let defaults = UserDefaults.standard

    private init() {
        currentLevel = min(Self.maxLevel, max(0, defaults.integer(forKey: levelKey)))
        openedCardIDs = defaults.stringArray(forKey: cardsKey) ?? []
    }

    var nextUnlockMinutes: Int {
        let upcoming = currentLevel >= Self.maxLevel ? Self.maxLevel : currentLevel + 1
        return Self.minutesByLevel[upcoming] ?? 15
    }

    var nextLevelNumber: Int {
        currentLevel >= Self.maxLevel ? Self.maxLevel : currentLevel + 1
    }

    /// Card + level for the overlay. Does not persist until `commitReveal`.
    func beginReveal() -> DeedAscentResult {
        let newLevel = min(Self.maxLevel, currentLevel + 1)
        let minutes = Self.minutesByLevel[newLevel] ?? 15
        return DeedAscentResult(level: newLevel, minutes: minutes, card: pickCard())
    }

    /// Persist the climb and the minutes Amin will unlock. Call only when the user confirms.
    func commitReveal(_ result: DeedAscentResult) {
        currentLevel = result.level
        defaults.set(result.level, forKey: levelKey)

        var opened = openedCardIDs
        if opened.count >= Self.catalog.count {
            opened = []
        }
        if !opened.contains(result.card.id) {
            opened.append(result.card.id)
        }
        openedCardIDs = opened
        defaults.set(opened, forKey: cardsKey)
        UserDefaults.standard.set(result.minutes, forKey: UserDataManager.pendingUnlockMinutesKey)
    }

    /// Called when the unlock window ends and apps lock again.
    func resetClimb() {
        currentLevel = 0
        defaults.set(0, forKey: levelKey)
        UserDefaults.standard.removeObject(forKey: UserDataManager.pendingUnlockMinutesKey)
    }

    private func pickCard() -> BarakahCard {
        let unused = Self.catalog.filter { !openedCardIDs.contains($0.id) }
        if let pick = unused.randomElement() { return pick }
        return Self.catalog.randomElement() ?? Self.catalog[0]
    }

    static let catalog: [BarakahCard] = [
        BarakahCard(id: "ease", arabic: "إِنَّ مَعَ الْعُسْرِ يُسْرًا", meaningKey: "barakah.card.ease"),
        BarakahCard(id: "remember", arabic: "فَاذْكُرُونِي أَذْكُرْكُمْ", meaningKey: "barakah.card.remember"),
        BarakahCard(id: "hearts", arabic: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ", meaningKey: "barakah.card.hearts"),
        BarakahCard(id: "trust", arabic: "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ", meaningKey: "barakah.card.trust"),
        BarakahCard(id: "patient", arabic: "إِنَّ اللَّهَ مَعَ الصَّابِرِينَ", meaningKey: "barakah.card.patient"),
        BarakahCard(id: "rahman", arabic: "الرَّحْمَٰنُ", meaningKey: "barakah.card.rahman"),
        BarakahCard(id: "salam", arabic: "السَّلَامُ", meaningKey: "barakah.card.salam"),
        BarakahCard(id: "wadud", arabic: "الْوَدُودُ", meaningKey: "barakah.card.wadud"),
        BarakahCard(id: "latif", arabic: "اللَّطِيفُ", meaningKey: "barakah.card.latif"),
        BarakahCard(id: "fattah", arabic: "الْفَتَّاحُ", meaningKey: "barakah.card.fattah"),
        BarakahCard(id: "smile", arabic: "تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ صَدَقَةٌ", meaningKey: "barakah.card.smile"),
        BarakahCard(id: "purity", arabic: "الطُّهُورُ شَطْرُ الْإِيمَانِ", meaningKey: "barakah.card.purity"),
        BarakahCard(id: "quran", arabic: "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ", meaningKey: "barakah.card.quran"),
        BarakahCard(id: "bismillah", arabic: "بِسْمِ اللَّهِ", meaningKey: "barakah.card.bismillah"),
        BarakahCard(id: "hamd", arabic: "الْحَمْدُ لِلَّهِ", meaningKey: "barakah.card.hamd"),
        BarakahCard(id: "hasbuna", arabic: "حَسْبُنَا اللَّهُ", meaningKey: "barakah.card.hasbuna"),
        BarakahCard(id: "grieve", arabic: "لَا تَحْزَنْ إِنَّ اللَّهَ مَعَنَا", meaningKey: "barakah.card.grieve"),
        BarakahCard(id: "knowledge", arabic: "رَبِّ زِدْنِي عِلْمًا", meaningKey: "barakah.card.knowledge"),
        BarakahCard(id: "forgiving", arabic: "إِنَّ اللَّهَ غَفُورٌ رَّحِيمٌ", meaningKey: "barakah.card.forgiving"),
        BarakahCard(id: "ease2", arabic: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا", meaningKey: "barakah.card.ease2")
    ]
}
