//
//  KnowledgePracticeView.swift
//  scrolldeeds
//
//  Practice hub: quiz and flash cards over discovery cards the user has scrolled.
//

import Combine
import SwiftUI

@MainActor
final class PracticeProgressStore: ObservableObject {
    static let shared = PracticeProgressStore()

    @Published private(set) var answeredCount: Int
    @Published private(set) var correctCount: Int
    @Published private(set) var wrongCount: Int

    private let defaults = UserDefaults.standard
    private let answeredKey = "practice_answered_count"
    private let correctKey = "practice_correct_count"
    private let wrongKey = "practice_wrong_count"
    private let quizItemsKey = "practice_quiz_items"
    private let quizIndexKey = "practice_quiz_index"
    private let quizSessionCorrectKey = "practice_quiz_session_correct"
    private let quizSelectedKey = "practice_quiz_selected_id"
    private let quizStartedAtKey = "practice_quiz_started_at"
    private let quizReviewKey = "practice_quiz_review"
    private let quizDoneKey = "practice_quiz_done_ids"
    private let flashQueueKey = "practice_flash_queue"
    private let flashKnownKey = "practice_flash_session_known"
    private let flashUnknownKey = "practice_flash_session_unknown"
    private let flashStartedAtKey = "practice_flash_started_at"
    private let flashReviewKey = "practice_flash_review"
    private let flashDoneKey = "practice_flash_done_ids"

    private init() {
        answeredCount = max(0, defaults.integer(forKey: answeredKey))
        correctCount = max(0, defaults.integer(forKey: correctKey))
        wrongCount = max(0, defaults.integer(forKey: wrongKey))
    }

    func recordAnswer(correct: Bool) {
        answeredCount += 1
        if correct { correctCount += 1 } else { wrongCount += 1 }
        defaults.set(answeredCount, forKey: answeredKey)
        defaults.set(correctCount, forKey: correctKey)
        defaults.set(wrongCount, forKey: wrongKey)
    }

    func saveQuizSession(
        items: [SavedQuizItem],
        index: Int,
        sessionCorrect: Int,
        selectedID: String?,
        startedAt: TimeInterval,
        review: [SavedPracticeReview]
    ) {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: quizItemsKey)
        }
        defaults.set(index, forKey: quizIndexKey)
        defaults.set(sessionCorrect, forKey: quizSessionCorrectKey)
        defaults.set(startedAt, forKey: quizStartedAtKey)
        if let data = try? JSONEncoder().encode(review) {
            defaults.set(data, forKey: quizReviewKey)
        }
        if let selectedID {
            defaults.set(selectedID, forKey: quizSelectedKey)
        } else {
            defaults.removeObject(forKey: quizSelectedKey)
        }
    }

    func loadQuizSession() -> (
        items: [SavedQuizItem],
        index: Int,
        sessionCorrect: Int,
        selectedID: String?,
        startedAt: TimeInterval,
        review: [SavedPracticeReview]
    )? {
        guard let data = defaults.data(forKey: quizItemsKey),
              let items = try? JSONDecoder().decode([SavedQuizItem].self, from: data),
              !items.isEmpty else { return nil }
        let trimmed = Array(items.prefix(PracticeRound.size))
        let index = min(max(0, defaults.integer(forKey: quizIndexKey)), trimmed.count - 1)
        let reviewData = defaults.data(forKey: quizReviewKey)
        let review = reviewData.flatMap { try? JSONDecoder().decode([SavedPracticeReview].self, from: $0) } ?? []
        let startedAt = defaults.object(forKey: quizStartedAtKey) as? TimeInterval ?? Date().timeIntervalSince1970
        return (
            trimmed,
            index,
            defaults.integer(forKey: quizSessionCorrectKey),
            defaults.string(forKey: quizSelectedKey),
            startedAt,
            review
        )
    }

    func clearQuizSession() {
        defaults.removeObject(forKey: quizItemsKey)
        defaults.removeObject(forKey: quizIndexKey)
        defaults.removeObject(forKey: quizSessionCorrectKey)
        defaults.removeObject(forKey: quizSelectedKey)
        defaults.removeObject(forKey: quizStartedAtKey)
        defaults.removeObject(forKey: quizReviewKey)
    }

    func markQuizDone(_ id: String) {
        var done = loadSet(quizDoneKey)
        done.insert(id)
        persist(done, key: quizDoneKey)
    }

    func nextQuizCards(from seen: [DiscoveryCard], limit: Int = 10, avoiding: String? = nil) -> [DiscoveryCard] {
        var done = loadSet(quizDoneKey)
        var pool = seen.filter { !done.contains($0.id) }
        if pool.isEmpty {
            done = []
            persist(done, key: quizDoneKey)
            pool = seen
        }
        var next = Array(pool.shuffled().prefix(limit))
        if let avoiding, next.first?.id == avoiding, next.count > 1 {
            next.swapAt(0, Int.random(in: 1..<next.count))
        }
        return next
    }

    func saveFlashSession(
        queue: [String],
        known: Int,
        unknown: Int,
        startedAt: TimeInterval,
        review: [SavedPracticeReview]
    ) {
        defaults.set(queue, forKey: flashQueueKey)
        defaults.set(known, forKey: flashKnownKey)
        defaults.set(unknown, forKey: flashUnknownKey)
        defaults.set(startedAt, forKey: flashStartedAtKey)
        if let data = try? JSONEncoder().encode(review) {
            defaults.set(data, forKey: flashReviewKey)
        }
    }

    func loadFlashSession() -> (
        queue: [String],
        known: Int,
        unknown: Int,
        startedAt: TimeInterval,
        review: [SavedPracticeReview]
    )? {
        let queue = defaults.stringArray(forKey: flashQueueKey) ?? []
        guard !queue.isEmpty else { return nil }
        let known = max(0, defaults.integer(forKey: flashKnownKey))
        let unknown = max(0, defaults.integer(forKey: flashUnknownKey))
        let remaining = max(0, PracticeRound.size - known - unknown)
        let trimmed = Array(queue.prefix(remaining))
        guard !trimmed.isEmpty else { return nil }
        let reviewData = defaults.data(forKey: flashReviewKey)
        let review = reviewData.flatMap { try? JSONDecoder().decode([SavedPracticeReview].self, from: $0) } ?? []
        let startedAt = defaults.object(forKey: flashStartedAtKey) as? TimeInterval ?? Date().timeIntervalSince1970
        return (trimmed, known, unknown, startedAt, review)
    }

    func clearFlashSession() {
        defaults.removeObject(forKey: flashQueueKey)
        defaults.removeObject(forKey: flashKnownKey)
        defaults.removeObject(forKey: flashUnknownKey)
        defaults.removeObject(forKey: flashStartedAtKey)
        defaults.removeObject(forKey: flashReviewKey)
    }

    func markFlashDone(_ id: String) {
        var done = loadSet(flashDoneKey)
        done.insert(id)
        persist(done, key: flashDoneKey)
    }

    func nextFlashCards(from seen: [DiscoveryCard], avoiding: String? = nil) -> [DiscoveryCard] {
        var done = loadSet(flashDoneKey)
        var pool = seen.filter { !done.contains($0.id) }
        if pool.isEmpty {
            done = []
            persist(done, key: flashDoneKey)
            pool = seen
        }
        var next = Array(pool.shuffled().prefix(PracticeRound.size))
        if let avoiding, next.first?.id == avoiding, next.count > 1 {
            next.swapAt(0, Int.random(in: 1..<next.count))
        }
        return next
    }

    private func persist(_ set: Set<String>, key: String) {
        defaults.set(Array(set), forKey: key)
    }

    private func loadSet(_ key: String) -> Set<String> {
        Set((defaults.array(forKey: key) as? [String]) ?? [])
    }
}

struct SavedQuizItem: Codable {
    let cardID: String
    let optionIDs: [String]
}

struct SavedPracticeReview: Codable {
    let id: String
    let correct: Bool
}

private enum PracticeRound: Sendable {
    nonisolated static let size = 10
}

private struct PracticeReviewItem: Identifiable {
    let id: String
    let title: String
    let correct: Bool
}

private enum PracticeCloze {
    static let stop: Set<String> = [
        "the", "a", "an", "of", "and", "or", "to", "in", "on", "for", "with",
        "your", "you", "is", "at", "from", "this", "that", "its", "be",
        "de", "het", "een", "van", "en", "op", "te", "el", "la", "los", "las",
        "un", "una", "y", "le", "les", "des", "du", "et", "une", "der", "die",
        "das", "und", "ein", "im", "и", "в", "на", "с", "ال", "في", "من", "على", "و"
    ]

    static func prompt(for card: DiscoveryCard) -> (text: String, isArabic: Bool) {
        if let blanked = blanked(card.meaning, hiding: card.title), blanked != card.meaning {
            let arabic = blanked.unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) }
            return (blanked, arabic)
        }
        return ("", false)
    }

    private static func blanked(_ meaning: String, hiding title: String) -> String? {
        let tokens = title.split { !$0.isLetter && $0 != "'" && $0 != "’" && $0 != "-" }
            .map { String($0) }
            .filter { $0.count >= 3 && !stop.contains($0.lowercased()) }
            .sorted { $0.count > $1.count }
        guard !tokens.isEmpty else { return nil }
        var result = meaning
        var changed = false
        for token in tokens.prefix(2) {
            let updated = result.replacingOccurrences(
                of: token,
                with: "_____",
                options: [.caseInsensitive, .diacriticInsensitive]
            )
            if updated != result {
                result = updated
                changed = true
            }
        }
        return changed ? result : nil
    }
}

struct KnowledgePracticeView: View {
    var onScrollTap: () -> Void = {}

    @ObservedObject private var store = DiscoveryProgressStore.shared
    @ObservedObject private var practice = PracticeProgressStore.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var userDataManager = UserDataManager.shared
    @State private var showQuiz = false
    @State private var showFlash = false

    private var seen: [DiscoveryCard] { store.seenCards }
    private var practicePool: [DiscoveryCard] {
        seen
    }

    var body: some View {
        ZStack {
            SDPageBackground()
            VStack(spacing: 0) {
                header
                if seen.isEmpty {
                    emptyState
                } else {
                    activityList
                }
            }
        }
        .id(languageManager.languageEpoch)
        .fullScreenCover(isPresented: $showQuiz) {
            PracticeQuizSession(cards: practicePool, isPresented: $showQuiz)
        }
        .fullScreenCover(isPresented: $showFlash) {
            PracticeFlashIntro(cards: practicePool, isPresented: $showFlash)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            SDBrandHeader(buddy: "NafsiPoseReach") {
                SDStreakPill(streak: userDataManager.currentStreak)
            }
            Text(NSLocalizedString("practice.subtitle", comment: "Test what you learned while scrolling."))
                .font(AppTypography.body)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 12)
            PracticeStackedIllustration()
            VStack(spacing: 10) {
                Text(NSLocalizedString("practice.empty.title", comment: "Nothing to practice yet"))
                    .font(AppTypography.sectionTitle)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(NSLocalizedString("practice.empty.body", comment: "Scroll a few cards first."))
                    .font(AppTypography.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            Button(NSLocalizedString("practice.empty.cta", comment: "Go scroll"), action: onScrollTap)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private var activityList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                statsCard
                    .padding(.top, 8)

                activityCard(
                    systemName: "checkmark.circle",
                    title: NSLocalizedString("practice.quiz.title", comment: "Quiz"),
                    subtitle: NSLocalizedString("practice.quiz.subtitle", comment: "Fill the blank, then pick the title."),
                    action: { showQuiz = true }
                )
                activityCard(
                    systemName: "rectangle.stack",
                    title: NSLocalizedString("practice.flash.title", comment: "Flash cards"),
                    subtitle: NSLocalizedString("practice.flash.subtitle", comment: "See the title, recall the meaning."),
                    action: { showFlash = true }
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            statColumn(
                value: practice.answeredCount,
                label: NSLocalizedString("practice.stats.answered", comment: "Answered")
            )
            Rectangle()
                .fill(AppTheme.border.opacity(0.7))
                .frame(width: 1, height: 36)
            statColumn(
                value: practice.correctCount,
                label: NSLocalizedString("practice.stats.correct", comment: "Correct"),
                tint: AppTheme.success
            )
            Rectangle()
                .fill(AppTheme.border.opacity(0.7))
                .frame(width: 1, height: 36)
            statColumn(
                value: practice.wrongCount,
                label: NSLocalizedString("practice.stats.wrong", comment: "Wrong"),
                tint: AppTheme.error
            )
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func statColumn(value: Int, label: String, tint: Color = AppTheme.textPrimary) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(tint)
                .monospacedDigit()
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func activityCard(
        systemName: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticManager.shared.soft()
            action()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: systemName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppTheme.card)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PracticeStackedIllustration: View {
    var celebrating: Bool = false

    var body: some View {
        ZStack {
            if celebrating {
                confetti
                miniCard(color: AppTheme.card, rotation: -18)
                    .offset(x: -92, y: -28)
                miniCard(color: AppTheme.primary.opacity(0.28), rotation: 16)
                    .offset(x: 96, y: -22)
            }
            card(color: AppTheme.primary.opacity(0.22), rotation: 14)
                .offset(x: 22, y: 10)
            card(color: Color(red: 0.93, green: 0.78, blue: 0.74), rotation: -12)
                .offset(x: -18, y: 16)
            card(color: AppTheme.card, rotation: -4)
                .overlay(
                    VStack(spacing: 7) {
                        capsule
                        capsule.opacity(0.7)
                        capsule.frame(width: 42).opacity(0.45)
                    }
                    .padding(.horizontal, 22)
                )
        }
        .frame(width: celebrating ? 240 : 168, height: celebrating ? 168 : 128)
    }

    private var confetti: some View {
        ZStack {
            Capsule().fill(AppTheme.primary.opacity(0.55)).frame(width: 8, height: 18).rotationEffect(.degrees(-28)).offset(x: -10, y: -58)
            Capsule().fill(Color(red: 0.93, green: 0.78, blue: 0.74)).frame(width: 7, height: 16).rotationEffect(.degrees(22)).offset(x: 18, y: -62)
            Capsule().fill(AppTheme.primaryLight.opacity(0.9)).frame(width: 6, height: 14).rotationEffect(.degrees(40)).offset(x: 4, y: -48)
            Capsule().fill(AppTheme.accent.opacity(0.55)).frame(width: 6, height: 12).rotationEffect(.degrees(-50)).offset(x: 32, y: -44)
            Capsule().fill(AppTheme.primary.opacity(0.4)).frame(width: 5, height: 11).rotationEffect(.degrees(12)).offset(x: -34, y: -40)
        }
    }

    private func miniCard(color: Color, rotation: Double) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(color)
            .frame(width: 44, height: 36)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.textPrimary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
            .rotationEffect(.degrees(rotation))
    }

    private var capsule: some View {
        Capsule()
            .fill(AppTheme.primary.opacity(0.22))
            .frame(height: 6)
    }

    private func card(color: Color, rotation: Double) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(color)
            .frame(width: 92, height: 108)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.textPrimary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Quiz

private struct PracticeQuestion: Identifiable {
    let id: String
    let card: DiscoveryCard
    let options: [DiscoveryCard]
}

private struct PracticeQuizSession: View {
    let cards: [DiscoveryCard]
    @Binding var isPresented: Bool

    @ObservedObject private var practice = PracticeProgressStore.shared
    @State private var questions: [PracticeQuestion] = []
    @State private var index = 0
    @State private var selectedID: String?
    @State private var correctCount = 0
    @State private var finished = false
    @State private var scoredThisQuestion = false
    @State private var startedAt = Date()
    @State private var review: [PracticeReviewItem] = []

    private var question: PracticeQuestion? {
        guard questions.indices.contains(index) else { return nil }
        return questions[index]
    }

    private var answered: Bool { selectedID != nil }
    private var isCorrect: Bool { selectedID == question?.card.id }

    var body: some View {
        ZStack {
            SDPageBackground()
            if finished {
                PracticeResultView(
                    correct: correctCount,
                    total: max(questions.count, 1),
                    duration: Date().timeIntervalSince(startedAt),
                    review: review,
                    kind: .quiz,
                    onAgain: restart,
                    onDone: { isPresented = false }
                )
            } else if let question {
                VStack(spacing: 0) {
                    PracticeSessionBar(
                        progress: min(
                            1,
                            CGFloat(index + (answered ? 1 : 0)) / CGFloat(max(questions.count, PracticeRound.size))
                        ),
                        onClose: { isPresented = false }
                    )
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            promptCard(question.card)
                                .padding(.top, 12)
                            options(for: question)
                            if answered {
                                feedback(for: question)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .onAppear(perform: start)
    }

    private func promptCard(_ card: DiscoveryCard) -> some View {
        let prompt = PracticeCloze.prompt(for: card)
        return VStack(spacing: 14) {
            Text(card.kind.label.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(AppTheme.primary)

            if prompt.text.isEmpty {
                Text("_____")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.vertical, 8)
            } else {
                Text(prompt.text)
                    .font(.system(size: prompt.isArabic ? 22 : 18, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .environment(\.layoutDirection, prompt.isArabic ? .rightToLeft : .leftToRight)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: Color.black.opacity(0.06), radius: 16, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .padding(.horizontal, 8)
    }

    private func options(for question: PracticeQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(question.options) { option in
                Button {
                    choose(option, correct: question.card)
                } label: {
                    HStack(spacing: 10) {
                        if answered, option.id == question.card.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                        } else if answered, option.id == selectedID {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                        }
                        Text(option.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(optionForeground(option, correctID: question.card.id))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(Capsule(style: .continuous).fill(optionFill(option, correctID: question.card.id)))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(optionStroke(option, correctID: question.card.id), lineWidth: 1.2)
                    )
                }
                .disabled(answered)
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func feedback(for question: PracticeQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? AppTheme.success : AppTheme.error)
                Text(NSLocalizedString(
                    isCorrect ? "practice.quiz.correct" : "practice.quiz.incorrect",
                    comment: ""
                ))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            }
            if !isCorrect {
                Text(NSLocalizedString("practice.quiz.correct_answer", comment: "Correct answer:"))
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textMuted)
                Text(question.card.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            Text(question.card.meaning)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(NSLocalizedString("practice.quiz.source", comment: "Source:"))
                .font(AppTypography.caption)
                .foregroundColor(AppTheme.textMuted)
            Text(question.card.source)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            Button(NSLocalizedString("practice.quiz.next", comment: "Next"), action: advance)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
        )
    }

    private func optionFill(_ option: DiscoveryCard, correctID: String) -> Color {
        guard answered else { return AppTheme.card }
        if option.id == correctID { return AppTheme.success.opacity(0.22) }
        if option.id == selectedID { return AppTheme.error.opacity(0.22) }
        return AppTheme.card
    }

    private func optionStroke(_ option: DiscoveryCard, correctID: String) -> Color {
        guard answered else { return AppTheme.textPrimary.opacity(0.14) }
        if option.id == correctID { return AppTheme.success.opacity(0.55) }
        if option.id == selectedID { return AppTheme.error.opacity(0.55) }
        return AppTheme.border
    }

    private func optionForeground(_ option: DiscoveryCard, correctID: String) -> Color {
        guard answered else { return AppTheme.textPrimary }
        if option.id == correctID { return AppTheme.success }
        if option.id == selectedID { return AppTheme.error }
        return AppTheme.textMuted
    }

    private func choose(_ option: DiscoveryCard, correct: DiscoveryCard) {
        guard selectedID == nil else { return }
        HapticManager.shared.soft()
        selectedID = option.id
        let right = option.id == correct.id
        if right {
            correctCount += 1
        }
        if !scoredThisQuestion {
            scoredThisQuestion = true
            practice.recordAnswer(correct: right)
            practice.markQuizDone(correct.id)
            review.append(PracticeReviewItem(id: correct.id, title: correct.title, correct: right))
        }
        persistSession()
    }

    private func advance() {
        HapticManager.shared.soft()
        guard index + 1 < questions.count else {
            finished = true
            practice.clearQuizSession()
            return
        }
        index += 1
        selectedID = nil
        scoredThisQuestion = false
        persistSession()
    }

    private func start() {
        if restoreSession() { return }
        questions = PracticeQuizSession.buildQuestions(
            from: practice.nextQuizCards(from: cards, limit: PracticeRound.size)
        )
        index = 0
        selectedID = nil
        correctCount = 0
        finished = questions.isEmpty
        scoredThisQuestion = false
        startedAt = Date()
        review = []
        persistSession()
    }

    private func restart() {
        practice.clearQuizSession()
        start()
    }

    private func persistSession() {
        guard !finished, !questions.isEmpty else { return }
        let items = questions.map {
            SavedQuizItem(cardID: $0.card.id, optionIDs: $0.options.map(\.id))
        }
        practice.saveQuizSession(
            items: items,
            index: index,
            sessionCorrect: correctCount,
            selectedID: selectedID,
            startedAt: startedAt.timeIntervalSince1970,
            review: review.map { SavedPracticeReview(id: $0.id, correct: $0.correct) }
        )
    }

    private func restoreSession() -> Bool {
        guard let saved = practice.loadQuizSession() else { return false }
        let restored: [PracticeQuestion] = saved.items.compactMap { item in
            guard let card = DiscoveryCatalog.card(id: item.cardID) else { return nil }
            let options = item.optionIDs.compactMap { DiscoveryCatalog.card(id: $0) }
            guard options.count == item.optionIDs.count else { return nil }
            return PracticeQuestion(id: card.id, card: card, options: options)
        }
        guard restored.count == saved.items.count, !restored.isEmpty else {
            practice.clearQuizSession()
            return false
        }
        questions = restored
        index = min(saved.index, restored.count - 1)
        correctCount = min(saved.sessionCorrect, restored.count)
        selectedID = saved.selectedID
        scoredThisQuestion = saved.selectedID != nil
        startedAt = Date(timeIntervalSince1970: saved.startedAt)
        review = saved.review.compactMap { item in
            guard let card = DiscoveryCatalog.card(id: item.id) else { return nil }
            return PracticeReviewItem(id: card.id, title: card.title, correct: item.correct)
        }
        finished = false
        return true
    }

    static func buildQuestions(from deck: [DiscoveryCard]) -> [PracticeQuestion] {
        let pool = DiscoveryCatalog.cards
        return Array(deck.prefix(PracticeRound.size)).map { card in
            let distractors = pool.filter { $0.id != card.id }.shuffled().prefix(2)
            let options = ([card] + distractors).shuffled()
            return PracticeQuestion(id: card.id, card: card, options: Array(options))
        }
    }
}

// MARK: - Flash cards

private struct PracticeFlashIntro: View {
    let cards: [DiscoveryCard]
    @Binding var isPresented: Bool
    @State private var started = false

    var body: some View {
        ZStack {
            SDPageBackground()
            if started {
                PracticeFlashSession(cards: cards, isPresented: $isPresented)
            } else {
                intro
            }
        }
        .onAppear {
            if PracticeProgressStore.shared.loadFlashSession() != nil {
                started = true
            }
        }
    }

    private var intro: some View {
        VStack(spacing: 0) {
                    HStack {
                        PaywallCloseButton { isPresented = false }
                            .frame(width: 28, height: 28)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    Spacer()
                    PracticeStackedIllustration()
                    Text(NSLocalizedString("practice.flash.title", comment: "Flash cards"))
                        .font(AppTypography.display)
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.top, 28)
                        .padding(.bottom, 18)

                    VStack(alignment: .leading, spacing: 16) {
                        howToRow(
                            systemName: "rectangle.stack",
                            text: NSLocalizedString(
                                "practice.flash.howto.swipe",
                                comment: "Swipe left if you don’t know it, swipe right if you do"
                            )
                        )
                        howToRow(
                            systemName: "arrow.2.squarepath",
                            text: NSLocalizedString(
                                "practice.flash.howto.flip",
                                comment: "Tap to flip and check the meaning"
                            )
                        )
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .fill(AppTheme.card)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, y: 3)
                    )
                    .padding(.horizontal, 22)

                    Spacer()
                    Button(NSLocalizedString("practice.start", comment: "Start")) {
                        HapticManager.shared.soft()
                        started = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
        }
    }

    private func howToRow(systemName: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
            }
            Text(text)
                .font(AppTypography.body)
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PracticeFlashSession: View {
    let cards: [DiscoveryCard]
    @Binding var isPresented: Bool

    @ObservedObject private var practice = PracticeProgressStore.shared
    @State private var deck: [DiscoveryCard] = []
    @State private var known = 0
    @State private var unknown = 0
    @State private var isFlipped = false
    @State private var drag: CGFloat = 0
    @State private var finished = false
    @State private var startedAt = Date()
    @State private var review: [PracticeReviewItem] = []

    private var current: DiscoveryCard? { deck.first }

    var body: some View {
        ZStack {
            SDPageBackground()
            if finished {
                PracticeResultView(
                    correct: known,
                    total: max(known + unknown, 1),
                    duration: Date().timeIntervalSince(startedAt),
                    review: review,
                    kind: .flash,
                    onAgain: restart,
                    onDone: { isPresented = false }
                )
            } else {
                VStack(spacing: 0) {
                    PracticeSessionBar(
                        progress: min(
                            1,
                            CGFloat(known + unknown) / CGFloat(max(known + unknown + deck.count, PracticeRound.size))
                        ),
                        onClose: { isPresented = false }
                    )
                    scoreRow
                    Spacer(minLength: 8)
                    ZStack {
                        ForEach(Array(deck.dropFirst().prefix(2).enumerated()), id: \.element.id) { pair in
                            let depth = pair.offset + 1
                            flashCard(pair.element, isTop: false)
                                .offset(y: CGFloat(depth) * 10)
                                .scaleEffect(1 - CGFloat(depth) * 0.04)
                        }
                        if let current {
                            flashCard(current, isTop: true)
                        }
                    }
                    .padding(.horizontal, 28)
                    Spacer(minLength: 8)
                    Text(NSLocalizedString("practice.flash.hint", comment: "Swipe left if you don’t know it"))
                        .font(AppTypography.caption)
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.bottom, 22)
                }
            }
        }
        .onAppear(perform: start)
    }

    private var scoreRow: some View {
        HStack {
            scoreChip(systemName: "xmark", count: unknown, tint: AppTheme.error)
            Spacer()
            Text(String(
                format: NSLocalizedString("practice.flash.left", comment: "%d left in deck"),
                deck.count
            ))
            .font(AppTypography.caption)
            .foregroundColor(AppTheme.textMuted)
            Spacer()
            scoreChip(systemName: "checkmark", count: known, tint: AppTheme.success)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func scoreChip(systemName: String, count: Int, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(tint))
            Text("\(count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(AppTheme.card))
        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
    }

    @ViewBuilder
    private func flashCard(_ card: DiscoveryCard, isTop: Bool) -> some View {
        let rotation = isTop ? Double(drag / 18) : 0
        let cardView = RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(AppTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(AppTheme.textPrimary.opacity(0.12), lineWidth: 1.4)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)
            .overlay(cardFace(card).opacity(isTop ? 1 : 0))
            .frame(maxWidth: .infinity)
            .frame(height: 390)
            .offset(x: isTop ? drag : 0)
            .rotationEffect(.degrees(rotation))
            .onTapGesture {
                guard isTop else { return }
                HapticManager.shared.soft()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    isFlipped.toggle()
                }
            }

        if isTop {
            cardView.gesture(dragGesture)
        } else {
            cardView
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                drag = value.translation.width
            }
            .onEnded { value in
                if value.translation.width > 90 {
                    resolve(knew: true)
                } else if value.translation.width < -90 {
                    resolve(knew: false)
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                        drag = 0
                    }
                }
            }
    }

    @ViewBuilder
    private func cardFace(_ card: DiscoveryCard) -> some View {
        VStack(spacing: 14) {
            if isFlipped {
                Text(card.kind.label.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.primary)
                Text(card.meaning)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 22)
                Text(card.source)
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
            } else {
                Text(card.kind.label.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.primary)
                Text(card.title)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.55)
                    .padding(.horizontal, 20)
                Text(NSLocalizedString("practice.flash.think", comment: "Recall the meaning"))
                    .font(AppTypography.caption)
                    .foregroundColor(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .padding(22)
    }

    private func resolve(knew: Bool) {
        HapticManager.shared.soft()
        if let current {
            practice.markFlashDone(current.id)
            practice.recordAnswer(correct: knew)
            review.append(PracticeReviewItem(id: current.id, title: current.title, correct: knew))
        }
        if knew { known += 1 } else { unknown += 1 }
        withAnimation(.easeInOut(duration: 0.22)) {
            drag = knew ? 420 : -420
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            if !deck.isEmpty { deck.removeFirst() }
            drag = 0
            isFlipped = false
            if deck.isEmpty {
                finished = true
                practice.clearFlashSession()
            } else {
                persistSession()
            }
        }
    }

    private func start() {
        if restoreSession() { return }
        deck = practice.nextFlashCards(from: cards)
        known = 0
        unknown = 0
        isFlipped = false
        drag = 0
        finished = deck.isEmpty
        startedAt = Date()
        review = []
        persistSession()
    }

    private func restart() {
        practice.clearFlashSession()
        start()
    }

    private func persistSession() {
        guard !finished else { return }
        practice.saveFlashSession(
            queue: deck.map(\.id),
            known: known,
            unknown: unknown,
            startedAt: startedAt.timeIntervalSince1970,
            review: review.map { SavedPracticeReview(id: $0.id, correct: $0.correct) }
        )
    }

    private func restoreSession() -> Bool {
        guard let saved = practice.loadFlashSession() else { return false }
        let restored = saved.queue.compactMap { DiscoveryCatalog.card(id: $0) }
        guard !restored.isEmpty else {
            practice.clearFlashSession()
            return false
        }
        deck = restored
        known = saved.known
        unknown = saved.unknown
        isFlipped = false
        drag = 0
        finished = false
        startedAt = Date(timeIntervalSince1970: saved.startedAt)
        review = saved.review.compactMap { item in
            guard let card = DiscoveryCatalog.card(id: item.id) else { return nil }
            return PracticeReviewItem(id: card.id, title: card.title, correct: item.correct)
        }
        return true
    }
}

// MARK: - Shared chrome

private struct PracticeSessionBar: View {
    let progress: CGFloat
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Color.clear
                .frame(width: 28, height: 28)
                .overlay {
                    PaywallCloseButton(action: onClose)
                }
            Capsule()
                .fill(AppTheme.textMuted.opacity(0.16))
                .frame(height: 7)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(AppTheme.primary)
                            .frame(width: geo.size.width * min(1, max(0, progress)))
                    }
                }
                .clipShape(Capsule())
                .frame(maxWidth: .infinity)
                .frame(height: 7)
                .layoutPriority(1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

private struct PracticeResultView: View {
    enum Kind {
        case quiz
        case flash
    }

    let correct: Int
    let total: Int
    let duration: TimeInterval
    let review: [PracticeReviewItem]
    let kind: Kind
    let onAgain: () -> Void
    let onDone: () -> Void

    @State private var showingReview = false

    private var unknown: Int { max(0, total - correct) }

    var body: some View {
        if showingReview {
            reviewScreen
        } else {
            celebration
        }
    }

    private var celebration: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            PracticeStackedIllustration(celebrating: true)
                .padding(.bottom, 28)
            Text(NSLocalizedString("practice.done.title", comment: "All done!"))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 22)

            VStack(spacing: 10) {
                Text("\(correct)/\(total)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .monospacedDigit()
                Text(timingLine)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
                HStack(spacing: 18) {
                    resultChip(
                        systemName: "checkmark.circle.fill",
                        text: String(
                            format: NSLocalizedString("practice.done.known_count", comment: "%d known"),
                            correct
                        ),
                        tint: AppTheme.success
                    )
                    resultChip(
                        systemName: "xmark.circle.fill",
                        text: String(
                            format: NSLocalizedString("practice.done.unknown_count", comment: "%d not known"),
                            unknown
                        ),
                        tint: AppTheme.error
                    )
                }
                .padding(.top, 6)
            }
            .padding(.vertical, 26)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.card)
                    .shadow(color: Color.black.opacity(0.06), radius: 16, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .padding(.horizontal, 22)

            Spacer()
            Button {
                HapticManager.shared.soft()
                showingReview = true
            } label: {
                Text(NSLocalizedString("practice.done.see_results", comment: "See results"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 22)
            .padding(.bottom, 28)
        }
    }

    private var reviewScreen: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    HapticManager.shared.soft()
                    showingReview = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppTheme.card))
                        .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                Spacer()
                Text(NSLocalizedString("practice.done.review_title", comment: "Your answers"))
                    .font(AppTypography.sectionTitle)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(review.enumerated()), id: \.offset) { pair in
                        HStack(spacing: 12) {
                            Image(systemName: pair.element.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(pair.element.correct ? AppTheme.success : AppTheme.error)
                            Text(pair.element.title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            Text("\(pair.offset + 1)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .fill(AppTheme.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            VStack(spacing: 12) {
                Button(NSLocalizedString("practice.again", comment: "Practice again"), action: onAgain)
                    .buttonStyle(PrimaryButtonStyle())
                Button(NSLocalizedString("practice.done", comment: "Done"), action: onDone)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 28)
        }
    }

    private var timingLine: String {
        let key = kind == .quiz ? "practice.done.timing.quiz" : "practice.done.timing.flash"
        return String(format: NSLocalizedString(key, comment: "in %@"), formattedDuration)
    }

    private var formattedDuration: String {
        let seconds = max(0, Int(duration.rounded()))
        return String(
            format: NSLocalizedString("practice.done.duration", comment: "%dm %02ds"),
            seconds / 60,
            seconds % 60
        )
    }

    private func resultChip(systemName: String, text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

#Preview {
    KnowledgePracticeView()
}
