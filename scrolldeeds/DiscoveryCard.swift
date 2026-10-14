//
//  DiscoveryCard.swift
//  scrolldeeds
//
//  One “vocabulary-style” card: a sunnah, ayah, adab, hadith, or fact.
//  Unlock uses the next unseen card so every deed teaches something new.
//

import Combine
import Foundation

enum DiscoveryKind: String, CaseIterable {
    case sunnah
    case ayah
    case adab
    case hadith
    case fact

    var localizationKey: String { "discovery.kind.\(rawValue)" }

    var label: String {
        NSLocalizedString(localizationKey, comment: rawValue)
    }
}

struct DiscoveryCard: Identifiable, Equatable {
    let id: String
    let kind: DiscoveryKind
    let arabic: String?

    private var rawMeaning: String {
        NSLocalizedString("discovery.card.\(id).meaning", comment: "")
    }

    var title: String {
        let stored = NSLocalizedString("discovery.card.\(id).title", comment: "")
        if id.hasPrefix("ayah_") || id.hasPrefix("sunnah_") {
            return DiscoveryHeadline.title(from: rawMeaning, id: id)
        }
        return stored
    }

    var meaning: String {
        if id.hasPrefix("ayah_") || id.hasPrefix("sunnah_") {
            return DiscoveryHeadline.meaning(from: rawMeaning, id: id)
        }
        return rawMeaning
    }

    var source: String {
        NSLocalizedString("discovery.card.\(id).source", comment: "")
    }

    /// Companion pose above the kind label on the Scroll feed — varies per card,
    /// with a small pool tuned to each kind so ayah/hadith/etc. feel distinct.
    var feedBuddyPose: String {
        let pool: [String]
        switch kind {
        case .hadith:
            pool = ["NafsiScrollRead", "NafsiScrollWatch", "NafsiScrollStand"]
        case .ayah:
            pool = ["NafsiScrollOffer", "NafsiScrollWatch", "NafsiScrollRead"]
        case .sunnah:
            pool = ["NafsiScrollStand", "NafsiScrollReach", "NafsiScrollOffer"]
        case .adab:
            pool = ["NafsiScrollWatch", "NafsiScrollOffer", "NafsiScrollStand"]
        case .fact:
            pool = ["NafsiScrollWatch", "NafsiScrollRead", "NafsiScrollReach"]
        }
        let hash = id.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        return pool[abs(hash) % pool.count]
    }
}

/// Complete topic title from the existing translation — never clipped with “…”, never invented wording.
enum DiscoveryHeadline {
    static func title(from meaning: String, id: String) -> String {
        let body = teachingBody(from: meaning)
        if id.hasPrefix("ayah_36_1") || isDisconnectedLetters(body) {
            return polish(isDisconnectedLetters(body) ? body : "Ya-Sin")
        }
        if id.hasPrefix("ayah_55_1") || divineName(in: body) != nil {
            let name = divineName(in: body) ?? lastToken(in: body)
            return String(
                format: NSLocalizedString("discovery.explain.allah_name.title", comment: "Name of Allah title"),
                name
            )
        }
        if let asIf = asIfTitle(from: body) { return asIf }
        if let prohibition = prohibitionTitle(from: body) { return prohibition }
        if let twoPart = twoPartTitle(from: body) { return twoPart }
        return summaryPhrase(from: body)
    }

    static func meaning(from meaning: String, id: String) -> String {
        let trimmed = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = teachingBody(from: trimmed)
        if id.hasPrefix("ayah_36_1") || isDisconnectedLetters(body) {
            let letters = polish(isDisconnectedLetters(body) ? body : "Ya-Sin")
            let note = String(
                format: NSLocalizedString("discovery.explain.muqattaat.body", comment: "Disconnected letters"),
                letters
            )
            return trimmed + "\n\n" + note
        }
        if id.hasPrefix("ayah_55_1") || divineName(in: body) != nil {
            let name = divineName(in: body) ?? lastToken(in: body)
            let note = String(
                format: NSLocalizedString("discovery.explain.allah_name.body", comment: "Name of Allah"),
                name
            )
            return trimmed + "\n\n" + note
        }
        return trimmed
    }

    private static let filler: Set<String> = [
        "the", "a", "an", "of", "and", "or", "to", "in", "on", "for", "with", "from",
        "that", "this", "his", "her", "their", "he", "she", "it", "was", "were", "had",
        "de", "het", "een", "van", "en", "op", "te", "dat", "die", "hij", "zij", "zijn",
        "el", "la", "los", "las", "un", "una", "y", "que", "su", "se",
        "le", "les", "des", "du", "et", "une", "il", "elle",
        "der", "die", "das", "und", "ein", "im", "er", "sie",
        "и", "в", "на", "с", "что", "он", "его",
        "ال", "في", "من", "على", "و", "أن", "هو",
        "terwijl", "while", "mientras", "während", "pendant", "пока",
        "waarheen", "wherever", "donde", "wohin"
    ]

    private static let bonus = [
        "ziel", "soul", "alma", "seele", "âme", "душ", "نفس",
        "mensen", "mankind", "humanity", "hombres", "menschen", "humanité", "людей", "ناس",
        "qibla", "kibla", "qiblah", "قبس", "قبلة",
        "rijdier", "mount", "animal", "montura", "reittier", "monture", "животн",
        "gebed", "prayer", "salah", "salat", "oración", "gebet", "prière", "молитв", "صلاة",
        "sujud", "prostration", "urine", "urineren", "water", "still", "stilstaand",
        "barmhartig", "merciful", "compasivo", "erbarmer", "rahman",
        "doodt", "kills", "kill", "slay", "mata", "tötet", "tue", "убива"
    ]

    private static func teachingBody(from meaning: String) -> String {
        var text = normalizeQuotes(meaning).trimmingCharacters(in: .whitespacesAndNewlines)
        if let quoted = preferredQuote(in: text) {
            return quoted
        }
        let patterns = [
            #"^(?:Narrated|Overgeleverd|Relatado|Transmitido|Überliefert|Rapporté|Передано|روي)[^.!?\n]{0,180}[:：]\s*"#,
            #"(?i)^(?:the same narrator|dezelfde overleveraar|el mismo narrador|derselbe überlieferer|le même rapporteur|тот же передатчик).{0,80}?(?:said|zei|dijo|sagte|dit|сказал)\s+(?:that|dat|que|dass|что)\s+.{0,80}?(?:said|gezegd|dicho|gesagt|dit|сказал)\s*[:：]\s*"#,
            #"(?i)(?:the (?:holy )?(?:prophet|messenger of allah|messenger)|allah'?s messenger|de (?:profeet|boodschapper van allah)|el (?:profeta|mensajero de al[aá]h)|der (?:prophet|gesandte allahs)|le (?:prophète|messager d['']allah)|пророк|посланник аллаха).{0,60}(?:said|had said|zei|had gezegd|dijo|sagte|dit|сказал|قال)\s*(?:\([^)]{0,12}\))?\s*[:：]\s*"#,
            #"(?i)(?:the (?:holy )?(?:prophet|messenger of allah|messenger)|de (?:profeet|boodschapper van allah)|el (?:profeta|mensajero de al[aá]h)|der (?:prophet|gesandte allahs)|le (?:prophète|messager d['']allah)|пророк|посланник аллаха).{0,40}(?:used to|would|placht|solía|pflegte|avait l'habitude|имел обыкновение|كان)\s+"#,
            #"(?i)^(?:because of that,?|therefore|daarom|por eso|darum|c'est pourquoi|поэтому).{0,80}?(?:children of israel|kinderem van israel|kinderen van israel|hijos de israel|kinder israel|fils d'israël|сынов израиля).{0,40}?(?:that|dat|que|dass|что)\s+"#,
            #"(?i)^(?:o (?:you who (?:have )?believed|mankind|people|believers)|o jullie die geloven|o mensen)[,،:]?\s+"#
        ]
        for pattern in patterns {
            text = replace(pattern, in: text, with: "")
        }
        text = text.replacingOccurrences(of: #"\([^)]{0,80}\)"#, with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
    }

    private static func preferredQuote(in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "\"([^\"]{8,})\"") else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        let quotes = regex.matches(in: text, range: range).compactMap { match -> String? in
            guard let inner = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[inner]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let first = quotes.first else { return nil }
        if quotes.count >= 2, first.hasSuffix("?") || first.hasSuffix("؟") {
            return quotes[1]
        }
        return first
    }

    private static func asIfTitle(from text: String) -> String? {
        let pattern = #"(?i)(?:voor )?wie\s+(.{6,40}?)\s+(?:[-–—(].{0,100}?)?(?:het is )?alsof\s+(.{6,48}?)(?:\.| en dat| en |$)"#
        if let match = firstGroups(pattern, in: text, count: 2) {
            return polish("Wie \(match[0]), alsof \(match[1])")
        }
        let en = #"(?i)whoever\s+(.{6,42}?)\s+(?:unless|except|[-–—(].{0,90}?)?(?:it is )?as if\s+(.{6,48}?)(?:\.| and |$)"#
        if let match = firstGroups(en, in: text, count: 2) {
            return polish("Whoever \(match[0]): as if \(match[1])")
        }
        let es = #"(?i)quien\s+(.{6,42}?)\s+(?:[-–—(].{0,90}?)?(?:es )?como si\s+(.{6,48}?)(?:\.| y |$)"#
        if let match = firstGroups(es, in: text, count: 2) {
            return polish("Quien \(match[0]), como si \(match[1])")
        }
        let de = #"(?i)wer\s+(.{6,42}?)\s+(?:[-–—(].{0,90}?)?(?:so )?als ob\s+(.{6,48}?)(?:\.| und |$)"#
        if let match = firstGroups(de, in: text, count: 2) {
            return polish("Wer \(match[0]), als ob \(match[1])")
        }
        let fr = #"(?i)quiconque\s+(.{6,42}?)\s+(?:[-–—(].{0,90}?)?(?:c'est )?comme si\s+(.{6,48}?)(?:\.| et |$)"#
        if let match = firstGroups(fr, in: text, count: 2) {
            return polish("Quiconque \(match[0]), comme si \(match[1])")
        }
        return nil
    }

    private static func prohibitionTitle(from text: String) -> String? {
        let pattern = #"(?i)((?:jullie mogen niet|you may not|do not|don't|niet|no |ne |не )\s[^.,]{8,52}?)(?:\s+dat |\s+that |\s+om |\s+in order|\s+so that|\s+para |\s+um |\s+pour |\s+,|\.|$)"#
        guard let match = firstGroups(pattern, in: text, count: 1) else { return nil }
        let phrase = polish(match[0])
        return phrase.count >= 14 ? phrase : nil
    }

    private static func twoPartTitle(from text: String) -> String? {
        let pattern = #"(?i)^(.{12,}?),\s*(?:en wanneer|and when|y cuando|und wenn|et quand|и когда)\s+(.{12,})$"#
        guard let match = firstGroups(pattern, in: text, count: 2) else { return nil }
        let first = summaryPhrase(from: match[0], wordLimit: 6)
        let second = summaryPhrase(from: match[1], wordLimit: 6)
        guard first.count >= 10, second.count >= 10 else { return nil }
        return "\(first), \(second)"
    }

    private static func summaryPhrase(from text: String, wordLimit: Int = 8) -> String {
        var cleaned = replace(#"\s+"#, in: text, with: " ")
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = cleaned.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if words.count <= wordLimit, cleaned.count <= 58 {
            return polish(cleaned)
        }
        if let window = bestWindow(in: words, size: wordLimit) {
            return polish(window)
        }
        let capped = Array(words.prefix(wordLimit))
        return polish(capped.joined(separator: " "))
    }

    private static func bestWindow(in words: [String], size: Int) -> String? {
        guard words.count >= 4 else { return words.joined(separator: " ") }
        let windowSize = min(max(size, 5), min(8, words.count))
        var best: (score: Int, text: String)?
        for length in (5...windowSize).reversed() {
            guard words.count >= length else { continue }
            for start in 0...(words.count - length) {
                let slice = Array(words[start..<(start + length)])
                let first = slice[0].lowercased().trimmingCharacters(in: .punctuationCharacters)
                let last = slice[length - 1].lowercased().trimmingCharacters(in: .punctuationCharacters)
                if filler.contains(first) || filler.contains(last) { continue }
                var score = slice.filter { word in
                    let key = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                    return key.count > 3 && !filler.contains(key)
                }.count * 2
                let joined = slice.joined(separator: " ").lowercased()
                for term in bonus where joined.contains(term) {
                    score += 6
                }
                if start == 0 { score -= 2 }
                if best == nil || score > best!.score {
                    best = (score, slice.joined(separator: " "))
                }
            }
            if let best, best.score >= 10 { return best.text }
        }
        return best?.text
    }

    private static func divineName(in text: String) -> String? {
        let cleaned = polish(text)
        let compact = cleaned.lowercased()
        guard cleaned.split(whereSeparator: { $0.isWhitespace }).count <= 4 else { return nil }
        let names = [
            "erbarmer", "allerbarmer", "most merciful", "entirely merciful", "beneficent",
            "compasivo", "misericordioso", "tout miséricordieux", "miséricordieux",
            "милостивый", "الرحمن", "ar-rahman", "ar-rahmaan", "rahmaan", "rahman"
        ]
        guard names.contains(where: { compact.contains($0) }) else { return nil }
        return cleaned
    }

    private static func isDisconnectedLetters(_ text: String) -> Bool {
        let compact = polish(text).lowercased().replacingOccurrences(of: "î", with: "i")
        return compact == "ya sin" || compact == "ya-sin" || compact == "yasin" || compact == "يس"
    }

    private static func normalizeQuotes(_ text: String) -> String {
        text
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "„", with: "\"")
            .replacingOccurrences(of: "«", with: "\"")
            .replacingOccurrences(of: "»", with: "\"")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "’", with: "'")
    }

    private static func replace(_ pattern: String, in text: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }

    private static func firstGroups(_ pattern: String, in text: String, count: Int) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        var groups: [String] = []
        for index in 1...count {
            guard let inner = Range(match.range(at: index), in: text) else { return nil }
            groups.append(String(text[inner]).trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return groups
    }

    private static func lastToken(in text: String) -> String {
        let cleaned = polish(text)
        guard let last = cleaned.split(whereSeparator: { $0.isWhitespace }).last else {
            return cleaned
        }
        return polish(String(last))
    }

    private static func polish(_ text: String) -> String {
        var result = text.trimmingCharacters(in: CharacterSet(charactersIn: " \"'.,;:"))
        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        guard let first = result.first else { return result }
        if first.isASCII, first.isLetter, first.isLowercase {
            result.replaceSubrange(result.startIndex...result.startIndex, with: String(first).uppercased())
        }
        return result
    }
}

enum DiscoveryCatalog {
    private static let mixOrder: [DiscoveryKind] = [.fact, .ayah, .sunnah, .hadith, .adab]

    /// Trivia templates (surah X has N ayahs / juz names) feel random — keep EXTRA_FACTS and teachings.
    private static func isLowSignal(_ card: DiscoveryCard) -> Bool {
        let id = card.id
        if id.hasPrefix("fact_surah_") || id.hasPrefix("fact_juz_") { return true }
        // Long legal / combat passages without a clear daily lesson for this app.
        let blocked: Set<String> = [
            "ayah_5_3", "ayah_5_2", "ayah_2_216", "ayah_4_1", "ayah_5_6",
            "ayah_2_177", "ayah_3_103", "ayah_2_185", "ayah_5_32", "ayah_2_197"
        ]
        return blocked.contains(id)
    }

    private static let baseCards: [DiscoveryCard] = [
        DiscoveryCard(id: "smile", kind: .sunnah, arabic: "تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ صَدَقَةٌ"),
        DiscoveryCard(id: "salam", kind: .sunnah, arabic: "السَّلَامُ عَلَيْكُمْ"),
        DiscoveryCard(id: "right_hand", kind: .sunnah, arabic: nil),
        DiscoveryCard(id: "bismillah_eat", kind: .sunnah, arabic: "بِسْمِ اللَّهِ"),
        DiscoveryCard(id: "right_shoe", kind: .adab, arabic: nil),
        DiscoveryCard(id: "siwak", kind: .sunnah, arabic: nil),
        DiscoveryCard(id: "anger", kind: .sunnah, arabic: "لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ"),
        DiscoveryCard(id: "visit_sick", kind: .sunnah, arabic: nil),
        DiscoveryCard(
            id: "two_words",
            kind: .hadith,
            arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ"
        ),
        DiscoveryCard(id: "ease", kind: .ayah, arabic: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا"),
        DiscoveryCard(id: "neighbor", kind: .adab, arabic: nil),
        DiscoveryCard(id: "knowledge", kind: .ayah, arabic: "رَبِّ زِدْنِي عِلْمًا"),
        DiscoveryCard(id: "intention", kind: .hadith, arabic: "إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ"),
        DiscoveryCard(id: "half_date", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "remove_harm", kind: .sunnah, arabic: nil),
        DiscoveryCard(id: "ikhlas", kind: .ayah, arabic: "قُلْ هُوَ اللَّهُ أَحَدٌ"),
        DiscoveryCard(id: "kursi", kind: .ayah, arabic: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ"),
        DiscoveryCard(id: "mercy", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "parents", kind: .ayah, arabic: "فَلَا تَقُلْ لَهُمَا أُفٍّ"),
        DiscoveryCard(id: "backbite", kind: .ayah, arabic: nil),
        DiscoveryCard(id: "inshaallah", kind: .ayah, arabic: "وَلَا تَقُولَنَّ لِشَيْءٍ إِنِّي فَاعِلٌ ذَٰلِكَ غَدًا إِلَّا أَن يَشَاءَ اللَّهُ"),
        DiscoveryCard(id: "purification", kind: .hadith, arabic: "الطُّهُورُ شَطْرُ الْإِيمَانِ"),
        DiscoveryCard(id: "conceal", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "night_prayer", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "return_salam", kind: .ayah, arabic: nil),
        DiscoveryCard(id: "patience", kind: .ayah, arabic: "يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ"),
        DiscoveryCard(id: "tawakkul", kind: .ayah, arabic: "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ"),
        DiscoveryCard(id: "istighfar", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "wudu_sleep", kind: .sunnah, arabic: nil),
        DiscoveryCard(id: "enter_home", kind: .sunnah, arabic: nil),
        DiscoveryCard(id: "lower_gaze", kind: .ayah, arabic: "قُل لِّلْمُؤْمِنِينَ يَغُضُّوا مِنْ أَبْصَارِهِمْ"),
        DiscoveryCard(id: "upper_hand", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "fatiha", kind: .ayah, arabic: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ"),
        DiscoveryCard(id: "honor_guest", kind: .adab, arabic: nil),
        DiscoveryCard(id: "love_brother", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "remember_me", kind: .ayah, arabic: "فَاذْكُرُونِي أَذْكُرْكُمْ"),
        DiscoveryCard(id: "no_envy", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "truthfulness", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "ghusl_friday", kind: .sunnah, arabic: nil),
        DiscoveryCard(id: "speak_good", kind: .adab, arabic: nil),
        DiscoveryCard(id: "fajr_sunnah", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "haya", kind: .hadith, arabic: "الْحَيَاءُ شُعْبَةٌ مِنَ الْإِيمَانِ"),
        DiscoveryCard(id: "no_burden", kind: .ayah, arabic: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا"),
        DiscoveryCard(id: "mankind", kind: .ayah, arabic: "يَا أَيُّهَا النَّاسُ إِنَّا خَلَقْنَاكُم مِّن ذَكَرٍ وَأُنثَىٰ"),
        DiscoveryCard(id: "shukr", kind: .ayah, arabic: "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ"),
        DiscoveryCard(id: "dua_near", kind: .ayah, arabic: "وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ"),
        DiscoveryCard(id: "no_despair", kind: .ayah, arabic: "لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ"),
        DiscoveryCard(id: "qadr", kind: .ayah, arabic: "لَيْلَةُ الْقَدْرِ خَيْرٌ مِّنْ أَلْفِ شَهْرٍ"),
        DiscoveryCard(id: "duha_care", kind: .ayah, arabic: "مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ"),
        DiscoveryCard(id: "asr", kind: .ayah, arabic: "إِنَّ الْإِنسَانَ لَفِي خُسْرٍ"),
        DiscoveryCard(id: "kawthar", kind: .ayah, arabic: "إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ"),
        DiscoveryCard(id: "no_compulsion", kind: .ayah, arabic: "لَا إِكْرَاهَ فِي الدِّينِ"),
        DiscoveryCard(id: "with_you", kind: .ayah, arabic: "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ"),
        DiscoveryCard(id: "closer", kind: .ayah, arabic: "وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ"),
        DiscoveryCard(id: "spouses", kind: .ayah, arabic: "وَجَعَلَ بَيْنَكُم مَّوَدَّةً وَرَحْمَةً"),
        DiscoveryCard(id: "blessings_count", kind: .ayah, arabic: "وَإِن تَعُدُّوا نِعْمَةَ اللَّهِ لَا تُحْصُوهَا"),
        DiscoveryCard(id: "fasting_prescribed", kind: .ayah, arabic: "كُتِبَ عَلَيْكُمُ الصِّيَامُ"),
        DiscoveryCard(id: "yunus_dua", kind: .ayah, arabic: "لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ"),
        DiscoveryCard(id: "hasbuna", kind: .ayah, arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ"),
        DiscoveryCard(id: "rabbana_atina", kind: .ayah, arabic: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً"),
        DiscoveryCard(id: "be_and_it_is", kind: .ayah, arabic: "إِنَّمَا أَمْرُهُ إِذَا أَرَادَ شَيْئًا أَن يَقُولَ لَهُ كُن فَيَكُونُ"),
        DiscoveryCard(id: "which_favors", kind: .ayah, arabic: "فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ"),
        DiscoveryCard(id: "calamity", kind: .ayah, arabic: "مَا أَصَابَ مِن مُّصِيبَةٍ إِلَّا بِإِذْنِ اللَّهِ"),
        DiscoveryCard(id: "death_life", kind: .ayah, arabic: "الَّذِي خَلَقَ الْمَوْتَ وَالْحَيَاةَ لِيَبْلُوَكُمْ أَيُّكُمْ أَحْسَنُ عَمَلًا"),
        DiscoveryCard(id: "kafirun", kind: .ayah, arabic: "لَكُمْ دِينُكُمْ وَلِيَ دِينِ"),
        DiscoveryCard(id: "nas", kind: .ayah, arabic: "قُلْ أَعُوذُ بِرَبِّ النَّاسِ"),
        DiscoveryCard(id: "falaq", kind: .ayah, arabic: "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ"),
        DiscoveryCard(id: "orphans_duha", kind: .ayah, arabic: "فَأَمَّا الْيَتِيمَ فَلَا تَقْهَرْ"),
        DiscoveryCard(id: "justice", kind: .ayah, arabic: "كُونُوا قَوَّامِينَ بِالْقِسْطِ"),
        DiscoveryCard(id: "amanah", kind: .ayah, arabic: "إِنَّ اللَّهَ يَأْمُرُكُمْ أَن تُؤَدُّوا الْأَمَانَاتِ إِلَىٰ أَهْلِهَا"),
        DiscoveryCard(id: "luqman_salah", kind: .ayah, arabic: "يَا بُنَيَّ أَقِمِ الصَّلَاةَ"),
        DiscoveryCard(id: "infaq_grain", kind: .ayah, arabic: "مَّثَلُ الَّذِينَ يُنفِقُونَ أَمْوَالَهُمْ فِي سَبِيلِ اللَّهِ"),
        DiscoveryCard(id: "rabbana_forgive", kind: .ayah, arabic: "رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا"),
        DiscoveryCard(id: "establish_salah", kind: .ayah, arabic: "وَأَقِيمُوا الصَّلَاةَ وَآتُوا الزَّكَاةَ"),
        DiscoveryCard(id: "way_out", kind: .ayah, arabic: "وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا"),
        DiscoveryCard(id: "sincere_deen", kind: .ayah, arabic: "وَمَا أُمِرُوا إِلَّا لِيَعْبُدُوا اللَّهَ مُخْلِصِينَ لَهُ الدِّينَ"),
        DiscoveryCard(id: "allah_light", kind: .ayah, arabic: "اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ"),
        DiscoveryCard(id: "expand_chest", kind: .ayah, arabic: "أَلَمْ نَشْرَحْ لَكَ صَدْرَكَ"),
        DiscoveryCard(id: "hikmah", kind: .ayah, arabic: "يُؤْتِي الْحِكْمَةَ مَن يَشَاءُ"),
        DiscoveryCard(id: "five_pillars", kind: .hadith, arabic: "بُنِيَ الْإِسْلَامُ عَلَىٰ خَمْسٍ"),
        DiscoveryCard(id: "muslim_tongue", kind: .hadith, arabic: "الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ"),
        DiscoveryCard(id: "deen_nasihah", kind: .hadith, arabic: "الدِّينُ النَّصِيحَةُ"),
        DiscoveryCard(id: "best_quran", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "mother_first", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "plant_tree", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "seven_shade", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "tasbih_salah", kind: .sunnah, arabic: nil),
        DiscoveryCard(id: "hundred_tasbih", kind: .hadith, arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ"),
        DiscoveryCard(id: "enter_masjid", kind: .sunnah, arabic: "اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ"),
        DiscoveryCard(id: "do_not_anger", kind: .hadith, arabic: "لَا تَغْضَبْ"),
        DiscoveryCard(id: "make_easy", kind: .hadith, arabic: "يَسِّرُوا وَلَا تُعَسِّرُوا"),
        DiscoveryCard(id: "religion_ease", kind: .hadith, arabic: "إِنَّ الدِّينَ يُسْرٌ"),
        DiscoveryCard(id: "feed_hungry", kind: .sunnah, arabic: nil),
        DiscoveryCard(id: "good_word", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "no_cheating", kind: .hadith, arabic: "مَنْ غَشَّ فَلَيْسَ مِنِّي"),
        DiscoveryCard(id: "sleep_muawwidhat", kind: .sunnah, arabic: nil),
        DiscoveryCard(id: "treat_women", kind: .hadith, arabic: nil),
        DiscoveryCard(id: "wudu_sins", kind: .hadith, arabic: nil)
    ]

    static let cards: [DiscoveryCard] = {
        var seen = Set<String>()
        var merged: [DiscoveryCard] = []
        for card in baseCards + DiscoveryExpansion.cards where seen.insert(card.id).inserted {
            guard !isLowSignal(card) else { continue }
            merged.append(card)
        }
        return merged
    }()

    private static let curatedIDs: Set<String> = Set(baseCards.map(\.id))

    private static let cardsByID: [String: DiscoveryCard] = Dictionary(
        uniqueKeysWithValues: cards.map { ($0.id, $0) }
    )

    static func card(id: String) -> DiscoveryCard? {
        cardsByID[id]
    }

    /// Round-robin so weetjes, ayahs, and sunnahs show up in the same scroll.
    /// Curated base cards come first so early unlocks feel meaningful, not random.
    static func interleavedIDs(from cards: [DiscoveryCard]? = nil, avoiding lastID: String? = nil) -> [String] {
        let source = cards ?? self.cards
        let curated = source.filter { curatedIDs.contains($0.id) }
        let rest = source.filter { !curatedIDs.contains($0.id) }
        let mixed = mixBuckets(curated) + mixBuckets(rest)
        var result = mixed
        if let lastID, result.first == lastID, result.count > 1 {
            result.swapAt(0, Int.random(in: 1..<result.count))
        }
        return result
    }

    private static func mixBuckets(_ source: [DiscoveryCard]) -> [String] {
        let shuffled = source.shuffled()
        var buckets: [DiscoveryKind: [String]] = [:]
        for card in shuffled {
            buckets[card.kind, default: []].append(card.id)
        }
        var result: [String] = []
        while mixOrder.contains(where: { !(buckets[$0] ?? []).isEmpty }) {
            for kind in mixOrder {
                guard var list = buckets[kind], !list.isEmpty else { continue }
                result.append(list.removeFirst())
                buckets[kind] = list
            }
        }
        return result
    }

    /// Prefer curated cards the user has not seen yet; then the rest; then cycle.
    static func nextCard(seenIDs: Set<String>) -> DiscoveryCard {
        let unseen = cards.filter { !seenIDs.contains($0.id) }
        let curatedUnseen = unseen.filter { curatedIDs.contains($0.id) }
        if let pick = curatedUnseen.randomElement() { return pick }
        if let pick = unseen.randomElement() { return pick }
        return cards.randomElement() ?? cards[0]
    }
}

@MainActor
final class DiscoveryProgressStore: ObservableObject {
    static let shared = DiscoveryProgressStore()

    @Published private(set) var seenIDs: Set<String>
    @Published private(set) var likedIDs: Set<String>
    @Published private(set) var savedIDs: Set<String>
    @Published private(set) var lastCardID: String?
    @Published private(set) var playOrder: [String]

    private let seenKey = "discovery_seen_card_ids"
    private let likedKey = "discovery_liked_card_ids"
    private let savedKey = "discovery_saved_card_ids"
    private let lastKey = "discovery_last_card_id"
    private let playOrderKey = "discovery_play_order"
    private let curationVersionKey = "discovery_curation_version"
    /// Bump when catalog curation changes so play order rebuilds meaningfully.
    private let curationVersion = 3

    private init() {
        if UserDefaults.standard.integer(forKey: curationVersionKey) != curationVersion {
            UserDefaults.standard.set(curationVersion, forKey: curationVersionKey)
            UserDefaults.standard.removeObject(forKey: playOrderKey)
        }
        seenIDs = Self.loadSet(seenKey)
        likedIDs = Self.loadSet(likedKey)
        savedIDs = Self.loadSet(savedKey)
        lastCardID = UserDefaults.standard.string(forKey: lastKey)
        playOrder = UserDefaults.standard.stringArray(forKey: playOrderKey) ?? []
        reconcilePlayOrder()
    }

    var seenCount: Int { seenIDs.count }
    var totalCount: Int { DiscoveryCatalog.cards.count }

    var orderedCards: [DiscoveryCard] {
        let mapped = playOrder.compactMap { DiscoveryCatalog.card(id: $0) }
        return mapped.isEmpty ? DiscoveryCatalog.cards : mapped
    }

    var seenCards: [DiscoveryCard] {
        DiscoveryCatalog.cards.filter { seenIDs.contains($0.id) }
    }

    var savedCards: [DiscoveryCard] {
        DiscoveryCatalog.cards.filter { savedIDs.contains($0.id) }
    }

    var likedCards: [DiscoveryCard] {
        DiscoveryCatalog.cards.filter { likedIDs.contains($0.id) }
    }

    func nextCard() -> DiscoveryCard {
        DiscoveryCatalog.nextCard(seenIDs: seenIDs)
    }

    func restoreCardID() -> String? {
        if let lastCardID, DiscoveryCatalog.card(id: lastCardID) != nil {
            return lastCardID
        }
        return orderedCards.first?.id ?? DiscoveryCatalog.cards.first?.id
    }

    func markSeen(_ id: String) {
        if lastCardID != id {
            lastCardID = id
            UserDefaults.standard.set(id, forKey: lastKey)
        }
        guard !seenIDs.contains(id) else { return }
        seenIDs.insert(id)
        persist(seenIDs, key: seenKey)
    }

    /// When the user is near the end of this cycle, silently append a reshuffled loop.
    @discardableResult
    func extendPlayOrderIfNeeded(currentID: String?) -> [DiscoveryCard] {
        guard let currentID, let index = playOrder.firstIndex(of: currentID) else { return [] }
        let remaining = playOrder.count - index - 1
        guard remaining <= 2 else { return [] }
        return appendShuffledCycle(avoiding: playOrder.last)
    }

    func extraCards(alreadyHave count: Int, avoiding lastID: String?) -> [DiscoveryCard] {
        if orderedCards.count > count {
            return Array(orderedCards.dropFirst(count))
        }
        return appendShuffledCycle(avoiding: lastID)
    }

    @discardableResult
    func appendShuffledCycle(avoiding lastID: String?) -> [DiscoveryCard] {
        let nextIDs = DiscoveryCatalog.interleavedIDs(avoiding: lastID)
        playOrder.append(contentsOf: nextIDs)
        persistPlayOrder()
        return nextIDs.compactMap { DiscoveryCatalog.card(id: $0) }
    }

    private func reconcilePlayOrder() {
        let catalogIDs = DiscoveryCatalog.cards.map(\.id)
        let known = Set(catalogIDs)
        playOrder = playOrder.filter { known.contains($0) }
        let missing = catalogIDs.filter { !Set(playOrder).contains($0) }
        if playOrder.isEmpty {
            playOrder = DiscoveryCatalog.interleavedIDs()
        } else if !missing.isEmpty {
            let currentIndex = lastCardID.flatMap { playOrder.firstIndex(of: $0) } ?? 0
            let alreadyPlayed = Array(playOrder.prefix(currentIndex + 1))
            let leftoverIDs = Array(playOrder.dropFirst(alreadyPlayed.count))
            let leftoverCards = leftoverIDs.compactMap { DiscoveryCatalog.card(id: $0) }
            let missingCards = missing.compactMap { DiscoveryCatalog.card(id: $0) }
            playOrder = alreadyPlayed + DiscoveryCatalog.interleavedIDs(
                from: leftoverCards + missingCards,
                avoiding: alreadyPlayed.last
            )
        }
        persistPlayOrder()
    }

    private func persistPlayOrder() {
        UserDefaults.standard.set(playOrder, forKey: playOrderKey)
    }

    func isLiked(_ id: String) -> Bool { likedIDs.contains(id) }
    func isSaved(_ id: String) -> Bool { savedIDs.contains(id) }

    func toggleLike(_ id: String) {
        if likedIDs.contains(id) { likedIDs.remove(id) } else { likedIDs.insert(id) }
        persist(likedIDs, key: likedKey)
    }

    func toggleSave(_ id: String) {
        if savedIDs.contains(id) { savedIDs.remove(id) } else { savedIDs.insert(id) }
        persist(savedIDs, key: savedKey)
    }

    private func persist(_ set: Set<String>, key: String) {
        UserDefaults.standard.set(Array(set), forKey: key)
    }

    private static func loadSet(_ key: String) -> Set<String> {
        Set((UserDefaults.standard.array(forKey: key) as? [String]) ?? [])
    }
}
