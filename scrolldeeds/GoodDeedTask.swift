//
//  GoodDeedTask.swift
//  scrolldeeds
//

import SwiftUI

// MARK: - Unlock reward (fixed for all tasks)

enum TaskDifficulty {
    case standard

    var unlockMinutes: Int {
        UserDataManager.shared.effectiveUnlockMinutesAfterDeed()
    }
    
    var displayDuration: String {
        let m = unlockMinutes
        switch m {
        case 60:
            return NSLocalizedString("task.duration.1hour", comment: "1 hour")
        case 30:
            return NSLocalizedString("task.duration.30min", comment: "30 minutes")
        default:
            return String(format: NSLocalizedString("task.duration.minutes_format", comment: "%d min"), m)
        }
    }
    var iconName: String { "clock.fill" }
    var accentColor: Color { AppTheme.primary }
}

/// “+30 coins” with the gold coin, used wherever a deed used to show minutes.
struct DeedCoinBadge: View {
    let coins: Int
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 6) {
            NafsiCoinGlyph(size: size + 6)
            Text(String(format: NSLocalizedString("deed.coin_reward", comment: "+%d coins"), coins))
                .font(.system(size: size, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Task Style

enum GoodDeedTaskStyle {
    case dhikr(DhikrType)   // reuses existing dhikr screen (Arabic text + tap 3×)
    case deed               // new task card + "I completed it"
}

// MARK: - Dua Content (full Arabic + translation key)

enum DuaContent {
    static func arabic(key: String) -> String? {
        switch key {
        case "ayat_al_kursi":    return DuaContent.ayatAlKursi
        case "istighfar":        return DuaContent.sayyidIstighfar
        case "dua_parents":      return DuaContent.duaParents
        case "dua_ummah":        return DuaContent.duaUmmah
        case "dua_loved_one":    return DuaContent.duaLovedOne
        case "verse_reflection": return DuaContent.verseReflection
        case "dua_knowledge":    return DuaContent.duaKnowledge
        case "dua_relief":       return DuaContent.duaRelief
        case "dua_morning":      return DuaContent.duaMorning
        case "dua_evening":      return DuaContent.duaEvening
        case "dua_dunya":        return DuaContent.duaDunya
        case "dua_heart":        return DuaContent.duaHeart
        case "dua_hasbi":        return DuaContent.duaHasbi
        case "dua_jannah":       return DuaContent.duaJannah
        case "salawat":          return DhikrType.salawatArabicFull
        default: return nil
        }
    }

    static func translationKey(key: String) -> String {
        key == "salawat" ? "dhikr.salawat.translation_full" : "dua.\(key).translation"
    }

    private static let ayatAlKursi = """
    اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ
    لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ
    لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ
    مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ
    يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ
    وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ
    وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ
    وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ
    """

    private static let sayyidIstighfar = """
    اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ
    خَلَقْتَنِي وَأَنَا عَبْدُكَ
    وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ
    أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ
    أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي
    فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ
    """

    private static let duaParents = """
    رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا
    """

    private static let duaUmmah = """
    اللَّهُمَّ أَصْلِحْ أُمَّةَ مُحَمَّدٍ
    اللَّهُمَّ فَرِّجْ عَنْ أُمَّةِ مُحَمَّدٍ
    اللَّهُمَّ ارْحَمْ أُمَّةَ مُحَمَّدٍ
    """

    private static let duaLovedOne = """
    اللَّهُمَّ بَارِكْ لَهُ فِيمَا رَزَقْتَهُ
    وَاغْفِرْ لَهُ وَارْحَمْهُ
    وَعَافِهِ وَاعْفُ عَنْهُ
    """

    private static let verseReflection = """
    إِنَّ فِي خَلْقِ السَّمَاوَاتِ وَالْأَرْضِ
    وَاخْتِلَافِ اللَّيْلِ وَالنَّهَارِ
    لَآيَاتٍ لِأُولِي الْأَلْبَابِ
    """

    private static let duaKnowledge = """
    رَبِّ زِدْنِي عِلْمًا
    """

    private static let duaRelief = """
    اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحُزْنِ
    """

    private static let duaMorning = """
    أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ
    """

    private static let duaEvening = """
    أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ
    """

    private static let duaDunya = """
    رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ
    """

    private static let duaHeart = """
    رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً ۚ إِنَّكَ أَنْتَ الْوَهَّابُ
    """

    private static let duaHasbi = """
    حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ
    """

    private static let duaJannah = """
    اللَّهُمَّ إِنِّي أَسْأَلُكَ الْجَنَّةَ وَأَعُوذُ بِكَ مِنَ النَّارِ
    """
}

// MARK: - Surah Content (full Arabic + translation key)

enum SurahContent {
    static func arabic(key: String) -> String? {
        switch key {
        case "ikhlas": return SurahContent.ikhlasArabic
        case "falaq": return SurahContent.falaqArabic
        case "nas": return SurahContent.nasArabic
        case "fatiha": return SurahContent.fatihaArabic
        case "kafirun": return SurahContent.kafirunArabic
        case "kawthar": return SurahContent.kawtharArabic
        case "asr": return SurahContent.asrArabic
        default: return nil
        }
    }

    static func translationKey(key: String) -> String { "surah.\(key).translation" }

    private static let ikhlasArabic = """
    بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
    قُلْ هُوَ اللَّهُ أَحَدٌ
    اللَّهُ الصَّمَدُ
    لَمْ يَلِدْ وَلَمْ يُولَدْ
    وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ
    """

    private static let falaqArabic = """
    بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
    قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ
    مِنْ شَرِّ مَا خَلَقَ
    وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ
    وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ
    وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ
    """

    private static let nasArabic = """
    بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
    قُلْ أَعُوذُ بِرَبِّ النَّاسِ
    مَلِكِ النَّاسِ
    إِلَٰهِ النَّاسِ
    مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ
    الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ
    مِنَ الْجِنَّةِ وَالنَّاسِ
    """

    private static let fatihaArabic = """
    بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
    الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ
    الرَّحْمَٰنِ الرَّحِيمِ
    مَالِكِ يَوْمِ الدِّينِ
    إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ
    اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ
    صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ
    """

    private static let kafirunArabic = """
    بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
    قُلْ يَا أَيُّهَا الْكَافِرُونَ
    لَا أَعْبُدُ مَا تَعْبُدُونَ
    وَلَا أَنْتُمْ عَابِدُونَ مَا أَعْبُدُ
    وَلَا أَنَا عَابِدٌ مَا عَبَدْتُمْ
    وَلَا أَنْتُمْ عَابِدُونَ مَا أَعْبُدُ
    لَكُمْ دِينُكُمْ وَلِيَ دِينِ
    """

    private static let kawtharArabic = """
    بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
    إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ
    فَصَلِّ لِرَبِّكَ وَانْحَرْ
    إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ
    """

    private static let asrArabic = """
    بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
    وَالْعَصْرِ
    إِنَّ الْإِنْسَانَ لَفِي خُسْرٍ
    إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ
    """
}

// MARK: - Task Model

struct GoodDeedTask: Identifiable {
    let id: String
    let title: String
    let instruction: String
    let difficulty: TaskDifficulty
    let style: GoodDeedTaskStyle
    /// When set (e.g. "ikhlas", "falaq", "nas"), task card shows full Arabic + translation.
    let surahKey: String?

    /// How many taps the user must do on the dhikr button (default 3, can be 33 etc.)
    let requiredTaps: Int
    /// When true, the user must type a personal reflection before completing.
    let requiresInput: Bool
    /// Localisation key for the text input placeholder.
    let inputPlaceholderKey: String

    /// When set, task card shows the full Arabic dua + translation.
    let duaKey: String?

    init(id: String, title: String, instruction: String, difficulty: TaskDifficulty,
         style: GoodDeedTaskStyle, surahKey: String? = nil, duaKey: String? = nil,
         requiredTaps: Int = 3,
         requiresInput: Bool = false, inputPlaceholderKey: String = "task.input.placeholder") {
        self.id = id
        self.title = title
        self.instruction = instruction
        self.difficulty = difficulty
        self.style = style
        self.surahKey = surahKey
        self.duaKey = duaKey
        self.requiredTaps = requiredTaps
        self.requiresInput = requiresInput
        self.inputPlaceholderKey = inputPlaceholderKey
    }

    var unlockMinutes: Int { difficulty.unlockMinutes }

    /// Coins this deed pays. Each deed has its own amount.
    var coins: Int { Self.coinRewardByID[id] ?? 20 }

    private static let coinRewardByID: [String: Int] = [
        "easy_9": 14,
        "easy_1": 15,
        "easy_3": 16,
        "easy_2": 18,
        "easy_4": 20,
        "easy_5": 22,
        "easy_7": 24,
        "easy_8": 26,
        "easy_10": 28,
        "easy_6": 30,
        "med_19": 32,
        "med_16": 34,
        "med_1": 35,
        "med_20": 36,
        "med_2": 38,
        "med_3": 40,
        "med_10": 42,
        "med_11": 44,
        "med_13": 45,
        "med_12": 46,
        "med_17": 47,
        "med_9": 48,
        "med_6": 50,
        "med_7": 52,
        "med_14": 55,
        "med_15": 58,
        "med_18": 60,
        "hard_3": 65,
        "hard_2": 70,
        "hard_1": 80
    ]

    var isDhikr: Bool {
        if case .dhikr = style { return true }
        return false
    }

    var dhikrType: DhikrType? {
        if case .dhikr(let t) = style { return t }
        return nil
    }

    var isSurahTask: Bool { surahKey != nil && SurahContent.arabic(key: surahKey!) != nil }
    var isDuaTask: Bool { duaKey != nil && DuaContent.arabic(key: duaKey!) != nil }
}

// MARK: - Task Manager

@MainActor
final class GoodDeedTaskManager {
    static let shared = GoodDeedTaskManager()
    private init() {}

    private var lastUsedId: String?

    // MARK: Task Pool — reward minutes follow onboarding Easy (60) / Medium (30) / Hard (15), else legacy 10

    let allTasks: [GoodDeedTask] = [
        // Dhikr — 3 taps each
        GoodDeedTask(id: "easy_1", title: "SubhanAllah",
                     instruction: "Say SubhanAllah 3 times with full presence.",
                     difficulty: .standard, style: .dhikr(.subhanallah), requiredTaps: 3),
        GoodDeedTask(id: "easy_2", title: "Alhamdulillah",
                     instruction: "Say Alhamdulillah 3 times with gratitude in your heart.",
                     difficulty: .standard, style: .dhikr(.alhamdulillah), requiredTaps: 3),
        GoodDeedTask(id: "easy_3", title: "Allahu Akbar",
                     instruction: "Say Allahu Akbar 3 times, remembering His greatness.",
                     difficulty: .standard, style: .dhikr(.allahuAkbar), requiredTaps: 3),
        GoodDeedTask(id: "easy_4", title: "Astaghfirullah",
                     instruction: "Say Astaghfirullah 3 times, seeking His forgiveness.",
                     difficulty: .standard, style: .dhikr(.astaghfirullah), requiredTaps: 3),
        GoodDeedTask(id: "easy_5", title: "La ilaha illa Allah",
                     instruction: "Say La ilaha illa Allah 3 times, affirming His oneness.",
                     difficulty: .standard, style: .dhikr(.laIlahaIllaAllah), requiredTaps: 3),
        GoodDeedTask(id: "easy_7", title: "SubhanAllahi wa bihamdihi",
                     instruction: "Say SubhanAllahi wa bihamdihi 3 times.",
                     difficulty: .standard, style: .dhikr(.subhanAllahiWaBihamdihi), requiredTaps: 3),
        GoodDeedTask(id: "easy_8", title: "La hawla wa la quwwata illa billah",
                     instruction: "Say La hawla wa la quwwata illa billah 3 times.",
                     difficulty: .standard, style: .dhikr(.laHawla), requiredTaps: 3),
        GoodDeedTask(id: "easy_9", title: "Bismillah",
                     instruction: "Say Bismillah ar-Rahman ar-Raheem 3 times, beginning with His name.",
                     difficulty: .standard, style: .dhikr(.bismillah), requiredTaps: 3),
        GoodDeedTask(id: "easy_10", title: "Hasbunallah",
                     instruction: "Say Hasbunallah wa ni'mal wakeel 3 times, trusting in Allah.",
                     difficulty: .standard, style: .dhikr(.hasbunallah), requiredTaps: 3),

        // Deed tasks — 1 completion each
        GoodDeedTask(id: "med_1", title: "Surah Al-Ikhlas",
                     instruction: "Recite Surah Al-Ikhlas slowly and with full attention. Feel the meaning of each word.",
                     difficulty: .standard, style: .deed, surahKey: "ikhlas"),
        GoodDeedTask(id: "med_2", title: "Surah Al-Falaq",
                     instruction: "Recite Surah Al-Falaq and reflect on seeking refuge only in Allah.",
                     difficulty: .standard, style: .deed, surahKey: "falaq"),
        GoodDeedTask(id: "med_3", title: "Surah An-Nas",
                     instruction: "Recite Surah An-Nas with sincerity, remembering that Allah alone protects.",
                     difficulty: .standard, style: .deed, surahKey: "nas"),
        GoodDeedTask(id: "easy_6", title: "Salawat",
                     instruction: "Send salawat upon the Prophet ﷺ once, with love and presence.",
                     difficulty: .standard, style: .deed, duaKey: "salawat"),
        GoodDeedTask(id: "med_6", title: "Dua for Your Parents",
                     instruction: "Pause and make sincere dua for your parents. Ask Allah to bless, protect, and have mercy on them.",
                     difficulty: .standard, style: .deed, duaKey: "dua_parents"),
        GoodDeedTask(id: "med_7", title: "Dua for the Ummah",
                     instruction: "Make heartfelt dua for the Muslim Ummah. Pray for ease, unity, and mercy for all who are struggling.",
                     difficulty: .standard, style: .deed, duaKey: "dua_ummah"),
        GoodDeedTask(id: "med_9", title: "Surah Al-Fatiha",
                     instruction: "Recite Surah Al-Fatiha with presence. Reflect on asking Allah for guidance.",
                     difficulty: .standard, style: .deed, surahKey: "fatiha"),
        GoodDeedTask(id: "med_10", title: "Surah Al-Kafirun",
                     instruction: "Recite Surah Al-Kafirun. Ponder the clarity of tawheed in your heart.",
                     difficulty: .standard, style: .deed, surahKey: "kafirun"),
        GoodDeedTask(id: "med_11", title: "Dua for Knowledge",
                     instruction: "Ask Allah to increase you in beneficial knowledge. Say Rabbi zidni ilma with sincerity.",
                     difficulty: .standard, style: .deed, duaKey: "dua_knowledge"),
        GoodDeedTask(id: "med_12", title: "Dua for Relief",
                     instruction: "Seek refuge in Allah from worry and grief. Say the dua with a calm heart.",
                     difficulty: .standard, style: .deed, duaKey: "dua_relief"),
        GoodDeedTask(id: "med_13", title: "Morning Remembrance",
                     instruction: "Recite the morning remembrance: Asbahna wa asbahal-mulku lillah.",
                     difficulty: .standard, style: .deed, duaKey: "dua_morning"),
        GoodDeedTask(id: "hard_1", title: "Ayat al-Kursi",
                     instruction: "Recite Ayat al-Kursi slowly and with full presence. Reflect on the greatness of Allah described within it.",
                     difficulty: .standard, style: .deed, duaKey: "ayat_al_kursi"),
        GoodDeedTask(id: "hard_2", title: "Ask Forgiveness",
                     instruction: "Ask Allah sincerely for forgiveness. Be specific about what you regret and renew your intention to do better.",
                     difficulty: .standard, style: .deed, duaKey: "istighfar"),
        GoodDeedTask(id: "hard_3", title: "Dua for Someone You Love",
                     instruction: "Think of someone dear to you and make a sincere dua for them. Ask Allah to bless them in this life and the next.",
                     difficulty: .standard, style: .deed, duaKey: "dua_loved_one"),
        GoodDeedTask(id: "med_14", title: "Good in Both Worlds",
                     instruction: "Ask Allah for good in this life and the next, and for protection from the Fire.",
                     difficulty: .standard, style: .deed, duaKey: "dua_dunya"),
        GoodDeedTask(id: "med_15", title: "A Steadfast Heart",
                     instruction: "Ask Allah not to let your heart slip after He has guided you.",
                     difficulty: .standard, style: .deed, duaKey: "dua_heart"),
        GoodDeedTask(id: "med_16", title: "Allah Is Enough",
                     instruction: "Say Hasbiyallahu la ilaha illa Huwa once, placing your trust in Him.",
                     difficulty: .standard, style: .deed, duaKey: "dua_hasbi"),
        GoodDeedTask(id: "med_17", title: "Evening Remembrance",
                     instruction: "Recite the evening remembrance: Amsayna wa amsal-mulku lillah.",
                     difficulty: .standard, style: .deed, duaKey: "dua_evening"),
        GoodDeedTask(id: "med_18", title: "Ask for Paradise",
                     instruction: "Ask Allah for Jannah and seek refuge in Him from the Fire.",
                     difficulty: .standard, style: .deed, duaKey: "dua_jannah"),
        GoodDeedTask(id: "med_19", title: "Surah Al-Kawthar",
                     instruction: "Recite Surah Al-Kawthar slowly. It is a gift from Allah.",
                     difficulty: .standard, style: .deed, surahKey: "kawthar"),
        GoodDeedTask(id: "med_20", title: "Surah Al-Asr",
                     instruction: "Recite Surah Al-Asr and remember that time is passing.",
                     difficulty: .standard, style: .deed, surahKey: "asr"),
    ]

    var allTitles: [String] { allTasks.map { $0.title } }

    func task(withID id: String) -> GoodDeedTask? {
        allTasks.first { $0.id == id }
    }

    func selectTask() -> GoodDeedTask {
        let candidates = allTasks.filter { $0.id != lastUsedId }
        let selected = (candidates.isEmpty ? allTasks : candidates).randomElement() ?? allTasks[0]
        lastUsedId = selected.id
        return selected
    }
}
