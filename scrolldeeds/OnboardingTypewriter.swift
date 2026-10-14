//
//  OnboardingTypewriter.swift
//  scrolldeeds
//
//  Character-by-character reveal for explanation pages (not question screens).
//

import SwiftUI

enum OnboardingTypewriter {

    static let charInterval: TimeInterval = 0.048
    static let linePause: TimeInterval = 0.28

    static func duration(lines: [String]) -> TimeInterval {
        var total: TimeInterval = 0
        for (index, line) in lines.enumerated() {
            total += Double(max(line.count, 1)) * charInterval
            if index < lines.count - 1 {
                total += linePause
            }
        }
        return total
    }

    static func prefix(_ text: String, count: Int) -> String {
        guard count > 0 else { return "" }
        if count >= text.count { return text }
        let end = text.index(text.startIndex, offsetBy: count)
        return String(text[..<end])
    }

    static func highlightedText(
        full: String,
        visibleCount: Int,
        highlight: String?,
        fontSize: CGFloat,
        weight: Font.Weight = .regular,
        highlightWeight: Font.Weight = .bold,
        caseInsensitive: Bool = false
    ) -> Text {
        let shown = prefix(full, count: visibleCount)
        let base = Font.system(size: fontSize, weight: weight, design: .rounded)
        let bold = Font.system(size: fontSize, weight: highlightWeight, design: .rounded)
        guard let rawHighlight = highlight, !rawHighlight.isEmpty else {
            return Text(shown).font(base).foregroundColor(AppTheme.textPrimary)
        }
        let options: String.CompareOptions = caseInsensitive ? [.caseInsensitive] : []
        guard let range = full.range(of: rawHighlight, options: options) else {
            return Text(shown).font(base).foregroundColor(AppTheme.textPrimary)
        }
        let highlightStart = full.distance(from: full.startIndex, to: range.lowerBound)
        let highlightEnd = full.distance(from: full.startIndex, to: range.upperBound)
        let vis = shown.count
        if vis <= highlightStart {
            return Text(shown).font(base).foregroundColor(AppTheme.textPrimary)
        }
        let before = prefix(full, count: min(vis, highlightStart))
        let matchLen = min(vis, highlightEnd) - highlightStart
        let match = prefix(String(full[range]), count: max(matchLen, 0))
        let after: String = {
            guard vis > highlightEnd else { return "" }
            return prefix(String(full[range.upperBound...]), count: vis - highlightEnd)
        }()
        var result = Text("")
        if !before.isEmpty {
            result = result + Text(before).font(base).foregroundColor(AppTheme.textPrimary)
        }
        if !match.isEmpty {
            result = result + Text(match).font(bold).foregroundColor(AppTheme.primary)
        }
        if !after.isEmpty {
            result = result + Text(after).font(base).foregroundColor(AppTheme.textPrimary)
        }
        return result
    }

    static func highlightedText(
        full: String,
        visibleCount: Int,
        highlights: [String],
        fontSize: CGFloat,
        weight: Font.Weight = .regular,
        highlightWeight: Font.Weight = .bold
    ) -> Text {
        let shown = prefix(full, count: visibleCount)
        let words = highlights.filter { !$0.isEmpty }
        let base = Font.system(size: fontSize, weight: weight, design: .rounded)
        let bold = Font.system(size: fontSize, weight: highlightWeight, design: .rounded)
        guard !words.isEmpty else {
            return Text(shown).font(base).foregroundColor(AppTheme.textPrimary)
        }

        var result = Text("")
        var remaining = shown[...]
        while !remaining.isEmpty {
            var earliest: (range: Range<String.Index>, word: String)?
            for word in words {
                if let range = remaining.range(of: word) {
                    if let current = earliest {
                        if range.lowerBound < current.range.lowerBound
                            || (range.lowerBound == current.range.lowerBound && word.count > current.word.count) {
                            earliest = (range, word)
                        }
                    } else {
                        earliest = (range, word)
                    }
                }
            }
            if let match = earliest {
                let before = String(remaining[..<match.range.lowerBound])
                if !before.isEmpty {
                    result = result + Text(before).font(base).foregroundColor(AppTheme.textPrimary)
                }
                result = result + Text(match.word).font(bold).foregroundColor(AppTheme.primary)
                remaining = remaining[match.range.upperBound...]
            } else {
                result = result + Text(String(remaining)).font(base).foregroundColor(AppTheme.textPrimary)
                break
            }
        }
        return result
    }
}

final class OnboardingTypewriterRunner {
    private var token = UUID()

    func cancel() {
        token = UUID()
    }

    func start(
        lines: [String],
        interval: TimeInterval = OnboardingTypewriter.charInterval,
        onCount: @escaping (Int, Int) -> Void,
        onComplete: @escaping () -> Void
    ) {
        let run = UUID()
        token = run
        HapticManager.shared.prepareTypewriter()
        for index in lines.indices {
            onCount(index, 0)
        }

        func typeLine(_ lineIndex: Int) {
            guard token == run else { return }
            if lineIndex >= lines.count {
                onComplete()
                return
            }
            let line = lines[lineIndex]
            if line.isEmpty {
                onCount(lineIndex, 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + OnboardingTypewriter.linePause) {
                    typeLine(lineIndex + 1)
                }
                return
            }

            func typeChar(_ count: Int) {
                guard token == run else { return }
                onCount(lineIndex, count)
                let index = line.index(line.startIndex, offsetBy: count - 1)
                HapticManager.shared.typewriterTick(character: line[index])
                if count >= line.count {
                    let pause = lineIndex == lines.count - 1 ? 0.06 : OnboardingTypewriter.linePause
                    DispatchQueue.main.asyncAfter(deadline: .now() + pause) {
                        typeLine(lineIndex + 1)
                    }
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                    typeChar(count + 1)
                }
            }

            typeChar(1)
        }

        typeLine(0)
    }
}
