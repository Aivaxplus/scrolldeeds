import SwiftUI
import Combine
#if canImport(FamilyControls)
import FamilyControls
#endif

// MARK: - Onboarding Step Types

enum OnboardingStepType {
    case info(InfoStep)
    case reflection(ReflectionStep) // Multi-line reassurance with per-line fade (after Assalam)
    case prayerLock(PrayerLockStep) // "ScrollDeeds helps you put God first" – per-line fade + highlights
    case nameInput(NameInputStep)   // "What should we call you?" – first things first
    case considerThis(ConsiderThisStep) // "Alright [name], consider this..." – ScrollDeeds style
    case question(QuestionStep)
    case sliderQuestion(SliderQuestionStep) // NEW: Slider-based questions
    case ageSelection // NEW: Age picker
    case impactStats(ImpactStatsStep) // Screen time impact – continue CTA after copy lands, no back
    case planIntro(PlanIntroStep)     // "it doesn't have to be this way" –zelfde stijl als prayer-lock info pages
    /// Where the user heard about ScrollDeeds (before apps question); options list scrolls only.
    case referralSource
    case appSelection
    /// After app picker: how strict / consistent the system should feel (before CommitmentView).
    case difficultySelection
    case commitment(CommitmentStep)
    case visual(VisualStep) // Visual/Illustration screens
    /// Notification banner + deed icons + Dhikr press → leads into interactiveDemo
    case demoNotification
    case interactiveDemo // NEW: Interactive demo of the app
    /// Streak preview (after interactive demo “That’s how it works”)
    case streakPreview
    /// Reminder permission pitch — system prompt fires on Continue
    case allowNotifications
    /// “Almost done” + patience quote (Al-Baqarah 2:153)
    case patienceQuote
    /// Which apps consume most time — multi-select 3×3 icons
    case appIconPicker
    /// Earn reward by guiding other Muslims — in-app review popup on CTA
    case guideMuslims
}

/// Reflection step: question with one highlighted word (e.g. God/Allah) + reassurance lines, each fading in.
struct ReflectionStep {
    let title: String
    let titleHighlight: String?
    let lines: [String]
}

/// Prayer lock intro: multiple lines, each with optional highlighted word (e.g. "God first", "simple", "pray").
struct PrayerLockLine {
    let text: String
    let highlight: String?
}
struct PrayerLockStep {
    let lines: [PrayerLockLine]
    /// When true, show 6 deed icons (2×3) under the text — same chrome as prayer lock.
    var showDeedCards: Bool = false
    /// Indices after which a larger paragraph gap (26pt) is inserted. Default matches classic prayer-lock.
    var paragraphBreakAfterIndices: Set<Int> = [1, 3]
    /// Optional format key with `%@` for the user’s name — prepended as first line (highlighted).
    var nameGreetingFormatKey: String? = nil
    /// Optional custom continue CTA localization key (e.g. “Bismillah”).
    var ctaKey: String? = nil
    /// When set, hide CTA and auto-advance after this many seconds (finish if last step).
    var autoAdvanceAfterSeconds: Double? = nil
    /// Companion pose. Nil keeps the page as text only.
    var buddyPose: String? = nil
}

/// Name input step: subtitle, title, placeholder (e.g. "first things first", "what should we call you?", "enter your name").
struct NameInputStep {
    let subtitle: String
    let title: String
    let placeholder: String
}

/// Consider this step: "alright [name], consider this..." – shows after name input, ScrollDeeds style.
struct ConsiderThisStep {
    /// Localization key for format string with %@ placeholder for name (e.g. "questionnaire.consider_this.text").
    let formatKey: String
}

/// Impact stats: "[name], you'll spend 2.007 hours..." – na leeftijdsvraag, ScrollDeeds stijl, per-line fade, auto na 3s.
struct ImpactStatsStep {
    /// Zelfde structuur als PrayerLockStep; eerste regel heeft format string met %@ voor naam.
    let lines: [PrayerLockLine]
}

/// Plan intro: "it doesn't have to be this way" / "5 minutes for God" – na impact stats, ScrollDeeds stijl, zelfde animatie.
struct PlanIntroStep {
    let lines: [PrayerLockLine]
}

struct InfoStep {
    let icon: String
    let title: String
    let subtitle: String
    let features: [String]?
    let animationType: AnimationType
    var visualDemo: InfoVisualDemo? = nil

    enum AnimationType {
        case pulse
        case float
        case glow
        case shake
    }
}

enum InfoVisualDemo {
    case fajrPhotoAlarm
    case fajrSetup
    case widgetDesire
}

struct QuestionStep {
    let emoji: String
    /// Optional SF Symbol shown instead of `emoji` in the hero icon.
    var systemImage: String? = nil
    /// Storybook illustration in Assets (replaces emoji on question pages).
    var illustrationName: String? = nil
    let title: String
    let subtitle: String
    /// Localization keys, not resolved strings: analytics needs the key to report one
    /// canonical English label per answer regardless of the user's language.
    let optionKeys: [String]
    /// If the user picks this answer index, skip the immediately following step.
    var skipNextStepWhenAnswerIndex: Int? = nil
    /// Last option is “Other” and reveals a text field instead of auto-advancing.
    var allowsOtherText: Bool = false

    var options: [String] {
        optionKeys.map { NSLocalizedString($0, comment: "") }
    }

    var otherOptionIndex: Int? {
        allowsOtherText && !optionKeys.isEmpty ? optionKeys.count - 1 : nil
    }
}

struct SliderQuestionStep {
    let emoji: String
    /// Optional SF Symbol shown instead of `emoji` in the hero icon.
    var systemImage: String? = nil
    /// Storybook illustration in Assets (replaces emoji on slider pages).
    var illustrationName: String? = nil
    let title: String
    let subtitle: String
    let minValue: Int
    let maxValue: Int
    let defaultValue: Int
    let unit: String // "Hours", "Minutes", etc.
    /// When set, slider shows mood number + left/right labels (same chrome as hours).
    var moodLeftLabel: String? = nil
    var moodRightLabel: String? = nil
    /// If final value is greater than this, skip the immediately following step (e.g. 3 → skip on 4–5).
    var skipNextStepWhenValueAbove: Int? = nil

    var isMoodSlider: Bool { moodLeftLabel != nil && moodRightLabel != nil }
}

struct CommitmentStep {
    let icon: String
    let title: String
    let commitmentText: String
}

// NEW: Visual step for illustrations and mockups
struct VisualStep {
    let type: VisualType
    let title: String
    let subtitle: String
    
    enum VisualType {
        case phoneMockup       // Shows a phone with app icons
        case screenTimeStats   // Shows screen time statistics
        case transformationAfter  // After state
        case dhikrDemo         // Shows dhikr recitation demo
        case lockScreen        // Shows the lock screen mockup
        case unlockFlow        // Shows the unlock flow
        case dailyRoutine      // Shows daily routine comparison
    }
}

// Interactive Demo phases
enum DemoPhase {
    case lockedApps      // Show locked apps, tap mic to start
    case recording       // "Recording" dhikr
    case verifying       // AI verifying
    case coinsEarned     // Same +coins reward as a real deed
    case buyHearts       // Spend those coins on a heart
    case unlocked        // TikTok opens once a heart is bought
}

// MARK: - Main View

struct QuestionnaireView: View {
    let onFinished: () -> Void
    @ObservedObject var shieldManager: ShieldManager
    @ObservedObject var localStorage: LocalStorageManager
    @ObservedObject var userDataManager: UserDataManager
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var fajrAlarm = FajrAlarmManager.shared
    
    @State private var step: Int = 0
    @State private var answers: [Int: Int] = [:]
    @State private var otherAnswers: [Int: String] = [:]
    @FocusState private var otherInputFocused: Bool
    @State private var nameFocusWorkItem: DispatchWorkItem?
    @State private var keyboardOverlap: CGFloat = 0
    @State private var isAppPickerPresented: Bool = false
    @State private var showFamilyControlsDeniedAlert: Bool = false
    @State private var commitmentAccepted: [Int: Bool] = [:]
    @State private var sliderValues: [Int: Int] = [:] // Store slider values by step index
    @State private var selectedAge: Int? = nil // Store selected age
    
    // Interactive Demo states
    @State private var demoPhase: DemoPhase = .lockedApps
    @State private var demoReciteCount: Int = 0
    @State private var demoCompleted: Bool = false
    @State private var demoCoinsBalance: Int = 0
    @State private var demoHearts: Int = 0
    @State private var demoShowSuccess: Bool = false
    /// Wow-layer motion for the interactive demo (breath / ripples / unlock burst).
    @State private var demoLockBreath = false
    @State private var demoMicPulse = false
    @State private var demoHeartBeat: CGFloat = 1
    @State private var demoUnlockRing: CGFloat = 0.6
    @State private var demoUnlockBurst = false
    @State private var impactHeroVisible = false
    @State private var impactHeroScale: CGFloat = 0.7
    @State private var impactHeroYears: Int = 0
    @State private var impactIconsRevealed = 0
    @State private var impactCountedHours = 0
    @State private var impactCountedDays = 0
    @State private var impactStatsSequenceID = UUID()
    
    // Animation states (simplified for performance)
    @State private var animateContent = false
    @State private var animateOptions = false
    @State private var pulseAnimation = false
    
    // Info page staggered fade animation states
    @State private var infoIconVisible = false
    @State private var infoTitleVisible = false
    @State private var infoSubtitleVisible = false
    @State private var infoFeaturesVisible: [Int: Bool] = [:] // Track each feature individually
    @State private var infoAnimationComplete = false // Track if all animations are done
    @State private var joinReviewsVisible = false
    @State private var joinReviewPage = 0
    
    // Reflection step (attention/God page) per-line fade states
    @State private var reflectionTitleVisible = false
    @State private var reflectionLineVisible: [Int: Bool] = [:]
    @State private var reflectionAnimationComplete = false
    
    // Prayer lock step per-line fade states
    @State private var prayerLockLineVisible: [Int: Bool] = [:]
    @State private var prayerLockAnimationComplete = false
    @State private var prayerLockCardsVisible = false
    
    @State private var enteredName: String = ""
    @FocusState private var nameInputFocused: Bool
    
    @State private var nameInputSubtitleVisible = false
    @State private var nameInputTitleVisible = false
    @State private var nameInputFieldVisible = false
    @State private var considerThisVisible = false
    @State private var considerThisAnimationComplete = false
    @State private var considerThisAutoAdvanceWorkItem: DispatchWorkItem?
    @State private var impactStatsLineVisible: [Int: Bool] = [:]
    @State private var impactStatsAnimationComplete = false
    @State private var impactStatsAutoAdvanceWorkItem: DispatchWorkItem?
    @State private var prayerLockAutoAdvanceWorkItem: DispatchWorkItem?
    @State private var planIntroLineVisible: [Int: Bool] = [:]
    @State private var planIntroAnimationComplete = false
    @State private var typewriterRunner = OnboardingTypewriterRunner()
    @State private var narrativeTypedCount: [Int: Int] = [:]
    @State private var prayerLockDissolving = false
    @State private var allowNotificationsReady = false
    @State private var patienceQuoteReady = false
    @State private var guideMuslimsReady = false
    @State private var showGuideMuslimsReviewPopup = false
    /// After the in-app review sheet is shown (or cancelled), the next CTA leaves this page.
    @State private var didHandleGuideMuslimsReview = false
    @State private var selectedTimeApps: Set<String> = []
    @State private var appIconPickerRevealed = false
    @State private var spiritualTypesExpanded = false
    
    // Transition state - prevents rapid clicking
    @State private var isTransitioning = false
    /// Last page dissolves before the plan-loading canvas takes over.
    @State private var isHandingOff = false
    
    // Haptic feedback tracking
    @State private var previousStep: Int = -1
    @State private var lastProgressHaptic: CGFloat = 0
    @State private var hasTriggeredStepHaptic = false
    
    // Visual steps: weekly screen time + “You’re not alone” (staggered entrance)
    @State private var screenTimeChartRevealed = false
    @State private var screenTimeBarFill: CGFloat = 0
    @State private var screenTimeStatCardsRevealed = false
    @State private var screenTimeFooterRevealed = false
    @State private var notAloneCard0 = false
    @State private var notAloneCard1 = false
    @State private var notAloneCard2 = false
    @State private var notAloneQuoteRevealed = false
    @State private var notAloneBuddyRevealed = false
    
    /// "Your Life With ScrollDeeds" — staggered header, rows, subtitle; gates Continue until done
    @State private var afterLifeHeaderVisible = false
    @State private var afterLifeRow0 = false
    @State private var afterLifeRow1 = false
    @State private var afterLifeRow2 = false
    @State private var afterLifeRow3 = false
    @State private var afterLifeSubtitleVisible = false
    @State private var afterLifeAnimationComplete = false
    
    // Stagger pacing for narrative pages — shared with other onboarding beats
    private var narrativeDelayPerElement: Double { OnboardingFunnelConfig.narrativeDelayPerElement }
    private var narrativeFadeDuration: Double { OnboardingFunnelConfig.narrativeFadeDuration }
    private let narrativeRevealOffset: CGFloat = 3

    private func narrativeRevealAnimation(delay: Double) -> Animation {
        .easeInOut(duration: narrativeFadeDuration).delay(delay)
    }
    
    #if canImport(FamilyControls)
    @State private var appSelection = FamilyActivitySelection()
    #endif
    
    /// Stored in `UserDataManager.referralSource` — stable analytics values (order: friend → TikTok → … → other).
    private static let referralSourceSlugs: [String] = [
        "friend_family", "tiktok", "instagram", "youtube", "facebook", "appstore", "other"
    ]
    
    // MARK: - Onboarding Steps (visuals, tutorials & questions)
    
    /// Full catalog — DO NOT delete entries. Visibility/order via `OnboardingFunnelConfig`.
    private let stepCatalog: [(id: String, step: OnboardingStepType)] = [
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 1: WELCOME & HOOK
        // ═══════════════════════════════════════════════════════════════
        
        ("welcome", .info(InfoStep(
            icon: "moon.stars.fill",
            title: NSLocalizedString("questionnaire.welcome.title", comment: "Welcome title"),
            subtitle: NSLocalizedString("questionnaire.welcome.subtitle", comment: "Welcome subtitle"),
            features: nil,
            animationType: .glow
        ))),
        
        // Benefits intro — same PrayerLock chrome as “ScrollDeeds helpt je…”, plus 6 deed icons
        ("benefits_reflection", .prayerLock(PrayerLockStep(
            lines: [
                PrayerLockLine(
                    text: NSLocalizedString("benefits.reflection.line1", comment: ""),
                    highlight: NSLocalizedString("benefits.reflection.highlight.allah", comment: "Allah")
                ),
                PrayerLockLine(
                    text: NSLocalizedString("benefits.reflection.line1b", comment: ""),
                    highlight: NSLocalizedString("benefits.reflection.highlight.muslims", comment: "Muslims")
                ),
                PrayerLockLine(
                    text: NSLocalizedString("benefits.reflection.line2", comment: ""),
                    highlight: NSLocalizedString("benefits.reflection.highlight.preserve", comment: "")
                )
            ],
            showDeedCards: true,
            paragraphBreakAfterIndices: [1],
            buddyPose: "NafsiPoseOffer"
        ))),

        // Notification preview → Dhikr press → interactive demo (ScrollDeeds style)
        ("demo_notification", .demoNotification),

        // Assalam + Sabri intro (benefits / prayer-lock chrome) — after streak, before questions
        ("sabri_intro", .prayerLock(PrayerLockStep(
            lines: [
                PrayerLockLine(
                    text: NSLocalizedString("onboarding.sabri.line1", comment: "Assalamu alaikum,"),
                    highlight: nil
                ),
                PrayerLockLine(
                    text: NSLocalizedString("onboarding.sabri.line2", comment: "I'm Sabri!"),
                    highlight: NSLocalizedString("onboarding.sabri.highlight", comment: "Sabri")
                ),
                PrayerLockLine(
                    text: NSLocalizedString("onboarding.sabri.line3", comment: "I'll ask a few questions"),
                    highlight: NSLocalizedString("onboarding.sabri.highlight.questions", comment: "")
                ),
                PrayerLockLine(
                    text: NSLocalizedString("onboarding.sabri.line4", comment: "to personalize your experience."),
                    highlight: NSLocalizedString("onboarding.sabri.highlight.personalize", comment: "")
                )
            ],
            paragraphBreakAfterIndices: [1],
            buddyPose: "NafsiPoseStand"
        ))),
        
        // Same chrome as “ScrollDeeds helpt je…” (prayerLock); name greeting prepended at render time
        ("reflection", .prayerLock(PrayerLockStep(
            lines: [
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.attention_god.title", comment: "Phone more attention than Allah"),
                    highlight: NSLocalizedString("questionnaire.attention_god.highlight", comment: "Allah")
                ),
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.attention_god.line1", comment: "You're not alone"),
                    highlight: nil
                ),
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.attention_god.line2", comment: "Distractions everywhere"),
                    highlight: nil
                ),
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.attention_god.line3", comment: "Pull muslims away"),
                    highlight: NSLocalizedString("questionnaire.attention_god.line3_highlight", comment: "muslims")
                ),
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.attention_god.line4", comment: "What really matters"),
                    highlight: nil
                )
            ],
            paragraphBreakAfterIndices: [0, 1],
            nameGreetingFormatKey: "questionnaire.attention_god.name_greeting",
            buddyPose: "NafsiPoseSit"
        ))),
        
        ("prayer_lock", .prayerLock(PrayerLockStep(
            lines: [
                PrayerLockLine(text: NSLocalizedString("questionnaire.prayer_lock.line1", comment: ""), highlight: NSLocalizedString("questionnaire.prayer_lock.line1_highlight", comment: "")),
                PrayerLockLine(text: NSLocalizedString("questionnaire.prayer_lock.line2", comment: ""), highlight: NSLocalizedString("questionnaire.prayer_lock.line2_highlight", comment: "")),
                PrayerLockLine(text: NSLocalizedString("questionnaire.prayer_lock.line3", comment: ""), highlight: NSLocalizedString("questionnaire.prayer_lock.line3_highlight", comment: "")),
                PrayerLockLine(text: NSLocalizedString("questionnaire.prayer_lock.line4", comment: ""), highlight: NSLocalizedString("questionnaire.prayer_lock.line4_highlight", comment: "")),
                PrayerLockLine(text: NSLocalizedString("questionnaire.prayer_lock.line5", comment: ""), highlight: NSLocalizedString("questionnaire.prayer_lock.line5_highlight", comment: "")),
                PrayerLockLine(text: NSLocalizedString("questionnaire.prayer_lock.line6", comment: ""), highlight: NSLocalizedString("questionnaire.prayer_lock.line6_highlight", comment: ""))
            ],
            paragraphBreakAfterIndices: [1, 3, 4],
            buddyPose: "NafsiPoseStand"
        ))),
        
        ("name", .nameInput(NameInputStep(
            subtitle: NSLocalizedString("questionnaire.name_input.subtitle", comment: "First things first"),
            title: NSLocalizedString("questionnaire.name_input.title", comment: "What should we call you?"),
            placeholder: NSLocalizedString("questionnaire.name_input.placeholder", comment: "Enter your name")
        ))),
        
        ("consider_this", .considerThis(ConsiderThisStep(formatKey: "questionnaire.consider_this.text"))),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 2: PROBLEM CONFIRMATION
        // ═══════════════════════════════════════════════════════════════

        ("intention", .question(QuestionStep(
            emoji: "🤍",
            illustrationName: "OnboardingQIntention",
            title: NSLocalizedString("questionnaire.intention.title", comment: "Intention question"),
            subtitle: NSLocalizedString("questionnaire.intention.subtitle", comment: "Intention subtitle"),
            optionKeys: [
                "questionnaire.intention.option1",
                "questionnaire.intention.option2",
                "questionnaire.intention.option3",
                "questionnaire.intention.option4",
                "questionnaire.intention.option5"
            ]
        ))),
        
        ("screen_time", .sliderQuestion(SliderQuestionStep(
            emoji: "⏳",
            illustrationName: "OnboardingQScreenTime",
            title: NSLocalizedString("questionnaire.screen_time.title", comment: "Screen time question"),
            subtitle: NSLocalizedString("questionnaire.screen_time.subtitle", comment: "Screen time subtitle"),
            minValue: 0,
            maxValue: 12,
            defaultValue: 3,
            unit: NSLocalizedString("questionnaire.screen_time.unit", comment: "Hours")
        ))),
        
        ("age", .ageSelection),
        
        ("impact_stats", .impactStats(ImpactStatsStep(lines: [
            PrayerLockLine(text: NSLocalizedString("questionnaire.impact_stats.line1", comment: ""), highlight: NSLocalizedString("questionnaire.impact_stats.line1_highlight", comment: "")),
            PrayerLockLine(text: NSLocalizedString("questionnaire.impact_stats.line2", comment: ""), highlight: NSLocalizedString("questionnaire.impact_stats.line2_highlight", comment: "")),
            PrayerLockLine(text: NSLocalizedString("questionnaire.impact_stats.line3", comment: ""), highlight: NSLocalizedString("questionnaire.impact_stats.line3_highlight", comment: "")),
            PrayerLockLine(text: NSLocalizedString("questionnaire.impact_stats.line4", comment: ""), highlight: NSLocalizedString("questionnaire.impact_stats.line4_highlight", comment: "")),
            PrayerLockLine(text: NSLocalizedString("questionnaire.impact_stats.line5", comment: ""), highlight: nil),
            PrayerLockLine(text: NSLocalizedString("questionnaire.impact_stats.line6", comment: ""), highlight: nil),
            PrayerLockLine(text: NSLocalizedString("questionnaire.impact_stats.line7", comment: ""), highlight: NSLocalizedString("questionnaire.impact_stats.line7_highlight", comment: ""))
        ]))),
        
        ("plan_intro", .planIntro(PlanIntroStep(lines: [
            PrayerLockLine(text: NSLocalizedString("questionnaire.plan_intro.line1", comment: ""), highlight: nil),
            PrayerLockLine(text: NSLocalizedString("questionnaire.plan_intro.line2", comment: ""), highlight: NSLocalizedString("questionnaire.plan_intro.line2_highlight", comment: "")),
            PrayerLockLine(text: NSLocalizedString("questionnaire.plan_intro.line3", comment: ""), highlight: NSLocalizedString("questionnaire.plan_intro.line3_highlight", comment: ""))
            // line4 "let's build a plan for you" hidden — keys remain in Localizable.strings
        ]))),
        
        ("referral_source", .referralSource),
        
        // Legacy text options hidden — icon grid is the live step (keys remain in strings).
        // ("apps_consume_text", .question(...))
        ("apps_consume", .appIconPicker),
        
        ("stats_average_person", .visual(VisualStep(
            type: .screenTimeStats,
            title: NSLocalizedString("questionnaire.stats.title", comment: "Stats title"),
            subtitle: NSLocalizedString("questionnaire.stats.subtitle", comment: "Stats subtitle")
        ))),
        
        ("control", .question(QuestionStep(
            emoji: "✋",
            illustrationName: "OnboardingQControl",
            title: NSLocalizedString("questionnaire.control.title", comment: "Control question"),
            subtitle: NSLocalizedString("questionnaire.control.subtitle", comment: "Control subtitle"),
            optionKeys: [
                "questionnaire.control.option_yes",
                "questionnaire.control.option_sometimes",
                "questionnaire.control.option_no"
            ]
        ))),

        ("tried_stop", .question(QuestionStep(
            emoji: "🔄",
            illustrationName: "OnboardingQTriedStop",
            title: NSLocalizedString("questionnaire.tried_stop.title", comment: "What have you already tried?"),
            subtitle: NSLocalizedString("questionnaire.tried_stop.subtitle", comment: "Screen Time, deleting apps, a promise..."),
            optionKeys: [
                "questionnaire.tried_stop.option1",
                "questionnaire.tried_stop.option2",
                "questionnaire.tried_stop.option3",
                "questionnaire.tried_stop.option4",
                "questionnaire.other"
            ],
            allowsOtherText: true
        ))),

        ("chances", .question(QuestionStep(
            emoji: "🎯",
            illustrationName: "OnboardingQChances",
            title: NSLocalizedString("questionnaire.chances.title", comment: "How many chances have you already given yourself?"),
            subtitle: NSLocalizedString("questionnaire.chances.subtitle", comment: "Every time you thought: this time it’s different..."),
            optionKeys: [
                "questionnaire.chances.option1",
                "questionnaire.chances.option2",
                "questionnaire.chances.option3",
                "questionnaire.chances.option4"
            ]
        ))),

        ("barrier", .question(QuestionStep(
            emoji: "🧱",
            illustrationName: "OnboardingQBarrier",
            title: NSLocalizedString("questionnaire.barrier.title", comment: "What is stopping you from stopping?"),
            subtitle: NSLocalizedString("questionnaire.barrier.subtitle", comment: "Be honest. What usually wins?"),
            optionKeys: [
                "questionnaire.barrier.option1",
                "questionnaire.barrier.option2",
                "questionnaire.barrier.option3",
                "questionnaire.barrier.option4",
                "questionnaire.other"
            ],
            allowsOtherText: true
        ))),

        ("extra_minutes", .question(QuestionStep(
            emoji: "⏰",
            illustrationName: "OnboardingQExtraMinutes",
            title: NSLocalizedString("questionnaire.extra_minutes.title", comment: "What would you do with 30 extra minutes a day?"),
            subtitle: NSLocalizedString("questionnaire.extra_minutes.subtitle", comment: "If you got that time back, every day..."),
            optionKeys: [
                "questionnaire.extra_minutes.option1",
                "questionnaire.extra_minutes.option2",
                "questionnaire.extra_minutes.option3",
                "questionnaire.extra_minutes.option4",
                "questionnaire.other"
            ],
            allowsOtherText: true
        ))),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 3: PAIN AMPLIFICATION
        // ═══════════════════════════════════════════════════════════════
        
        // Legacy multi-choice feeling options remain in Localizable.strings (hidden).
        ("feeling", .sliderQuestion(SliderQuestionStep(
            emoji: "😔",
            title: NSLocalizedString("questionnaire.mood_after.title", comment: "How do you feel after scrolling?"),
            subtitle: NSLocalizedString("questionnaire.mood_after.subtitle", comment: "Be honest with yourself"),
            minValue: 1,
            maxValue: 5,
            defaultValue: 3,
            unit: "",
            moodLeftLabel: NSLocalizedString("questionnaire.mood_after.left", comment: "Guilty"),
            moodRightLabel: NSLocalizedString("questionnaire.mood_after.right", comment: "Super happy"),
            // Half or below (1–3) → show not_alone; above half (4–5) → skip it
            skipNextStepWhenValueAbove: 3
        ))),
        
        ("not_alone", .visual(VisualStep(
            type: .dailyRoutine,
            title: NSLocalizedString("questionnaire.not_alone.title", comment: "Not alone title"),
            subtitle: NSLocalizedString("questionnaire.not_alone.subtitle", comment: "Not alone subtitle")
        ))),

        ("late_night", .question(QuestionStep(
            emoji: "🌙",
            illustrationName: "OnboardingQLateNight",
            title: NSLocalizedString("questionnaire.late_night.title", comment: "Late night scrolling question"),
            subtitle: NSLocalizedString("questionnaire.late_night.subtitle", comment: "Late night scrolling subtitle"),
            optionKeys: [
                "questionnaire.late_night.option_yes",
                "questionnaire.late_night.option_no"
            ]
        ))),

        ("honest_thanks", .prayerLock(PrayerLockStep(
            lines: [
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.honest_thanks.line1", comment: "thank you for being honest with me."),
                    highlight: NSLocalizedString("questionnaire.honest_thanks.highlight.honest", comment: "honest")
                ),
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.honest_thanks.line2", comment: "Your journey to become a more powerful Muslim"),
                    highlight: NSLocalizedString("questionnaire.honest_thanks.highlight.powerful", comment: "more powerful Muslim")
                ),
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.honest_thanks.line3", comment: "starts right here and now, in sha Allah."),
                    highlight: NSLocalizedString("questionnaire.honest_thanks.highlight.inshaallah", comment: "in sha Allah")
                )
            ],
            paragraphBreakAfterIndices: [1],
            nameGreetingFormatKey: "questionnaire.honest_thanks.name_greeting",
            ctaKey: "questionnaire.honest_thanks.cta",
            buddyPose: "NafsiPoseSit"
        ))),
        
        ("stop_scrolling", .question(QuestionStep(
            emoji: "🔄",
            title: NSLocalizedString("questionnaire.stop_scrolling.title", comment: "Stop scrolling question"),
            subtitle: NSLocalizedString("questionnaire.stop_scrolling.subtitle", comment: "Stop scrolling subtitle"),
            optionKeys: [
                "questionnaire.stop_scrolling.option_yes",
                "questionnaire.stop_scrolling.option_no"
            ],
            // “Nee” → skip “we've all been there”; “Ja” continues normally
            skipNextStepWhenAnswerIndex: 1
        ))),

        // Relief after stop-scrolling — same PrayerLock / benefits chrome
        ("been_there", .prayerLock(PrayerLockStep(
            lines: [
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.been_there.line1", comment: "we've all been there"),
                    highlight: NSLocalizedString("questionnaire.been_there.line1_highlight", comment: "")
                ),
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.been_there.line2", comment: "that doesn't make you a bad muslim"),
                    highlight: NSLocalizedString("questionnaire.been_there.line2_highlight", comment: "bad muslim")
                ),
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.been_there.line3", comment: "you just need a reminder"),
                    highlight: NSLocalizedString("questionnaire.been_there.line3_highlight", comment: "reminder")
                )
            ],
            paragraphBreakAfterIndices: [0],
            buddyPose: "NafsiPoseWatch"
        ))),

        ("reminder_need", .question(QuestionStep(
            emoji: "🔔",
            illustrationName: "OnboardingQReminderNeed",
            title: NSLocalizedString("questionnaire.reminder_need.title", comment: "Reminder need question"),
            subtitle: NSLocalizedString("questionnaire.reminder_need.subtitle", comment: "Reminder need subtitle"),
            optionKeys: [
                "questionnaire.reminder_need.option1",
                "questionnaire.reminder_need.option2",
                "questionnaire.reminder_need.option3",
                "questionnaire.reminder_need.option4"
            ]
        ))),
        
        ("allow_notifications", .allowNotifications),

        ("daily_reminder_count", .sliderQuestion(SliderQuestionStep(
            emoji: "🔔",
            systemImage: "bell.badge.fill",
            title: NSLocalizedString("questionnaire.daily_reminder_count.title", comment: "Daily reminder count"),
            subtitle: NSLocalizedString("questionnaire.daily_reminder_count.subtitle", comment: "Daily reminder count subtitle"),
            minValue: NotificationManager.minDailySpiritualCount,
            maxValue: NotificationManager.maxDailySpiritualCount,
            defaultValue: NotificationManager.shared.dailySpiritualCount,
            unit: NSLocalizedString("questionnaire.daily_reminder_count.unit", comment: "per day")
        ))),
        
        ("patience_quote", .patienceQuote),
        
        ("fajr", .question(QuestionStep(
            emoji: "🌄",
            illustrationName: "OnboardingQFajr",
            title: NSLocalizedString("questionnaire.fajr.title", comment: "Fajr question"),
            subtitle: NSLocalizedString("questionnaire.fajr.subtitle", comment: "Fajr subtitle"),
            optionKeys: [
                "questionnaire.fajr.option1",
                "questionnaire.fajr.option2",
                "questionnaire.fajr.option3",
                "questionnaire.fajr.option4"
            ],
            skipNextStepWhenAnswerIndex: 0
        ))),

        ("fajr_wake", .info(InfoStep(
            icon: "sun.horizon.fill",
            title: NSLocalizedString("questionnaire.fajr_wake.title", comment: "Fajr wake title"),
            subtitle: NSLocalizedString("questionnaire.fajr_wake.subtitle", comment: "Fajr wake subtitle"),
            features: [
                NSLocalizedString("questionnaire.fajr_wake.feature1", comment: ""),
                NSLocalizedString("questionnaire.fajr_wake.feature2", comment: ""),
                NSLocalizedString("questionnaire.fajr_wake.feature3", comment: "")
            ],
            animationType: .glow,
            visualDemo: .fajrPhotoAlarm
        ))),

        ("fajr_setup", .info(InfoStep(
            icon: "alarm.fill",
            title: NSLocalizedString("questionnaire.fajr_setup.title", comment: "Set Fajr alarm"),
            subtitle: NSLocalizedString("questionnaire.fajr_setup.subtitle", comment: "Optional"),
            features: nil,
            animationType: .glow,
            visualDemo: .fajrSetup
        ))),
        
        ("prayers", .question(QuestionStep(
            emoji: "🤲",
            illustrationName: "OnboardingQPrayers",
            title: NSLocalizedString("questionnaire.prayers.title", comment: "Prayers question"),
            subtitle: NSLocalizedString("questionnaire.prayers.subtitle", comment: "Prayers subtitle"),
            optionKeys: [
                "questionnaire.prayers.option1",
                "questionnaire.prayers.option2",
                "questionnaire.prayers.option3",
                "questionnaire.prayers.option4"
            ]
        ))),
        
        ("not_lack_iman", .info(InfoStep(
            icon: "heart.fill",
            title: NSLocalizedString("questionnaire.not_lack_iman.title", comment: "Not lack of iman title"),
            subtitle: NSLocalizedString("questionnaire.not_lack_iman.subtitle", comment: "Not lack of iman subtitle"),
            features: nil,
            animationType: .glow
        ))),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 4: FIRST COMMITMENT
        // ═══════════════════════════════════════════════════════════════
        
        ("acknowledge", .commitment(CommitmentStep(
            icon: "checkmark.circle.fill",
            title: NSLocalizedString("questionnaire.acknowledge.title", comment: "Acknowledge title"),
            commitmentText: NSLocalizedString("questionnaire.acknowledge.commitment", comment: "Acknowledge commitment")
        ))),
        
        ("brave", .info(InfoStep(
            icon: "hands.clap.fill",
            title: NSLocalizedString("questionnaire.brave.title", comment: "Brave title"),
            subtitle: NSLocalizedString("questionnaire.brave.subtitle", comment: "Brave subtitle"),
            features: nil,
            animationType: .glow
        ))),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 5: PERSONAL CONTEXT
        // ═══════════════════════════════════════════════════════════════
        
        ("tried_before", .question(QuestionStep(
            emoji: "💪",
            title: NSLocalizedString("questionnaire.tried_before.title", comment: "Tried before question"),
            subtitle: NSLocalizedString("questionnaire.tried_before.subtitle", comment: "Tried before subtitle"),
            optionKeys: [
                "questionnaire.tried_before.option1",
                "questionnaire.tried_before.option2",
                "questionnaire.tried_before.option3",
                "questionnaire.tried_before.option4"
            ]
        ))),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 6: TUTORIAL - HOW IT WORKS (WITH VISUALS)
        // ═══════════════════════════════════════════════════════════════
        
        ("better_way", .info(InfoStep(
            icon: "wand.and.stars",
            title: NSLocalizedString("questionnaire.better_way.title", comment: "Better way title"),
            subtitle: NSLocalizedString("questionnaire.better_way.subtitle", comment: "Better way subtitle"),
            features: nil,
            animationType: .glow
        ))),
        
        ("how_works", .info(InfoStep(
            icon: "lock.shield.fill",
            title: NSLocalizedString("questionnaire.how_works.title", comment: "How works title"),
            subtitle: NSLocalizedString("questionnaire.how_works.subtitle", comment: "How works subtitle"),
            features: nil,
            animationType: .float
        ))),
        
        ("interactive_demo", .interactiveDemo),
        
        ("streak_preview", .streakPreview),

        ("widget_distraction", .question(QuestionStep(
            emoji: "📱",
            illustrationName: "OnboardingQDistraction",
            title: NSLocalizedString("questionnaire.widget_distraction.title", comment: "Does distraction grab you before you even open an app?"),
            subtitle: NSLocalizedString("questionnaire.widget_distraction.subtitle", comment: "Your Home Screen alone: icons, notifications, apps pulling you away."),
            optionKeys: [
                "questionnaire.widget_distraction.option1",
                "questionnaire.widget_distraction.option2",
                "questionnaire.widget_distraction.option3",
                "questionnaire.widget_distraction.option4"
            ],
            skipNextStepWhenAnswerIndex: 0
        ))),

        ("widget_desire", .info(InfoStep(
            icon: "square.stack.fill",
            title: NSLocalizedString("questionnaire.widget_desire.title", comment: "Nafsi puts a verse on your Home Screen"),
            subtitle: NSLocalizedString("questionnaire.widget_desire.subtitle", comment: "Every unlock, an ayah, du'a or hadith — before any app can pull you in."),
            features: [
                NSLocalizedString("questionnaire.widget_desire.feature1", comment: ""),
                NSLocalizedString("questionnaire.widget_desire.feature2", comment: ""),
                NSLocalizedString("questionnaire.widget_desire.feature3", comment: "")
            ],
            animationType: .glow,
            visualDemo: .widgetDesire
        ))),
        
        ("magic", .info(InfoStep(
            icon: "sparkles",
            title: NSLocalizedString("questionnaire.magic.title", comment: "Magic title"),
            subtitle: NSLocalizedString("questionnaire.magic.subtitle", comment: "Magic subtitle"),
            features: nil,
            animationType: .glow
        ))),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 9: SOCIAL PROOF
        // ═══════════════════════════════════════════════════════════════
        
        ("transformation_after", .visual(VisualStep(
            type: .transformationAfter,
            title: NSLocalizedString("questionnaire.after.title", comment: "After title"),
            subtitle: NSLocalizedString("questionnaire.after.subtitle", comment: "After subtitle")
        ))),
        
        ("join", .info(InfoStep(
            icon: "person.3.sequence.fill",
            title: NSLocalizedString("questionnaire.join.title", comment: "Join title"),
            subtitle: NSLocalizedString("questionnaire.join.subtitle", comment: "Join subtitle"),
            features: nil,
            animationType: .pulse
        ))),

        ("guide_muslims", .guideMuslims),

        ("life_change", .prayerLock(PrayerLockStep(
            lines: [
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.life_change.line1", comment: "this can really change your life"),
                    highlight: NSLocalizedString("questionnaire.life_change.highlight.change", comment: "change your life")
                ),
                PrayerLockLine(
                    text: NSLocalizedString("questionnaire.life_change.line2", comment: "if you take this seriously."),
                    highlight: NSLocalizedString("questionnaire.life_change.highlight.serious", comment: "seriously")
                )
            ],
            paragraphBreakAfterIndices: [],
            nameGreetingFormatKey: "questionnaire.life_change.name_greeting",
            autoAdvanceAfterSeconds: OnboardingFunnelConfig.lifeChangeAutoAdvanceSeconds
        ))),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 10: FINAL QUESTION
        // ═══════════════════════════════════════════════════════════════
        
        ("committed_question", .question(QuestionStep(
            emoji: "🔥",
            title: NSLocalizedString("questionnaire.committed.title", comment: "Committed question"),
            subtitle: NSLocalizedString("questionnaire.committed.subtitle", comment: "Committed subtitle"),
            optionKeys: [
                "questionnaire.committed.option1",
                "questionnaire.committed.option2",
                "questionnaire.committed.option3",
                "questionnaire.committed.option4"
            ]
        ))),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 11: FINAL COMMITMENT
        // ═══════════════════════════════════════════════════════════════
        
        ("journey_commitment", .commitment(CommitmentStep(
            icon: "checkmark.seal.fill",
            title: NSLocalizedString("questionnaire.journey.title", comment: "Journey title"),
            commitmentText: NSLocalizedString("questionnaire.journey.commitment", comment: "Journey commitment")
        ))),
        
        ("did_it", .info(InfoStep(
            icon: "party.popper.fill",
            title: NSLocalizedString("questionnaire.did_it.title", comment: "Did it title"),
            subtitle: NSLocalizedString("questionnaire.did_it.subtitle", comment: "Did it subtitle"),
            features: nil,
            animationType: .glow
        ))),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 12: SETUP
        // ═══════════════════════════════════════════════════════════════
        
        ("app_selection", .appSelection),
        ("difficulty", .difficultySelection)
    ]
    
    private var steps: [OnboardingStepType] {
        OnboardingFunnelConfig.resolveQuestionnaireSteps(stepCatalog)
    }

    /// Stable catalog ids, parallel to `steps`, used as the analytics `step_identifier`.
    private var stepIDs: [String] {
        OnboardingFunnelConfig.resolveQuestionnaireStepIDs(stepCatalog)
    }

    /// TestFlight crash: `steps[step]` was used from `body` / `finishQuestionnaire` with no bounds check.
    private var safeCurrentStep: OnboardingStepType? {
        guard steps.indices.contains(step) else { return nil }
        return steps[step]
    }
    
    var body: some View {
        ZStack {
            // Animated background
            animatedBackground
            
            VStack(spacing: 0) {
                // Progress bar (verborgen op reflection en prayer lock)
                if shouldShowProgressBar {
                    progressBar
                        .padding(.top, 8)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
                
                // Content area
                if shouldCenterContent {
                    // Info & Visual steps: centered vertically
                    GeometryReader { geometry in
                        ZStack {
                            stepContentWithHorizontalPadding
                                .id(step)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                } else {
                    // Other steps: normal scrollable layout
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            currentStepContent
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 140)
                    }
                }
                
                // Bottom button area
                bottomButtonArea
            }
            .modifier(OnboardingHandoffModifier(isActive: isHandingOff))
            .animation(.spring(response: 0.72, dampingFraction: 0.88), value: step)
            .ignoresSafeArea(.keyboard, edges: keyboardIgnoredEdges)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                updateKeyboardOverlap(from: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
                let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
                withAnimation(.easeOut(duration: duration)) {
                    keyboardOverlap = 0
                }
            }
        }
        .overlay {
            if showFamilyControlsDeniedAlert {
                CustomAlertView(
                    title: NSLocalizedString("selection.permission_title", comment: "Permission Required"),
                    message: NSLocalizedString("selection.permission_message", comment: "Family Controls permission was denied."),
                    icon: "lock.shield.fill",
                    iconColor: AppTheme.primary,
                    isPresented: $showFamilyControlsDeniedAlert,
                    primaryAction: { showFamilyControlsDeniedAlert = false },
                    primaryActionTitle: NSLocalizedString("common.ok", comment: "OK")
                )
            }
        }
        .overlay {
            if showGuideMuslimsReviewPopup {
                GuideMuslimsReviewPopup(
                    isPresented: $showGuideMuslimsReviewPopup,
                    onRate: {
                        didHandleGuideMuslimsReview = true
                        // Stay on this page so Apple’s star sheet cannot land on life-change.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            OnboardingGuideMuslimsView.requestGuideReview()
                        }
                    },
                    onCancel: {
                        didHandleGuideMuslimsReview = true
                        advancePastCurrentStep(requestReview: false)
                    }
                )
                .zIndex(1000)
            }
        }
        .onChange(of: step) { newStep in
            // Cancel auto-advance timers when leaving steps
            considerThisAutoAdvanceWorkItem?.cancel()
            considerThisAutoAdvanceWorkItem = nil
            impactStatsAutoAdvanceWorkItem?.cancel()
            impactStatsAutoAdvanceWorkItem = nil
            prayerLockAutoAdvanceWorkItem?.cancel()
            prayerLockAutoAdvanceWorkItem = nil
            
            // Safety check
            guard newStep >= 0 && newStep < steps.count else {
                debugPrint("❌ ERROR: Invalid step \(newStep), steps.count = \(steps.count)")
                return
            }
            
            debugPrint("🟢 Step changed to \(newStep)/\(steps.count - 1)")

            showGuideMuslimsReviewPopup = false
            didHandleGuideMuslimsReview = false
            
            // Reset haptic trigger for new step
            hasTriggeredStepHaptic = false
            
            // Trigger transition haptic
            if previousStep != -1 {
                triggerStepChangeHaptic(from: previousStep, to: newStep)
            }
            previousStep = newStep
            dismissOnboardingKeyboard()
            
            resetAnimations()
            // Start new animations after a brief delay to allow transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                startAnimations()
            }
            // Track step view
            trackStepViewed(step: newStep)
        }
        .onAppear {
            startAnimations()
            #if canImport(FamilyControls)
            if #available(iOS 16.0, *) {
                appSelection = shieldManager.currentFamilySelection()
            }
            #endif
            // Track onboarding started
            PostHogManager.shared.screen(AnalyticsScreen.onboarding)
            AnalyticsManager.shared.trackOnboardingStarted()
            trackStepViewed(step: 0)
        }
        .onDisappear {
            // Track abandonment if not completed
            if step < steps.count - 1 {
                AnalyticsManager.shared.trackOnboardingAbandoned(
                    atStep: step,
                    stepName: getStepName(for: step),
                    stepIdentifier: getStepIdentifier(for: step),
                    totalSteps: steps.count
                )
            }
        }
        #if canImport(FamilyControls)
        .onChange(of: isAppPickerPresented) { _ in
            if !isAppPickerPresented {
                if #available(iOS 16.0, *) {
                    shieldManager.commitPickerSelection(appSelection)
                }
            }
        }
        #endif
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(AppTheme.muted)
                    .frame(height: 4)
                
                // Progress fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 4)
        .onChange(of: progress) { newProgress in
            // Strategic haptic feedback at milestone progress points
            let milestones: [CGFloat] = [0.25, 0.5, 0.75, 0.9, 1.0]
            for milestone in milestones {
                if newProgress >= milestone && lastProgressHaptic < milestone {
                    triggerProgressHaptic(for: milestone)
                    lastProgressHaptic = milestone
                    break
                }
            }
        }
    }
    
    private func triggerProgressHaptic(for milestone: CGFloat) {
        switch milestone {
        case 0.25:
            HapticManager.shared.soft()
        case 0.5:
            HapticManager.shared.medium()
        case 0.75:
            HapticManager.shared.selection()
        case 0.9:
            HapticManager.shared.medium()
        case 1.0:
            HapticManager.shared.success()
        default:
            HapticManager.shared.light()
        }
    }
    
    private var progress: CGFloat {
        guard steps.count > 0 else { return 0 }
        return CGFloat(step + 1) / CGFloat(steps.count)
    }
    
    private var shouldCenterContent: Bool {
        // All questionnaire steps use vertically centered content layout
        return true
    }

    /// Question pages keep their layout when the keyboard is up. Name input still avoids it.
    private var keyboardIgnoredEdges: Edge.Set {
        if case .nameInput = safeCurrentStep { return [] }
        return .bottom
    }

    /// Streak / demo / interactive demo fill width; other steps use side padding.
    @ViewBuilder
    private var stepContentWithHorizontalPadding: some View {
        switch safeCurrentStep {
        case .streakPreview, .demoNotification, .interactiveDemo, .allowNotifications, .patienceQuote, .appIconPicker, .guideMuslims:
            currentStepContent
        case .info(let info) where info.visualDemo == .fajrPhotoAlarm || info.visualDemo == .widgetDesire:
            currentStepContent
        case nil:
            Color.clear
        default:
            currentStepContent
                .padding(.horizontal, 24)
        }
    }
    
    /// Progress bar verbergen op reflection, prayer lock en name input (content bovenaan, geen bar)
    private var shouldShowProgressBar: Bool {
        guard let current = safeCurrentStep else { return false }
        // Short funnel: show progress once the user starts answering (goal-gradient).
        if OnboardingFunnelConfig.useShortFunnel {
            switch current {
            case .reflection, .prayerLock, .nameInput, .demoNotification:
                return false
            case .info:
                return step != 0
            default:
                return true
            }
        }
        switch current {
        case .info, .reflection, .prayerLock, .nameInput, .considerThis, .sliderQuestion, .ageSelection, .impactStats, .planIntro, .demoNotification:
            return false
        default:
            return true
        }
    }
    
    private var isGuideMuslimsStep: Bool {
        if case .guideMuslims = safeCurrentStep { return true }
        return false
    }
    
    // Hide button for considerThis (auto-advance after 4s) and referral (auto-advance on selection)
    private var shouldHideButton: Bool {
        switch safeCurrentStep {
        case .considerThis, .referralSource, .demoNotification:
            return true
        case .prayerLock(let prayerLock) where prayerLock.autoAdvanceAfterSeconds != nil:
            return true
        default:
            return false
        }
    }

    private var isAutoAdvancePrayerLock: Bool {
        if case .prayerLock(let prayerLock) = safeCurrentStep {
            return prayerLock.autoAdvanceAfterSeconds != nil
        }
        return false
    }
    
    private var isCommitmentStep: Bool {
        if case .commitment = safeCurrentStep { return true }
        return false
    }
    
    /// Softer “locked” CTA before user taps the commitment card (clearer than flat muted).
    private var commitmentNextButtonNeedsAcknowledgment: Bool {
        isCommitmentStep && commitmentAccepted[step] != true
    }
    
    // MARK: - Animated Background (Optimized)
    
    private var animatedBackground: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            // Single subtle glow - optimized for performance
            RadialGradient(
                colors: [
                    AppTheme.primary.opacity(0.08),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Current Step Content
    
    @ViewBuilder
    private var currentStepContent: some View {
        Group {
            switch safeCurrentStep {
            case .info(let info):
                infoStepView(info)
            case .reflection(let reflection):
                reflectionStepView(reflection)
            case .prayerLock(let prayerLock):
                prayerLockStepView(prayerLock)
            case .nameInput(let nameStep):
                nameInputStepView(nameStep)
            case .considerThis(let considerStep):
                considerThisStepView(considerStep)
            case .impactStats(let step):
                impactStatsStepView(step)
            case .planIntro(let planStep):
                planIntroStepView(planStep)
            case .referralSource:
                referralSourceStepView
            case .question(let question):
                questionStepView(question)
            case .sliderQuestion(let sliderQuestion):
                sliderQuestionView(sliderQuestion)
            case .ageSelection:
                ageSelectionView
            case .appSelection:
                appSelectionStepView
            case .difficultySelection:
                difficultySelectionStepView
            case .commitment(let commitment):
                commitmentStepView(commitment)
            case .visual(let visual):
                visualStepView(visual)
            case .demoNotification:
                OnboardingDemoNotificationView {
                    // Guard against Skip / step change racing the auto-finish timer
                    guard case .demoNotification = steps[step] else { return }
                    let next = step + 1
                    guard next < steps.count else {
                        finishQuestionnaire()
                        return
                    }
                    withAnimation(.easeInOut(duration: 0.55)) {
                        step = next
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        trackStepViewed(step: next)
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 12)),
                    removal: .opacity.combined(with: .scale(scale: 0.985))
                ))
            case .interactiveDemo:
                interactiveDemoView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 10)),
                        removal: .opacity
                    ))
            case .streakPreview:
                OnboardingStreakPreviewView()
                    .id(step)
            case .allowNotifications:
                OnboardingAllowNotificationsView()
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 10)),
                        removal: .opacity
                    ))
            case .patienceQuote:
                OnboardingPatienceQuoteView(onTypingComplete: {
                    patienceQuoteReady = true
                })
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 10)),
                        removal: .opacity
                    ))
            case .guideMuslims:
                OnboardingGuideMuslimsView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 10)),
                        removal: .opacity
                    ))
            case .appIconPicker:
                OnboardingAppTimePickerView(
                    selectedIDs: $selectedTimeApps,
                    revealed: appIconPickerRevealed
                )
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 10)),
                    removal: .opacity
                ))
            case nil:
                Color.clear
            }
        }
        .transition(safeCurrentStep.map(transitionForStep) ?? .opacity)
    }

    /// Cinematic handoff for the “this can change your life” beat → next question.
    private func transitionForStep(_ type: OnboardingStepType) -> AnyTransition {
        switch type {
        case .prayerLock(let prayerLock) where prayerLock.autoAdvanceAfterSeconds != nil:
            // Soft dissolve upward — like the words lifting into the next moment
            return .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                removal: .opacity
                    .combined(with: .scale(scale: 1.05))
                    .combined(with: .offset(y: -42))
            )
        case .question:
            // Rise gently into place after the life-change dissolve
            return .asymmetric(
                insertion: .opacity
                    .combined(with: .scale(scale: 0.94))
                    .combined(with: .offset(y: 36)),
                removal: .opacity.combined(with: .offset(y: -10))
            )
        default:
            return .asymmetric(
                insertion: .opacity.combined(with: .offset(y: 12)),
                removal: .opacity
            )
        }
    }
    
    // MARK: - Info Step View
    
    @ViewBuilder
    private func infoStepView(_ info: InfoStep) -> some View {
        if isJoinMuslimsInfoStep(info) {
            joinMuslimsSocialProofView()
        } else if info.visualDemo == .fajrPhotoAlarm {
            OnboardingFajrWakeView {
                infoAnimationComplete = true
            }
        } else if info.visualDemo == .fajrSetup {
            OnboardingFajrSetupView {
                infoAnimationComplete = true
            }
        } else if info.visualDemo == .widgetDesire {
            OnboardingWidgetDesireView {
                infoAnimationComplete = true
            }
        } else {
            infoStepViewDefault(info)
        }
    }

    /// Just Pray–style social proof: headline + avatars + vertical review cards, ScrollDeeds chrome.
    private func joinMuslimsSocialProofView() -> some View {
        let title = NSLocalizedString("questionnaire.join.title", comment: "")
        let highlight = NSLocalizedString("questionnaire.join.title_highlight", comment: "ScrollDeeds")
        let compact = isCompactOnboardingHeight

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.primary.opacity(0.10),
                            AppTheme.primary.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 36)
                .offset(y: -120)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: compact ? 12 : 20)

                    typewriterReserved(
                        full: joinHighlightedTitle(full: title, highlight: highlight, fontSize: compact ? 26 : 30, visibleCount: title.count)
                    ) {
                        joinHighlightedTitle(full: title, highlight: highlight, fontSize: compact ? 26 : 30, visibleCount: narrativeTypedCount[0] ?? 0)
                    }
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer().frame(height: 10)

                    typewriterReserved(
                        full: Text(NSLocalizedString("questionnaire.join.subtitle", comment: ""))
                            .font(.system(size: compact ? 15 : 16, weight: .regular, design: .rounded))
                    ) {
                        Text(OnboardingTypewriter.prefix(NSLocalizedString("questionnaire.join.subtitle", comment: ""), count: narrativeTypedCount[1] ?? 0))
                            .font(.system(size: compact ? 15 : 16, weight: .regular, design: .rounded))
                    }
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)

                    Spacer().frame(height: 16)

                    joinAvatarStack()
                        .opacity(infoSubtitleVisible ? 1 : 0)

                    Spacer().frame(height: 8)

                    Text(NSLocalizedString("conv_paywall.social.based_on", comment: "Based on App Store reviews"))
                        .font(.system(size: compact ? 13 : 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                        .opacity(infoSubtitleVisible ? 1 : 0)

                    Spacer().frame(height: compact ? 20 : 28)

                    VStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { index in
                            JoinMuslimsReviewCard(
                                compact: compact,
                                name: NSLocalizedString("questionnaire.join.review\(index + 1).name", comment: ""),
                                quote: NSLocalizedString("questionnaire.join.review\(index + 1).body", comment: ""),
                                flag: ["🇧🇪", "🇺🇸", "🇬🇧"][index]
                            )
                            .opacity(joinReviewsVisible ? 1 : 0)
                            .offset(y: joinReviewsVisible ? 0 : 12)
                            .animation(
                                .easeOut(duration: 0.45).delay(Double(index) * 0.08),
                                value: joinReviewsVisible
                            )
                        }
                    }

                    Spacer().frame(height: 24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func joinHighlightedTitle(full: String, highlight: String, fontSize: CGFloat, visibleCount: Int? = nil) -> Text {
        OnboardingTypewriter.highlightedText(
            full: full,
            visibleCount: visibleCount ?? full.count,
            highlight: highlight,
            fontSize: fontSize,
            weight: .bold,
            highlightWeight: .bold
        )
    }

    private func joinAvatarStack() -> some View {
        let colors: [Color] = [
            AppTheme.primary,
            AppTheme.primary.opacity(0.75),
            AppTheme.accent
        ]
        let initials = (1...3).map { index -> String in
            let name = NSLocalizedString("questionnaire.join.review\(index).name", comment: "")
            return name.first.map { String($0).uppercased() } ?? "?"
        }

        return HStack(spacing: -10) {
            ForEach(0..<3, id: \.self) { index in
                ZStack {
                    Circle()
                        .fill(colors[index % colors.count])
                        .frame(width: 36, height: 36)
                    Circle()
                        .strokeBorder(AppTheme.background, lineWidth: 2.5)
                        .frame(width: 36, height: 36)
                    Text(initials[index])
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .zIndex(Double(3 - index))
            }
        }
    }

    private func infoStepViewDefault(_ info: InfoStep) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.primary.opacity(0.12),
                            AppTheme.primary.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 40)
                .offset(y: -60)
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 32) {
                    Group {
                        if info.icon == "moon.stars.fill" {
                            NafsiBuddyView(pose: "NafsiPoseStand", height: 128)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primary.opacity(0.08))
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                    .opacity(pulseAnimation ? 0.5 : 0.8)

                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppTheme.primary.opacity(0.2),
                                                AppTheme.primary.opacity(0.12)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 96, height: 96)

                                Circle()
                                    .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 96, height: 96)

                                Image(systemName: info.icon)
                                    .font(.system(size: 42, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [AppTheme.primaryLight, AppTheme.primary],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, y: 4)
                            }
                        }
                    }
                    .onAppear {
                        if infoIconVisible {
                            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                pulseAnimation = true
                            }
                        }
                    }
                    .opacity(infoIconVisible ? 1 : 0)
                    .scaleEffect(infoIconVisible ? 1 : 0.92)
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.6))
                                .frame(width: 4, height: 4)
                            Circle()
                                .fill(AppTheme.primary.opacity(0.4))
                                .frame(width: 3, height: 3)
                        }
                        .opacity(infoTitleVisible ? 1 : 0)

                        OnboardingTypewriter.highlightedText(
                            full: info.title,
                            visibleCount: narrativeTypedCount[0] ?? 0,
                            highlight: nil,
                            fontSize: 28,
                            weight: .bold,
                            highlightWeight: .bold
                        )
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.2), radius: 6, y: 3)
                            .padding(.horizontal, 16)

                        Text(OnboardingTypewriter.prefix(info.subtitle, count: narrativeTypedCount[1] ?? 0))
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                    }
                    
                    if let features = info.features {
                        VStack(spacing: 12) {
                            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        AppTheme.success.opacity(0.25),
                                                        AppTheme.success.opacity(0.12)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 36, height: 36)
                                        
                                        Circle()
                                            .stroke(AppTheme.success.opacity(0.4), lineWidth: 1)
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppTheme.success)
                                    }
                                    
                                    Text(OnboardingTypewriter.prefix(feature, count: narrativeTypedCount[index + 2] ?? 0))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(AppTheme.card)
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(AppTheme.border, lineWidth: 1)
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                                .opacity((narrativeTypedCount[index + 2] ?? 0) > 0 ? 1 : 0)
                                .offset(y: infoFeaturesVisible[index] ?? false ? 0 : 10)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reflection Step View (attention / God page – Islamic & ScrollDeeds style, per-line fade)
    
    private let reflectionContentMaxWidth: CGFloat = 340
    
    @ViewBuilder
    private func reflectionStepView(_ reflection: ReflectionStep) -> some View {
        GeometryReader { geometry in
            let contentWidth = min(reflectionContentMaxWidth, geometry.size.width * 0.88)
            let hPad = max(24, geometry.size.width * 0.07)
            let lineSpacing = max(14, min(20, geometry.size.height * 0.022))
            let titleSize = max(26, min(32, geometry.size.width * 0.075))
            let bodySize = max(18, min(22, geometry.size.width * 0.048))

            ZStack {
                // Soft glow — matches benefits reflection / ScrollDeeds chrome
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primary.opacity(0.10),
                                AppTheme.primary.opacity(0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 160
                        )
                    )
                    .frame(
                        width: min(320, geometry.size.width * 0.85),
                        height: min(320, geometry.size.width * 0.85)
                    )
                    .blur(radius: 36)
                    .offset(y: -geometry.size.height * 0.12)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: max(48, geometry.safeAreaInsets.top + 28))

                    VStack(alignment: .leading, spacing: lineSpacing) {
                        typewriterReserved(full: reflectionTitleView(reflection, fontSize: titleSize, visibleCount: reflection.title.count)) {
                            reflectionTitleView(reflection, fontSize: titleSize, visibleCount: narrativeTypedCount[0] ?? 0)
                        }
                            .frame(maxWidth: contentWidth, alignment: .leading)

                        ForEach(Array(reflection.lines.enumerated()), id: \.offset) { index, line in
                            typewriterReserved(
                                full: Text(line)
                                    .font(.system(size: bodySize, weight: .medium, design: .rounded))
                            ) {
                                Text(OnboardingTypewriter.prefix(line, count: narrativeTypedCount[index + 1] ?? 0))
                                    .font(.system(size: bodySize, weight: .medium, design: .rounded))
                            }
                                .foregroundColor(AppTheme.textSecondary.opacity(0.95))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: contentWidth, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, hPad)

                    Spacer(minLength: 0)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func reflectionTitleView(_ reflection: ReflectionStep, fontSize: CGFloat = 28, visibleCount: Int? = nil) -> some View {
        OnboardingTypewriter.highlightedText(
            full: reflection.title,
            visibleCount: visibleCount ?? reflection.title.count,
            highlight: reflection.titleHighlight,
            fontSize: fontSize,
            weight: .bold,
            highlightWeight: .bold,
            caseInsensitive: true
        )
        .multilineTextAlignment(.leading)
        .lineSpacing(6)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Prayer Lock Step View (zelfde stijl: links uitgelijnd, highlights, per-line fade)
    
    private let prayerLockContentMaxWidth: CGFloat = 340

    private var displayUserName: String {
        let fromField = enteredName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fromField.isEmpty { return fromField }
        let stored = userDataManager.userName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let n = stored, !n.isEmpty { return n }
        return NSLocalizedString("questionnaire.consider_this.fallback_name", comment: "there")
    }

    private func resolvedPrayerLockLines(_ step: PrayerLockStep) -> [PrayerLockLine] {
        guard let formatKey = step.nameGreetingFormatKey else { return step.lines }
        let name = displayUserName
        let greeting = String(format: NSLocalizedString(formatKey, comment: "%@,"), name)
        return [PrayerLockLine(text: greeting, highlight: name)] + step.lines
    }
    
    @ViewBuilder
    private func prayerLockStepView(_ step: PrayerLockStep) -> some View {
        let lines = resolvedPrayerLockLines(step)
        // Only the short phones (SE, 13 mini) need tighter gaps. 6.1" and larger
        // keep the previous spacing — that layout already fit those screens.
        let isSmallPhone = UIScreen.main.bounds.height <= 812
        GeometryReader { geometry in
            let fontSize = max(24, min(28, geometry.size.width * 0.062))
            if !isSmallPhone {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppTheme.primary.opacity(0.10),
                                    AppTheme.primary.opacity(0.04),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 160
                            )
                        )
                        .frame(width: 320, height: 320)
                        .blur(radius: 36)
                        .offset(y: -geometry.size.height * 0.12)
                }
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: isSmallPhone ? 8 : max(step.buddyPose == nil ? 32 : 16, geometry.size.height * (step.buddyPose == nil ? 0.06 : 0.03)))
                    if let pose = step.buddyPose {
                        HStack {
                            Spacer(minLength: 0)
                            NafsiBuddyView(pose: pose, height: step.showDeedCards ? 96 : 108)
                            Spacer(minLength: 0)
                        }
                        .padding(.bottom, 8)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                            typewriterReserved(
                                full: prayerLockLineView(line: line, fontSize: fontSize, visibleCount: line.text.count)
                            ) {
                                prayerLockLineView(line: line, fontSize: fontSize, visibleCount: narrativeTypedCount[index] ?? 0)
                            }
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: prayerLockContentMaxWidth, alignment: .leading)
                            if index < lines.count - 1 {
                                Spacer().frame(
                                    height: step.paragraphBreakAfterIndices.contains(index)
                                        ? (isSmallPhone ? 16 : 26)
                                        : (isSmallPhone ? 10 : 16)
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, max(20, geometry.size.width * 0.06))
                    .opacity(prayerLockDissolving ? 0 : 1)

                    if step.showDeedCards {
                        Spacer().frame(height: isSmallPhone ? 20 : max(72, geometry.size.height * 0.10))
                        prayerLockDeedCardsGrid(compact: false)
                            .padding(.horizontal, max(12, geometry.size.width * 0.02))
                            .opacity(prayerLockCardsVisible ? 1 : 0)
                            .offset(y: prayerLockCardsVisible ? 0 : 10)
                    }

                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background {
                if isSmallPhone {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppTheme.primary.opacity(0.10),
                                    AppTheme.primary.opacity(0.04),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 160
                            )
                        )
                        .frame(width: 320, height: 320)
                        .blur(radius: 36)
                        .offset(y: -geometry.size.height * 0.12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var prayerLockDeedCards: [(id: String, titleKey: String, icon: String)] {
        [
            ("dhikr", "benefits.card.dhikr", "waveform"),
            ("dua", "benefits.card.dua", "hands.sparkles.fill"),
            ("quran", "benefits.card.quran", "book.fill"),
            ("istighfar", "benefits.card.istighfar", "heart.fill"),
            ("sadaqah", "benefits.card.sadaqah", "gift.fill"),
            ("salawat", "benefits.card.salawat", "sparkles")
        ]
    }

    private func prayerLockDeedCardsGrid(compact: Bool) -> some View {
        let circle: CGFloat = compact ? 52 : 64
        return VStack(spacing: compact ? 12 : 22) {
            HStack(spacing: 14) {
                ForEach(Array(prayerLockDeedCards.prefix(3)), id: \.id) { card in
                    prayerLockDeedCard(titleKey: card.titleKey, icon: card.icon, circle: circle)
                }
            }
            HStack(spacing: 14) {
                ForEach(Array(prayerLockDeedCards.suffix(3)), id: \.id) { card in
                    prayerLockDeedCard(titleKey: card.titleKey, icon: card.icon, circle: circle)
                }
            }
        }
    }

    private func prayerLockDeedCard(titleKey: String, icon: String, circle: CGFloat) -> some View {
        VStack(spacing: circle < 60 ? 6 : 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: circle, height: circle)
                Image(systemName: icon)
                    .font(.system(size: circle * 0.40, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
            }
            Text(NSLocalizedString(titleKey, comment: ""))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func typewriterReserved<Full: View, Live: View>(full: Full, @ViewBuilder live: () -> Live) -> some View {
        ZStack(alignment: .topLeading) {
            full.hidden()
            live()
        }
    }

    @ViewBuilder
    private func prayerLockLineView(line: PrayerLockLine, fontSize: CGFloat = 23, lineSpacing: CGFloat = 6, visibleCount: Int? = nil) -> some View {
        OnboardingTypewriter.highlightedText(
            full: line.text,
            visibleCount: visibleCount ?? line.text.count,
            highlight: line.highlight,
            fontSize: fontSize
        )
        .multilineTextAlignment(.leading)
        .lineSpacing(lineSpacing)
    }
    
    // MARK: - Name Input Step View (ScrollDeeds style: content bovenaan, zelfde glow en stijl als rest onboarding)
    
    private func nameInputStepView(_ nameStep: NameInputStep) -> some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primary.opacity(0.10),
                                AppTheme.primary.opacity(0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: 36)
                    .offset(y: -geometry.size.height * 0.15)
            }
            VStack(alignment: .leading, spacing: 0) {
                // Content bovenaan met lichte spacing (niet plakken tegen bovenrand)
                Spacer()
                    .frame(height: max(24, geometry.size.height * 0.045))
                VStack(alignment: .leading, spacing: 24) {
                    Text(nameStep.subtitle)
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.95))
                        .opacity(nameInputSubtitleVisible ? 1 : 0)
                        .offset(y: nameInputSubtitleVisible ? 0 : narrativeRevealOffset)
                    
                    Text(nameStep.title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(nameInputTitleVisible ? 1 : 0)
                        .offset(y: nameInputTitleVisible ? 0 : narrativeRevealOffset)
                    
                    TextField(nameStep.placeholder, text: $enteredName)
                        .focused($nameInputFocused)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(AppTheme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(AppTheme.border, lineWidth: 1)
                                )
                        )
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .opacity(nameInputFieldVisible ? 1 : 0)
                        .offset(y: nameInputFieldVisible ? 0 : narrativeRevealOffset)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                Spacer(minLength: 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if let existing = userDataManager.userName, !existing.isEmpty {
                enteredName = existing
            }
            nameFocusWorkItem?.cancel()
            let work = DispatchWorkItem {
                guard case .nameInput = self.safeCurrentStep else { return }
                self.nameInputFocused = true
            }
            nameFocusWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8, execute: work)
        }
    }
    
    // MARK: - Consider This Step View (zelfde ScrollDeeds-stijl als rest: groene achtergrond, witte tekst, geen knop, auto na 4s)
    
    private func considerThisStepView(_ considerStep: ConsiderThisStep) -> some View {
        let displayName: String = {
            let raw = userDataManager.userName?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let n = raw, !n.isEmpty { return n }
            return NSLocalizedString("questionnaire.consider_this.fallback_name", comment: "there")
        }()
        let formatTemplate = NSLocalizedString(considerStep.formatKey, comment: "")
        let text = String(format: formatTemplate, displayName)
        
        return GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                typewriterReserved(
                    full: Text(text)
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                ) {
                    Text(OnboardingTypewriter.prefix(text, count: narrativeTypedCount[0] ?? 0))
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                }
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Impact Stats Step View (na leeftijd: uren/dagen/jaren uit scroll-uur, ScrollDeeds, per-line fade, auto 3s)
    
    private let impactStatsContentMaxWidth: CGFloat = 340
    
    private var screenTimeStepIndex: Int? {
        steps.firstIndex {
            if case .sliderQuestion(let slider) = $0 { return !slider.isMoodSlider }
            return false
        }
    }

    private var screenTimeHoursPerDay: Int {
        guard let idx = screenTimeStepIndex else { return 3 }
        return sliderValues[idx] ?? answers[idx] ?? 3
    }

    private var selectedImpactAppIcons: [OnboardingAppOption] {
        Array(OnboardingAppTimeOptions.all.filter { selectedTimeApps.contains($0.id) }.prefix(3))
    }
    
    @ViewBuilder
    private func impactStatsStepView(_ impactStep: ImpactStatsStep) -> some View {
        let displayName: String = {
            let raw = userDataManager.userName?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let n = raw, !n.isEmpty { return n }
            return NSLocalizedString("questionnaire.consider_this.fallback_name", comment: "there")
        }()
        let hoursPerDay = screenTimeHoursPerDay
        let hoursPerYear = hoursPerDay * 365
        let yearsLifetime = Int(round(Double(hoursPerYear) * 60.0 / 8760.0))
        let yearsSuffix = NSLocalizedString("questionnaire.impact_stats.years_suffix", comment: "years")
        let displayedHours = impactCountedHours
        let displayedDays = impactCountedDays
        let resolvedLines: [PrayerLockLine] = (0..<impactStep.lines.count).map { index in
            switch index {
            case 0:
                let text = String(format: NSLocalizedString("questionnaire.impact_stats.line1_format", comment: ""), displayName, displayedHours)
                return PrayerLockLine(text: text, highlight: "\(displayedHours)")
            case 2:
                let text = String(format: NSLocalizedString("questionnaire.impact_stats.line3_format", comment: ""), displayedDays)
                return PrayerLockLine(text: text, highlight: "\(displayedDays)")
            case 3:
                let text = String(format: NSLocalizedString("questionnaire.impact_stats.line4_format", comment: ""), yearsLifetime)
                return PrayerLockLine(text: text, highlight: "\(yearsLifetime) \(yearsSuffix)")
            default:
                return impactStep.lines[index]
            }
        }
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primary.opacity(impactHeroVisible ? 0.16 : 0.10),
                                AppTheme.accent.opacity(impactHeroVisible ? 0.08 : 0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 180
                        )
                    )
                    .frame(width: 340, height: 340)
                    .blur(radius: 36)
                    .scaleEffect(impactHeroVisible ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 1.2), value: impactHeroVisible)
                    .offset(y: -geometry.size.height * 0.14)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 0) {
                    Spacer()
                        .frame(height: max(20, geometry.size.height * 0.04))

                    // Hero “aha” number — years of life on the phone, selected apps land under it
                    VStack(spacing: 0) {
                        Text("\(impactHeroYears)")
                            .font(.system(size: min(72, geometry.size.width * 0.18), weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.primaryLight, AppTheme.primary, AppTheme.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .contentTransition(.numericText())
                            .animation(.easeOut(duration: 0.08), value: impactHeroYears)
                        if !selectedImpactAppIcons.isEmpty {
                            impactSelectedAppIconsRow(size: 36)
                                .padding(.top, -18)
                                .padding(.bottom, 8)
                        } else {
                            Spacer().frame(height: 4)
                        }
                        Text(yearsSuffix)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                    .scaleEffect(impactHeroScale)
                    .opacity(impactHeroVisible ? 1 : 0)
                    .padding(.bottom, 22)

                    VStack(alignment: .leading, spacing: max(14, geometry.size.height * 0.018)) {
                        ForEach(Array(resolvedLines.enumerated()), id: \.offset) { index, line in
                            typewriterReserved(
                                full: prayerLockLineView(line: line, fontSize: max(22, min(26, geometry.size.width * 0.058)), visibleCount: line.text.count)
                            ) {
                                prayerLockLineView(line: line, fontSize: max(22, min(26, geometry.size.width * 0.058)), visibleCount: narrativeTypedCount[index] ?? 0)
                            }
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: impactStatsContentMaxWidth, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, max(20, geometry.size.width * 0.06))
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Kick hero count after a beat so the big number feels earned.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                    impactHeroVisible = true
                    impactHeroScale = 1.0
                }
                animateImpactHeroYears(to: max(1, yearsLifetime))
            }
        }
    }

    private func animateImpactHeroYears(to target: Int) {
        impactHeroYears = 0
        guard target > 0 else { return }
        let sequenceID = impactStatsSequenceID
        let steps = min(target, 24)
        let interval = 0.045
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                guard impactStatsSequenceID == sequenceID else { return }
                let value = Int(round(Double(target) * Double(i) / Double(steps)))
                withAnimation(.easeOut(duration: 0.08)) {
                    impactHeroYears = value
                }
                if i == steps {
                    HapticManager.shared.heavy()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                        impactHeroScale = 1.08
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        guard impactStatsSequenceID == sequenceID else { return }
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                            impactHeroScale = 1.0
                        }
                    }
                } else if i % 3 == 0 {
                    HapticManager.shared.selection()
                }
            }
        }
    }

    private func impactSelectedAppIconsRow(size: CGFloat) -> some View {
        let apps = selectedImpactAppIcons
        let corner = size * 0.24
        return HStack(spacing: -10) {
            ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                Image(app.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(Color.white.opacity(0.92), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 4, y: 2)
                    .scaleEffect(impactIconsRevealed > index ? 1 : 0.45)
                    .opacity(impactIconsRevealed > index ? 1 : 0)
                    .offset(y: impactIconsRevealed > index ? 0 : -16)
                    .zIndex(Double(index))
            }
        }
    }

    private func animateImpactIntCount(
        to target: Int,
        duration: Double,
        startDelay: Double,
        sequenceID: UUID,
        onTick: @escaping (Int) -> Void,
        onComplete: (() -> Void)? = nil
    ) {
        guard target >= 0 else { return }
        let steps = min(max(target, 1), 32)
        let interval = duration / Double(steps)
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + Double(i) * interval) {
                guard impactStatsSequenceID == sequenceID else { return }
                let value = Int(round(Double(target) * Double(i) / Double(steps)))
                withAnimation(.easeOut(duration: 0.08)) {
                    onTick(value)
                }
                if i == steps {
                    onComplete?()
                }
            }
        }
    }
    
    // MARK: - Plan Intro Step View (zelfde chrome als prayer-lock / andere narrative info pages)
    
    @ViewBuilder
    private func planIntroStepView(_ step: PlanIntroStep) -> some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primary.opacity(0.10),
                                AppTheme.primary.opacity(0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: 36)
                    .offset(y: -geometry.size.height * 0.12)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: max(32, geometry.size.height * 0.06))
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(step.lines.enumerated()), id: \.offset) { index, line in
                            typewriterReserved(
                                full: prayerLockLineView(line: line, fontSize: max(24, min(28, geometry.size.width * 0.062)), visibleCount: line.text.count)
                            ) {
                                prayerLockLineView(line: line, fontSize: max(24, min(28, geometry.size.width * 0.062)), visibleCount: narrativeTypedCount[index] ?? 0)
                            }
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: prayerLockContentMaxWidth, alignment: .leading)
                            if index < step.lines.count - 1 {
                                Spacer().frame(height: index == 0 ? 26 : 16)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, max(20, geometry.size.width * 0.06))
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var otherAnswerText: String {
        otherAnswers[step] ?? ""
    }

    private func dismissOnboardingKeyboard() {
        nameFocusWorkItem?.cancel()
        nameFocusWorkItem = nil
        nameInputFocused = false
        otherInputFocused = false
        keyboardOverlap = 0
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func updateKeyboardOverlap(from notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first
        else { return }
        let overlap = max(0, window.frame.maxY - frame.minY - window.safeAreaInsets.bottom)
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        withAnimation(.easeOut(duration: duration)) {
            keyboardOverlap = overlap
        }
    }

    private func isOtherAnswerSelected(_ question: QuestionStep) -> Bool {
        guard let otherIndex = question.otherOptionIndex else { return false }
        return answers[step] == otherIndex
    }

    private var showsOtherAnswerField: Bool {
        if case .question(let question) = safeCurrentStep {
            return isOtherAnswerSelected(question)
        }
        return false
    }

    private var otherFieldKeyboardLift: CGFloat {
        (otherInputFocused && showsOtherAnswerField) ? keyboardOverlap : 0
    }

    private func selectQuestionOption(_ index: Int, question: QuestionStep, option: String) {
        guard !isTransitioning else { return }
        let isOther = question.otherOptionIndex == index
        triggerOptionSelectionHaptic(optionIndex: index)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            answers[step] = index
        }
        if !isOther {
            otherInputFocused = false
        }
        AnalyticsManager.shared.trackOnboardingAnswer(
            step: step,
            stepName: question.title,
            stepIdentifier: getStepIdentifier(for: step),
            answerIndex: index,
            answerText: AnalyticsAnswerLabel.english(
                key: question.optionKeys.indices.contains(index) ? question.optionKeys[index] : "",
                fallback: option
            )
        )
    }

    // MARK: - Question Step View
    
    private func questionStepView(_ question: QuestionStep) -> some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 16) {
                    VStack(spacing: 6) {
                        Text(question.title)
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        if !question.subtitle.isEmpty {
                            Text(question.subtitle)
                                .font(.system(size: 17))
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                    questionHero(
                        illustrationName: question.illustrationName,
                        emoji: question.emoji,
                        systemImage: question.systemImage
                    )

                    VStack(spacing: 10) {
                        ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                            optionButton(text: option, isSelected: answers[step] == index)
                                .opacity(isTransitioning ? 0.6 : 1.0)
                                .disabled(isTransitioning)
                                .onTapGesture {
                                    selectQuestionOption(index, question: question, option: option)
                                }
                                .opacity(animateOptions ? 1 : 0)
                                .offset(y: animateOptions ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.06),
                                    value: animateOptions
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            dismissOnboardingKeyboard()
        }
    }
    
    @ViewBuilder
    private func questionHero(illustrationName: String?, emoji: String, systemImage: String?) -> some View {
        if let illustrationName {
            OnboardingHeroIllustration(
                imageName: illustrationName,
                revealed: animateContent,
                compact: isCompactOnboardingHeight
            )
        } else {
            OnboardingHeroEmojiIcon(
                emoji: emoji,
                systemImage: systemImage,
                glowColor: systemImage != nil
                    ? AppTheme.primary
                    : OnboardingQuestionEmoji.glow(for: emoji),
                revealed: animateContent
            )
        }
    }

    // MARK: - Referral source (same chrome as `questionStepView`; options scroll only)
    
    /// Fade at bottom of scrollable option lists (referral, difficulty, …).
    private var onboardingOptionsScrollBottomFade: some View {
        LinearGradient(
            colors: [
                AppTheme.background.opacity(0),
                AppTheme.background.opacity(0.55),
                AppTheme.background.opacity(0.92),
                AppTheme.background
            ],
            startPoint: UnitPoint(x: 0.5, y: 0),
            endPoint: UnitPoint(x: 0.5, y: 1)
        )
        .frame(height: 72)
        .allowsHitTesting(false)
    }
    
    private var referralSourceStepView: some View {
        let hearTitle = NSLocalizedString("questionnaire.hear_about.title", comment: "")
        let hearSubtitle = NSLocalizedString("questionnaire.hear_about.subtitle", comment: "")
        let options = Self.referralSourceSlugs.map {
            NSLocalizedString("questionnaire.hear_about.option.\($0)", comment: "")
        }
        return VStack(spacing: 0) {
            // Sticky header — does not scroll (pushed down from progress bar)
            VStack(spacing: 28) {
                OnboardingHeroEmojiIcon(
                    emoji: "👂",
                    glowColor: OnboardingQuestionEmoji.glow(for: "👂"),
                    revealed: animateContent
                )
                
                VStack(spacing: 10) {
                    Text(hearTitle)
                        .font(.system(size: 25, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(hearSubtitle)
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            }
            .padding(.top, 44)
            .padding(.horizontal, 0)
            
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                            optionButton(text: option, isSelected: answers[step] == index)
                                .opacity(isTransitioning ? 0.6 : 1.0)
                                .disabled(isTransitioning)
                                .onTapGesture {
                                    guard !isTransitioning else { return }
                                    isTransitioning = true
                                    triggerOptionSelectionHaptic(optionIndex: index)
                                    let slug = Self.referralSourceSlugs[index]
                                    userDataManager.setReferralSource(slug)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        answers[step] = index
                                    }
                                    AnalyticsManager.shared.trackOnboardingAnswer(
                                        step: step,
                                        stepName: hearTitle,
                                        stepIdentifier: getStepIdentifier(for: step),
                                        answerIndex: index,
                                        answerText: slug.replacingOccurrences(of: "_", with: " ").capitalized
                                    )
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        if step < steps.count - 1 {
                                            HapticManager.shared.light()
                                            withAnimation(.easeInOut(duration: 0.4)) {
                                                step += 1
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                isTransitioning = false
                                            }
                                        } else {
                                            isTransitioning = false
                                        }
                                    }
                                }
                                .opacity(animateOptions ? 1 : 0)
                                .offset(y: animateOptions ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.06),
                                    value: animateOptions
                                )
                        }
                    }
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
                
                onboardingOptionsScrollBottomFade
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Age Selection View
    
    private var ageSelectionView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 40) {
            OnboardingHeroEmojiIcon(
                emoji: "🪪",
                glowColor: AppTheme.accent,
                emojiSize: 58,
                revealed: animateContent
            )
            
            // Title & Subtitle
            VStack(spacing: 12) {
                Text(NSLocalizedString("questionnaire.age.title", comment: "How old are you?"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(NSLocalizedString("questionnaire.age.subtitle", comment: "So we can suggest the best setup for you"))
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            
            // Age Picker
            ScrollDeedsAgePicker(
                selectedAge: Binding(
                    get: { selectedAge ?? 18 },
                    set: { newAge in
                        if selectedAge != newAge {
                            selectedAge = newAge
                            // Store answer
                            if let stepIndex = steps.firstIndex(where: { if case .ageSelection = $0 { return true } else { return false } }) {
                                answers[stepIndex] = newAge
                                // Track answer
                                AnalyticsManager.shared.trackOnboardingAnswer(
                                    step: stepIndex,
                                    stepName: NSLocalizedString("questionnaire.age.title", comment: "How old are you?"),
                                    stepIdentifier: getStepIdentifier(for: stepIndex),
                                    answerIndex: newAge,
                                    answerText: "\(newAge) years old"
                                )
                                // Save to UserDataManager
                                userDataManager.setUserAge("\(newAge)")
                            }
                        }
                    }
                )
            )
            .opacity(animateOptions ? 1 : 0)
            .offset(y: animateOptions ? 0 : 30)
            }
            Spacer()
        }
    }
    
    // MARK: - Slider Question View
    
    private func sliderQuestionView(_ sliderQuestion: SliderQuestionStep) -> some View {
        let currentValue = sliderValues[step] ?? sliderQuestion.defaultValue
        let isMood = sliderQuestion.isMoodSlider
        let heroEmoji = isMood ? Self.moodEmoji(for: currentValue) : sliderQuestion.emoji

        return VStack(spacing: 0) {
            if isMood {
                Spacer(minLength: 0)
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Text(sliderQuestion.title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        if !sliderQuestion.subtitle.isEmpty,
                           sliderQuestion.subtitle != "questionnaire.screen_time.subtitle",
                           !sliderQuestion.subtitle.hasPrefix("questionnaire.") {
                            Text(sliderQuestion.subtitle)
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                    OnboardingHeroEmojiIcon(
                        emoji: heroEmoji,
                        systemImage: sliderQuestion.systemImage,
                        glowColor: OnboardingQuestionEmoji.glow(for: "😔"),
                        emojiSize: 58,
                        revealed: animateContent
                    )
                    .id("mood_\(currentValue)")
                    .animation(.spring(response: 0.35, dampingFraction: 0.72), value: currentValue)

                    sliderQuestionControl(sliderQuestion)
                }
                Spacer(minLength: 0)
            } else if getStepIdentifier(for: step) == "daily_reminder_count" {
                dailyReminderCountSliderView(sliderQuestion)
            } else {
                Spacer(minLength: 0)
                VStack(spacing: 18) {
                    Text(sliderQuestion.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    questionHero(
                        illustrationName: sliderQuestion.illustrationName,
                        emoji: sliderQuestion.emoji,
                        systemImage: sliderQuestion.systemImage
                    )

                    sliderQuestionControl(sliderQuestion)
                }
                .padding(.horizontal, 8)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sliderQuestionControl(_ sliderQuestion: SliderQuestionStep) -> some View {
        ScrollDeedsSlider(
            value: Binding(
                get: { Double(sliderValues[step] ?? sliderQuestion.defaultValue) },
                set: { newValue in
                    let intValue = Int(newValue)
                    sliderValues[step] = intValue
                    answers[step] = intValue
                    let answerText: String
                    if sliderQuestion.isMoodSlider {
                        answerText = AnalyticsAnswerLabel.mood(value: intValue)
                    } else {
                        answerText = "\(intValue) \(sliderQuestion.unit)"
                    }
                    AnalyticsManager.shared.trackOnboardingAnswer(
                        step: step,
                        stepName: sliderQuestion.title,
                        stepIdentifier: getStepIdentifier(for: step),
                        answerIndex: intValue,
                        answerText: answerText
                    )
                }
            ),
            minValue: Double(sliderQuestion.minValue),
            maxValue: Double(sliderQuestion.maxValue),
            unit: sliderQuestion.unit,
            moodLeftLabel: sliderQuestion.moodLeftLabel,
            moodRightLabel: sliderQuestion.moodRightLabel
        )
        .opacity(animateOptions ? 1 : 0)
        .offset(y: animateOptions ? 0 : 30)
    }

    private func dailyReminderCountSliderView(_ sliderQuestion: SliderQuestionStep) -> some View {
        let preview = notificationManager.previewSpiritualNotification()
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(sliderQuestion.title)
                        .font(.system(size: 25, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    if !sliderQuestion.subtitle.isEmpty {
                        Text(sliderQuestion.subtitle)
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 16)

                OnboardingNotificationPreviewCard(title: preview.title, message: preview.body)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: notificationManager.dailySpiritualFilter)

                SpiritualTypePickerCard(
                    isExpanded: $spiritualTypesExpanded,
                    selected: notificationManager.dailySpiritualFilter,
                    onSelect: { notificationManager.setDailySpiritualFilter($0) }
                )
                .opacity(animateOptions ? 1 : 0)

                sliderQuestionControl(sliderQuestion)
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
            .animation(.spring(response: 0.52, dampingFraction: 0.90), value: spiritualTypesExpanded)
        }
    }

    private static func moodEmoji(for value: Int) -> String {
        switch value {
        case 1: return "😞"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        default: return "😄"
        }
    }
    
    // MARK: - Commitment Step View
    
    @ViewBuilder
    private func commitmentStepView(_ commitment: CommitmentStep) -> some View {
        let isCommitted = commitmentAccepted[step] == true
        
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 22) {
                Text(commitment.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .shadow(color: Color.black.opacity(0.25), radius: 8, y: 2)
                    .opacity(animateContent ? 1 : 0)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 36)
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppTheme.primary.opacity(isCommitted ? 0.22 : 0.14),
                                    AppTheme.accent.opacity(0.06),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 200
                            )
                        )
                        .blur(radius: 28)
                        .frame(maxHeight: 280)
                        .offset(y: 24)
                        .allowsHitTesting(false)
                    
                    Button(action: {
                        HapticManager.shared.heavy()
                        let newValue = !isCommitted
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                            commitmentAccepted[step] = newValue
                        }
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                HapticManager.shared.success()
                            }
                        }
                        AnalyticsManager.shared.trackOnboardingCommitment(
                            step: step,
                            stepName: commitment.title,
                            stepIdentifier: getStepIdentifier(for: step),
                            committed: newValue
                        )
                    }) {
                        VStack(spacing: 0) {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    isCommitted ? AppTheme.accent.opacity(0.45) : AppTheme.primary.opacity(0.42),
                                                    isCommitted ? AppTheme.primary.opacity(0.2) : AppTheme.primary.opacity(0.12)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 58, height: 58)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                                        )
                                        .shadow(color: AppTheme.primary.opacity(0.35), radius: 12, y: 4)
                                    
                                    Image(systemName: isCommitted ? "heart.fill" : "hand.raised.fill")
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.white, Color.white.opacity(0.88)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                                }
                                
                                Text(commitment.commitmentText)
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(AppTheme.textPrimary.opacity(0.96))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(7)
                                    .padding(.horizontal, 18)
                            }
                            .padding(.top, 26)
                            .padding(.bottom, 22)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            isCommitted ? AppTheme.primary.opacity(0.35) : AppTheme.border,
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)
                            
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(
                                            isCommitted ? AppTheme.primary : AppTheme.border,
                                            lineWidth: 2
                                        )
                                        .frame(width: 30, height: 30)
                                    
                                    if isCommitted {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [AppTheme.primaryLight, AppTheme.primary],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 30, height: 30)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .scaleEffect(isCommitted ? 1.0 : 0.96)
                                .animation(.spring(response: 0.32, dampingFraction: 0.65), value: isCommitted)
                                
                                Text(isCommitted ? NSLocalizedString("questionnaire.commitment.committed", comment: "I'm committed") : NSLocalizedString("questionnaire.commitment.tap_to_commit", comment: "Tap to commit"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(isCommitted ? AppTheme.primary : AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        isCommitted
                                        ? AppTheme.primary.opacity(0.1)
                                        : AppTheme.cardSecondary
                                    )
                            )
                        }
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(
                                    isCommitted
                                    ? LinearGradient(
                                        colors: [
                                            AppTheme.primary.opacity(0.12),
                                            AppTheme.primary.opacity(0.06),
                                            AppTheme.card
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [
                                            AppTheme.card,
                                            AppTheme.card
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .strokeBorder(
                                    isCommitted
                                    ? LinearGradient(
                                        colors: [AppTheme.primary.opacity(0.55), AppTheme.primary.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [AppTheme.border, AppTheme.border],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isCommitted ? 1.5 : 1
                                )
                        )
                        .shadow(
                            color: isCommitted ? AppTheme.primary.opacity(0.18) : Color.black.opacity(0.06),
                            radius: isCommitted ? 24 : 18,
                            y: isCommitted ? 10 : 8
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isCommitted ? 1.01 : 1.0)
                    .animation(.spring(response: 0.42, dampingFraction: 0.74), value: isCommitted)
                    .opacity(animateOptions ? 1 : 0)
                    .offset(y: animateOptions ? 0 : 22)
                }
            }
            .padding(.horizontal, 22)
            
            Spacer()
        }
    }
    
    // MARK: - Free Trial Info View
    
    
    // MARK: - Visual Step View (Illustrations & Mockups)
    
    private func visualStepView(_ visual: VisualStep) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Compact centered content
            VStack(spacing: 24) {
                // Not-alone: character above title, 87% line as subtitle under title
                if visual.type == .dailyRoutine {
                    NafsiBuddyView(pose: "NafsiPoseSit", height: 84)
                        .opacity(notAloneBuddyRevealed ? 1 : 0)
                        .scaleEffect(notAloneBuddyRevealed ? 1 : 0.94)
                        .offset(y: notAloneBuddyRevealed ? 0 : 10)
                        .animation(.spring(response: 0.58, dampingFraction: 0.84), value: notAloneBuddyRevealed)

                    VStack(spacing: 10) {
                        Text(visual.title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)

                        Text(visual.subtitle)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 16)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 15)

                    dailyRoutineVisual
                        .opacity(animateOptions ? 1 : 0)
                        .scaleEffect(animateOptions ? 1 : 0.95)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animateOptions)
                } else {
                // Premium title with icon for transformation (after) page
                if visual.type == .transformationAfter {
                    VStack(spacing: 12) {
                        // Icon badge — spring in + subtle ring pulse
                        ZStack {
                            Circle()
                                .stroke(AppTheme.success.opacity(afterLifeHeaderVisible ? 0.35 : 0), lineWidth: 2)
                                .frame(width: 72, height: 72)
                                .scaleEffect(afterLifeHeaderVisible ? 1 : 0.6)
                            Circle()
                                .fill(AppTheme.success.opacity(0.15))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(AppTheme.success)
                        }
                        .opacity(afterLifeHeaderVisible ? 1 : 0)
                        .scaleEffect(afterLifeHeaderVisible ? 1 : 0.82)
                        .offset(y: afterLifeHeaderVisible ? 0 : 14)
                        .animation(.spring(response: 0.52, dampingFraction: 0.78), value: afterLifeHeaderVisible)
                        
                        Text(visual.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                            .opacity(afterLifeHeaderVisible ? 1 : 0)
                            .offset(y: afterLifeHeaderVisible ? 0 : 10)
                            .animation(.spring(response: 0.52, dampingFraction: 0.78).delay(0.04), value: afterLifeHeaderVisible)
                    }
                } else {
                    // Standard title, or personalized for screen time stats
                    if visual.type == .screenTimeStats {
                        let displayName: String = {
                            let raw = userDataManager.userName?.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let n = raw, !n.isEmpty { return n }
                            return NSLocalizedString("questionnaire.consider_this.fallback_name", comment: "there")
                        }()
                        let title = String(format: NSLocalizedString("questionnaire.stats.title_format", comment: ""), displayName)
                        Text(title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 15)
                    } else {
                        Text(visual.title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 15)
                    }
                }
                
                // Visual Illustration based on type - compact
                Group {
                    switch visual.type {
                    case .screenTimeStats:
                        screenTimeStatsVisual
                    case .phoneMockup:
                        phoneMockupVisual
                    case .lockScreen:
                        lockScreenVisual
                    case .dhikrDemo:
                        dhikrDemoVisual
                    case .unlockFlow:
                        unlockFlowVisual
                    case .transformationAfter:
                        transformationAfterVisual
                    case .dailyRoutine:
                        EmptyView()
                    }
                }
                .opacity(visual.type == .transformationAfter ? 1 : (animateOptions ? 1 : 0))
                .scaleEffect(visual.type == .transformationAfter ? 1 : (animateOptions ? 1 : 0.95))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animateOptions)
                
                // Subtitle - only show if not screenTimeStats
                if visual.type == .transformationAfter {
                    Text(visual.subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 16)
                        .opacity(afterLifeSubtitleVisible ? 1 : 0)
                        .offset(y: afterLifeSubtitleVisible ? 0 : 8)
                        .animation(.easeOut(duration: 0.42), value: afterLifeSubtitleVisible)
                } else if visual.type != .screenTimeStats {
                    Text(visual.subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 16)
                        .opacity(animateContent ? 1 : 0)
                }
                } // end non-dailyRoutine
            }
            .padding(.horizontal, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Visual Components
    
    private var screenTimeStatsVisual: some View {
        VStack(spacing: 16) {
            // Weekly Screen Time Bar Chart - Compact
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    Text(NSLocalizedString("questionnaire.stats_chart.title", comment: "Weekly Screen Time"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Spacer(minLength: 12)
                    
                    Text(NSLocalizedString("questionnaire.stats_chart.this_week", comment: "This Week"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.85, green: 0.75, blue: 0.55))
                        )
                        .fixedSize()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                // Bar Chart - Compact
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<7, id: \.self) { index in
                        let hours = [3, 4, 5, 4, 4, 5, 6][index]
                        let isSunday = index == 6
                        let dayLabels = [
                            NSLocalizedString("questionnaire.day.mon", comment: "M"),
                            NSLocalizedString("questionnaire.day.tue", comment: "T"),
                            NSLocalizedString("questionnaire.day.wed", comment: "W"),
                            NSLocalizedString("questionnaire.day.thu", comment: "T"),
                            NSLocalizedString("questionnaire.day.fri", comment: "F"),
                            NSLocalizedString("questionnaire.day.sat", comment: "S"),
                            NSLocalizedString("questionnaire.day.sun", comment: "S")
                        ]
                        
                        VStack(spacing: 6) {
                            Text(String(format: NSLocalizedString("questionnaire.hours_short", comment: "%dh"), hours))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(isSunday ? AppTheme.primary : AppTheme.textSecondary)
                                .opacity(screenTimeBarFill > 0.02 ? 1 : 0)
                                .animation(.easeOut(duration: 0.25), value: screenTimeBarFill)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isSunday ? AppTheme.primary : AppTheme.primary.opacity(0.2))
                                .frame(width: 28, height: max(4, CGFloat(hours * 14 + 16) * screenTimeBarFill))
                                .animation(.spring(response: 0.78, dampingFraction: 0.74), value: screenTimeBarFill)
                            
                            Text(dayLabels[index])
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 110)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .sdLiquidGlassCard(cornerRadius: 16)
            .opacity(screenTimeChartRevealed ? 1 : 0)
            .offset(y: screenTimeChartRevealed ? 0 : 22)
            .scaleEffect(screenTimeChartRevealed ? 1 : 0.96)
            .animation(.spring(response: 0.58, dampingFraction: 0.72), value: screenTimeChartRevealed)
            
            // Statistics Cards - Compact
            HStack(spacing: 10) {
                statCard(
                    value: "4.2",
                    unit: NSLocalizedString("questionnaire.stats.hrs_day", comment: "hrs/day"),
                    icon: "clock.fill",
                    iconColor: Color(red: 1.0, green: 0.42, blue: 0.42)
                )
                .opacity(screenTimeStatCardsRevealed ? 1 : 0)
                .offset(y: screenTimeStatCardsRevealed ? 0 : 24)
                .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0), value: screenTimeStatCardsRevealed)
                
                statCard(
                    value: "96",
                    unit: NSLocalizedString("questionnaire.stats.pickups", comment: "pickups"),
                    icon: "hand.tap.fill",
                    iconColor: AppTheme.accent
                )
                .opacity(screenTimeStatCardsRevealed ? 1 : 0)
                .offset(y: screenTimeStatCardsRevealed ? 0 : 24)
                .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.1), value: screenTimeStatCardsRevealed)
                
                statCard(
                    value: "60+",
                    unit: NSLocalizedString("questionnaire.stats.days_yr", comment: "days/yr"),
                    icon: "calendar",
                    iconColor: AppTheme.accent
                )
                .opacity(screenTimeStatCardsRevealed ? 1 : 0)
                .offset(y: screenTimeStatCardsRevealed ? 0 : 24)
                .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.2), value: screenTimeStatCardsRevealed)
            }
            
            // Conclusion text - Compact
            VStack(spacing: 2) {
                Text(NSLocalizedString("questionnaire.stats.conclusion1", comment: "Spends 4+ hours daily on their phone."))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(NSLocalizedString("questionnaire.stats.conclusion2", comment: "That's 60+ days per year lost to scrolling."))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .multilineTextAlignment(.center)
            .opacity(screenTimeFooterRevealed ? 1 : 0)
            .offset(y: screenTimeFooterRevealed ? 0 : 12)
            .animation(.easeOut(duration: 0.52), value: screenTimeFooterRevealed)
        }
    }
    
    private func statCard(value: String, unit: String, icon: String, iconColor: Color) -> some View {
        VStack(spacing: 8) {
            // Icon circle - Compact
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Value
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(iconColor)
            
            // Unit
            Text(unit)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .sdLiquidGlassCard(cornerRadius: 14)
    }
    
    private var phoneMockupVisual: some View {
        ZStack {
            // Glow behind phone
            RoundedRectangle(cornerRadius: 48)
                .fill(AppTheme.primary.opacity(0.15))
                .frame(width: 220, height: 420)
                .blur(radius: 30)
            
            // Phone frame
            RoundedRectangle(cornerRadius: 44)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "2a2a2a"), Color(hex: "1a1a1a")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 220, height: 440)
                .overlay(
                    RoundedRectangle(cornerRadius: 44)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            // Screen
            RoundedRectangle(cornerRadius: 36)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0f1724"), Color(hex: "1a2639")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 196, height: 416)
            
            // Dynamic Island
            Capsule()
                .fill(Color.black)
                .frame(width: 80, height: 28)
                .offset(y: -180)
            
            // App grid
            VStack(spacing: 24) {
                Text(NSLocalizedString("questionnaire.app_selection.choose_apps", comment: ""))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    appIcon(icon: "camera.fill", color: Color(hex: "E1306C"), locked: true, name: "Instagram")
                    appIcon(icon: "play.rectangle.fill", color: Color(hex: "FF0000"), locked: true, name: "YouTube")
                    appIcon(icon: "message.fill", color: Color(hex: "25D366"), locked: false, name: "Messages")
                    appIcon(icon: "safari.fill", color: Color(hex: "0066CC"), locked: false, name: "Safari")
                    appIcon(icon: "music.note", color: Color.black, locked: true, name: "TikTok", isTikTok: true)
                    appIcon(icon: "bird.fill", color: Color(hex: "1DA1F2"), locked: true, name: "Twitter")
                }
                .padding(.horizontal, 12)
            }
            .offset(y: 20)
        }
        .shadow(color: Color.black.opacity(0.3), radius: 40, y: 20)
    }
    
    private func appIcon(icon: String, color: Color, locked: Bool, name: String = "", isTikTok: Bool = false) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isTikTok ? [Color.black, Color(hex: "00f2ea")] : [color, color.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: color.opacity(0.4), radius: 8, y: 4)
                
                if isTikTok {
                    Text("♪")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Lock indicator - ENHANCED
                if locked {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 22, height: 22)
                            .shadow(color: AppTheme.primary.opacity(0.5), radius: 4)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 20, y: -20)
                }
            }
            
            if !name.isEmpty {
                Text(name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var lockScreenVisual: some View {
        ZStack {
            // Glow
            RoundedRectangle(cornerRadius: 48)
                .fill(AppTheme.primary.opacity(0.12))
                .frame(width: 220, height: 420)
                .blur(radius: 30)
            
            // Phone frame
            RoundedRectangle(cornerRadius: 44)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "2a2a2a"), Color(hex: "1a1a1a")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 220, height: 440)
                .overlay(
                    RoundedRectangle(cornerRadius: 44)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            // Screen with gradient
            RoundedRectangle(cornerRadius: 36)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0a1628"), Color(hex: "162033")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 196, height: 416)
            
            // Lock content - ENHANCED
            VStack(spacing: 24) {
                // App icon that's locked
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "E1306C"), Color(hex: "C13584")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                .overlay(
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 32, height: 32)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 24, y: -24)
                )
                
                VStack(spacing: 8) {
                    Text("Instagram is Locked")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Complete a good deed to unlock")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Lock icon with rings
                ZStack {
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.3), lineWidth: 3)
                        .frame(width: 76, height: 76)
                    
                    Circle()
                        .fill(AppTheme.primary.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                }
                
                // Unlock button mockup - ENHANCED
                HStack(spacing: 10) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Do a good deed")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primaryLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: AppTheme.primary.opacity(0.4), radius: 12, y: 6)
                )
            }
        }
        .shadow(color: Color.black.opacity(0.3), radius: 40, y: 20)
    }
    
    private var dhikrDemoVisual: some View {
        VStack(spacing: 28) {
            // Waveform animation - ENHANCED
            ZStack {
                // Outer rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.15 - Double(i) * 0.04), lineWidth: 2)
                        .frame(width: CGFloat(180 - i * 30), height: CGFloat(180 - i * 30))
                        .scaleEffect(pulseAnimation ? 1.0 + Double(i) * 0.05 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: pulseAnimation
                        )
                }
                
                // Center circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primary.opacity(0.25), AppTheme.primary.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 20)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                
                // "Recording" indicator
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .offset(x: 32, y: -32)
                    .opacity(pulseAnimation ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
            }
            
            // Dhikr cards - ENHANCED
            VStack(spacing: 14) {
                dhikrCard(arabic: "سُبْحَانَ الله", transliteration: "SubhanAllah", count: "✓", isComplete: true)
                dhikrCard(arabic: "الْحَمْدُ لِلَّه", transliteration: "Alhamdulillah", count: "✓", isComplete: true)
                dhikrCard(arabic: "اللَّهُ أَكْبَر", transliteration: "Allahu Akbar", count: "2/3", isComplete: false)
            }
        }
    }
    
    private func dhikrCard(arabic: String, transliteration: String, count: String, isComplete: Bool) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(arabic)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(transliteration)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            
            ZStack {
                Circle()
                    .fill(isComplete ? AppTheme.success.opacity(0.2) : AppTheme.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.success)
                } else {
                    Text(count)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isComplete ? AppTheme.success.opacity(0.3) : Color.clear, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
    }
    
    private var unlockFlowVisual: some View {
        VStack(spacing: 28) {
            // Flow diagram - ENHANCED
            HStack(spacing: 0) {
                flowStep(icon: "lock.fill", label: "Locked", color: Color(hex: "FF6B6B"), isActive: false, number: "1")
                
                // Arrow
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF6B6B").opacity(0.5), AppTheme.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 40, height: 3)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
                
                flowStep(icon: "mic.fill", label: "Dhikr", color: AppTheme.primary, isActive: true, number: "2")
                
                // Arrow
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.success],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 40, height: 3)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.success)
                }
                
                flowStep(icon: "lock.open.fill", label: "Unlocked", color: AppTheme.success, isActive: false, number: "3")
            }
            
            // Timer indicator - ENHANCED
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "timer")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlocked for 3 hours")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Then lock again & repeat the cycle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
            )
        }
    }
    
    private func flowStep(icon: String, label: String, color: Color, isActive: Bool, number: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(isActive ? 0.25 : 0.12))
                    .frame(width: 64, height: 64)
                
                if isActive {
                    Circle()
                        .stroke(color.opacity(0.4), lineWidth: 3)
                        .frame(width: 76, height: 76)
                        .scaleEffect(pulseAnimation ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isActive ? color : AppTheme.textSecondary)
        }
    }
    
    private var flowArrow: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(AppTheme.primary.opacity(0.6))
    }
    
    private var transformationAfterVisual: some View {
        VStack(spacing: 16) {
            // Soft “life unlocked” glow behind the list
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.success.opacity(afterLifeRow3 ? 0.18 : 0.06),
                                AppTheme.primary.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 160
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 24)
                    .scaleEffect(afterLifeRow3 ? 1.08 : 0.9)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: afterLifeRow3)

                VStack(spacing: 10) {
                    compactPositiveItem(
                        icon: "clock.badge.checkmark.fill",
                        text: NSLocalizedString("questionnaire.after.item1", comment: "Reclaim 2+ hours"),
                        revealed: afterLifeRow0
                    )
                    compactPositiveItem(
                        icon: "sun.horizon.fill",
                        text: NSLocalizedString("questionnaire.after.item2", comment: "Wake up for Fajr"),
                        revealed: afterLifeRow1
                    )
                    compactPositiveItem(
                        icon: "heart.fill",
                        text: NSLocalizedString("questionnaire.after.item3", comment: "Peace and barakah"),
                        revealed: afterLifeRow2
                    )
                    compactPositiveItem(
                        icon: "sparkles",
                        text: NSLocalizedString("questionnaire.after.item4", comment: "100+ daily adhkar"),
                        revealed: afterLifeRow3
                    )
                }
            }
        }
    }
    
    private func compactPositiveItem(icon: String, text: String, revealed: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.success.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.success)
            }
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textOnLight)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 8)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.success)
                .scaleEffect(revealed ? 1 : 0.35)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.success.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(AppTheme.success.opacity(0.2), lineWidth: 1)
                )
        )
        .offset(y: revealed ? 0 : 18)
        .opacity(revealed ? 1 : 0)
        .scaleEffect(revealed ? 1 : 0.97)
        .animation(.spring(response: 0.46, dampingFraction: 0.82), value: revealed)
    }
    
    private var dailyRoutineVisual: some View {
        VStack(spacing: 20) {
            // Premium animated stat cards (buddy + title + subtitle live above in visualStepView)
            HStack(spacing: 14) {
                animatedStatCard(
                    value: "87",
                    suffix: "%",
                    label: NSLocalizedString("questionnaire.stats.feel_guilty", comment: "Feel Guilty"),
                    color: Color(hex: "FF6B6B"),
                    icon: "heart.slash.fill",
                    revealed: notAloneCard0
                )
                animatedStatCard(
                    value: "96",
                    suffix: "",
                    label: NSLocalizedString("questionnaire.stats.daily_pickups", comment: "Daily Pickups"),
                    color: AppTheme.accent,
                    icon: "hand.tap.fill",
                    revealed: notAloneCard1
                )
                animatedStatCard(
                    value: "70",
                    suffix: "%",
                    label: NSLocalizedString("questionnaire.stats.want_change", comment: "Want Change"),
                    color: AppTheme.success,
                    icon: "arrow.up.heart.fill",
                    revealed: notAloneCard2
                )
            }
            
            // Inspiring quote card with premium design
            VStack(spacing: 16) {
                // Decorative top line
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, AppTheme.accent.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent.opacity(0.4), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                }
                .padding(.horizontal, 20)
                
                // Quote text with beautiful typography
                VStack(spacing: 8) {
                    Text(NSLocalizedString("questionnaire.quote.fitrah", comment: "The guilt you feel is your fitrah"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(NSLocalizedString("questionnaire.quote.change", comment: "telling you something needs to change"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accent.opacity(0.9), AppTheme.primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                
                // Decorative bottom line
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, AppTheme.primary.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                    
                    Circle()
                        .fill(AppTheme.primary.opacity(0.5))
                        .frame(width: 6, height: 6)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primary.opacity(0.3), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .sdLiquidGlassCard(cornerRadius: 20)
            .opacity(notAloneQuoteRevealed ? 1 : 0)
            .offset(y: notAloneQuoteRevealed ? 0 : 28)
            .scaleEffect(notAloneQuoteRevealed ? 1 : 0.96)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: notAloneQuoteRevealed)
        }
    }
    
    private func animatedStatCard(value: String, suffix: String, label: String, color: Color, icon: String, revealed: Bool) -> some View {
        VStack(spacing: 12) {
            // Animated icon with ring
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 2)
                    .frame(width: 52, height: 52)
                
                // Inner filled circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.25), color.opacity(0.08)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 26
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Value with suffix
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(color.opacity(0.8))
                }
            }
            
            // Label
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.card)
                
                // Accent border at top
                VStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.5))
                        .frame(width: 30, height: 3)
                        .padding(.top, 0)
                    Spacer()
                }
                
                // Border
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: color.opacity(0.15), radius: 12, y: 4)
        .opacity(revealed ? 1 : 0)
        .offset(y: revealed ? 0 : 28)
        .scaleEffect(revealed ? 1 : 0.93)
        .animation(.spring(response: 0.55, dampingFraction: 0.76), value: revealed)
    }
    
    // MARK: - Interactive Demo View (ScrollDeeds / onboarding-aligned — no heavy glows)
    
    private var interactiveDemoView: some View {
        // The continue button under this page is taller than the progress bar
        // above it, so centering in the leftover gap sits the card too high.
        GeometryReader { geo in
            let nudgeDown = min(40, geo.size.height * 0.06)
            let cardHeight = min(500, max(320, geo.size.height - nudgeDown - 8))
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                ZStack {
                    switch demoPhase {
                    case .lockedApps:   demoStep1Clean
                    case .recording:    demoStep2Clean
                    case .verifying:    demoVerifyingClean
                    case .coinsEarned:  demoCoinsClean
                    case .buyHearts:    demoBuyHeartsClean
                    case .unlocked:     demoSuccessClean
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: cardHeight)
                .sdLiquidGlassCard(cornerRadius: 28)
                .padding(.horizontal, 22)

                Spacer(minLength: 0)
            }
            .padding(.top, nudgeDown)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            demoPhase = .lockedApps
            demoReciteCount = 0
            demoCompleted = false
            demoCoinsBalance = 0
            demoHearts = 0
            demoShowSuccess = false
            demoUnlockBurst = false
            demoUnlockRing = 0.6
            demoLockBreath = false
            demoMicPulse = false
            demoHeartBeat = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    demoLockBreath = true
                }
            }
        }
    }

    /// Demo heart health climbs with each mic tap (tired → alive).
    private var demoHeartHealth: Double {
        switch demoReciteCount {
        case 0: return 18
        case 1: return 44
        case 2: return 72
        default: return 96
        }
    }

    // MARK: Step 1 — TikTok locked (recognizable app icon + clear lock state)
    private var demoStep1Clean: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 18)
            ZStack {
                Circle()
                    .stroke(AppTheme.primary.opacity(demoLockBreath ? 0.16 : 0.05), lineWidth: 1.5)
                    .frame(width: 176, height: 176)
                    .scaleEffect(demoLockBreath ? 1.10 : 0.94)
                Circle()
                    .stroke(AppTheme.primary.opacity(demoLockBreath ? 0.10 : 0.04), lineWidth: 1.5)
                    .frame(width: 156, height: 156)
                    .scaleEffect(demoLockBreath ? 1.05 : 0.97)

                demoTikTokAppIcon(locked: true)
                    .scaleEffect(demoLockBreath ? 1.02 : 0.98)
            }
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: demoLockBreath)

            Spacer().frame(height: 22)
            Text(NSLocalizedString("questionnaire.demo.step1_title", comment: "TikTok is locked"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Spacer().frame(height: 10)
            Text(NSLocalizedString("questionnaire.demo.step1_desc", comment: ""))
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)
            Spacer(minLength: 10)
            Image(systemName: "chevron.down")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.accent.opacity(0.75))
                .offset(y: demoLockBreath ? 3 : 0)
            Spacer().frame(height: 10)
            Button(action: {
                HapticManager.shared.heavy()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                    demoPhase = .recording
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        demoMicPulse = true
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text(NSLocalizedString("deed.cta", comment: "Earn coins"))
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
            }
            .buttonStyle(ActionCardButtonStyle())
            .padding(.horizontal, 24)
            Spacer(minLength: 18)
        }
    }

    /// Real TikTok brand mark — locked (dim + lock) or unlocked (open badge).
    private func demoTikTokAppIcon(locked: Bool) -> some View {
        let iconSize: CGFloat = 120
        let corner: CGFloat = 30
        let badge: CGFloat = 38

        return ZStack(alignment: .bottomTrailing) {
            ZStack {
                Image("TikTokLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                    .shadow(
                        color: locked ? Color.black.opacity(0.22) : AppTheme.success.opacity(0.28),
                        radius: 16,
                        y: 8
                    )

                if locked {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(Color.black.opacity(0.32))
                        .frame(width: iconSize, height: iconSize)
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(AppTheme.primary.opacity(0.55), lineWidth: 2)
                        .frame(width: iconSize, height: iconSize)
                } else {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(AppTheme.success.opacity(0.65), lineWidth: 2.5)
                        .frame(width: iconSize, height: iconSize)
                }
            }

            ZStack {
                Circle()
                    .fill(locked ? AppTheme.primary : AppTheme.success)
                    .frame(width: badge, height: badge)
                    .shadow(
                        color: (locked ? AppTheme.primary : AppTheme.success).opacity(0.4),
                        radius: 6,
                        y: 2
                    )
                Circle()
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                    .frame(width: badge, height: badge)
                Image(systemName: locked ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: locked ? 15 : 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .offset(x: 7, y: 7)
        }
        .frame(width: 136, height: 136)
        .accessibilityLabel(
            NSLocalizedString(
                locked ? "questionnaire.demo.step1_title" : "questionnaire.demo.success_title",
                comment: ""
            )
        )
    }

    // MARK: Step 2 — dhikr taps (+ dashboard heart between count & mic)
    private var demoStep2Clean: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            VStack(spacing: 8) {
                Text("سُبْحَانَ اللَّهِ")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("SubhanAllah")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 16)

            HStack(spacing: 18) {
                ForEach(0..<3, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(index < demoReciteCount ? AppTheme.primary.opacity(0.18) : AppTheme.muted)
                            .frame(width: 52, height: 52)
                        Circle()
                            .strokeBorder(
                                index < demoReciteCount ? AppTheme.primary.opacity(0.9) : AppTheme.border,
                                lineWidth: 1.5
                            )
                            .frame(width: 52, height: 52)
                        if index < demoReciteCount {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.accent)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(index == demoReciteCount ? AppTheme.textPrimary : AppTheme.textMuted)
                        }
                    }
                    .animation(.spring(response: 0.32, dampingFraction: 0.72), value: demoReciteCount)
                }
            }

            // Natural band between counters and mic — same heart language as home
            Spacer().frame(height: 12)
            CompactHeartView(health: demoHeartHealth, beatScale: demoHeartBeat)
                .frame(width: 100, height: 100)
                .accessibilityHidden(true)
            Spacer().frame(height: 12)

            Button(action: {
                guard demoReciteCount < 3 else { return }
                HapticManager.shared.heavy()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.65)) {
                    demoMicPulse.toggle()
                }
                // Heart “beat” + climb toward healthier
                withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                    demoHeartBeat = 1.08
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                        demoHeartBeat = 1
                    }
                }
                withAnimation(.easeInOut(duration: 0.35)) {
                    demoReciteCount += 1
                }
                if demoReciteCount >= 3 {
                    HapticManager.shared.success()
                    // Let the heart finish brightening before leaving the step
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                        withAnimation(.easeInOut(duration: 0.55)) {
                            demoPhase = .verifying
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                            demoCoinsBalance = NafsiLivesManager.coinCostPerHeart * NafsiLivesManager.fallbackCapacity
                            withAnimation(.easeInOut(duration: 0.55)) {
                                demoPhase = .coinsEarned
                            }
                        }
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.25), lineWidth: 2)
                        .frame(width: 118, height: 118)
                        .scaleEffect(demoMicPulse ? 1.22 : 0.88)
                        .opacity(demoMicPulse ? 0 : 0.55)
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.28), lineWidth: 2)
                        .frame(width: 104, height: 104)
                        .scaleEffect(demoMicPulse ? 1.12 : 0.92)
                        .opacity(demoMicPulse ? 0 : 0.45)
                    Circle()
                        .fill(AppTheme.gradientPrimary)
                        .frame(width: 88, height: 88)
                        .scaleEffect(demoMicPulse ? 0.94 : 1.0)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                }
                .shadow(color: AppTheme.primary.opacity(0.28), radius: 12, y: 5)
                .animation(.spring(response: 0.35, dampingFraction: 0.62), value: demoMicPulse)
            }
            .disabled(demoReciteCount >= 3)

            Spacer(minLength: 16)
        }
    }

    // MARK: Verifying
    private var demoVerifyingClean: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)
            TimelineView(.animation(minimumInterval: 1.0 / 45.0, paused: false)) { context in
                let seconds = context.date.timeIntervalSinceReferenceDate
                let degrees = (seconds.truncatingRemainder(dividingBy: 1.2)) / 1.2 * 360.0
                ZStack {
                    Circle()
                        .stroke(AppTheme.border, lineWidth: 4)
                        .frame(width: 104, height: 104)
                    Circle()
                        .trim(from: 0, to: 0.28)
                        .stroke(
                            LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 104, height: 104)
                        .rotationEffect(.degrees(degrees))
                    Image(systemName: "waveform")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(AppTheme.primaryLight)
                }
            }
            Spacer().frame(height: 24)
            Text(NSLocalizedString("questionnaire.demo.verifying_title", comment: "Verifying..."))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            Spacer().frame(height: 10)
            Text(NSLocalizedString("questionnaire.demo.verifying_desc", comment: ""))
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer(minLength: 20)
        }
    }

    // MARK: Coins — same reward as a finished deed

    private var demoCoinsClean: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(AppTheme.primary.opacity(0.08))
                    .frame(width: 76, height: 76)
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.primaryLight, AppTheme.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Spacer().frame(height: 18)
            Text(NSLocalizedString("task.confirmation.title", comment: "MashaAllah"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)

            Spacer().frame(height: 16)
            DeedCoinBadge(coins: NafsiLivesManager.coinCostPerHeart * NafsiLivesManager.fallbackCapacity, size: 20)
                .foregroundColor(AppTheme.textPrimary)

            Spacer().frame(height: 14)
            Text(NSLocalizedString("questionnaire.demo.coins_desc", comment: ""))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)

            Spacer().frame(height: 22)
            Button {
                HapticManager.shared.soft()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                    demoPhase = .buyHearts
                }
            } label: {
                Text(NSLocalizedString("questionnaire.demo.continue", comment: "Continue"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(ActionCardButtonStyle())
            .padding(.horizontal, 24)

            Spacer(minLength: 18)
        }
    }

    // MARK: Buy a heart, then TikTok opens

    private var demoBuyHeartsClean: some View {
        let pack = NafsiLivesManager.fallbackCapacity
        let cost = NafsiLivesManager.coinCostPerHeart

        return VStack(spacing: 0) {
            Spacer(minLength: 16)

            NafsiHeartsRow(hearts: demoHearts, maxHearts: pack, size: 26)
                .padding(.bottom, 16)

            HStack(spacing: 8) {
                NafsiCoinGlyph(size: 22)
                Text("\(demoCoinsBalance)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            Spacer().frame(height: 18)
            Text(String(format: NSLocalizedString("questionnaire.demo.buy_title", comment: "Buy hearts"), pack))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 8)
            Text(String(format: NSLocalizedString("questionnaire.demo.buy_desc", comment: ""), pack))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)

            Spacer().frame(height: 22)
            Button {
                guard demoHearts < pack, demoCoinsBalance >= cost else { return }
                HapticManager.shared.success()
                let filled = demoHearts + 1
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    demoCoinsBalance -= cost
                    demoHearts = filled
                }
                guard filled >= pack else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.easeInOut(duration: 0.55)) {
                        demoPhase = .unlocked
                        demoCompleted = true
                    }
                }
            } label: {
                Text(String(
                    format: NSLocalizedString("questionnaire.demo.buy_cta", comment: "Buy 1 heart · coins"),
                    cost
                ))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(ActionCardButtonStyle())
            .padding(.horizontal, 24)
            .disabled(demoHearts >= pack)
            .opacity(demoHearts >= pack ? 0.55 : 1)

            Spacer(minLength: 18)
        }
    }

    // MARK: Success — TikTok unlocked
    private var demoSuccessClean: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            AppTheme.success.opacity(demoUnlockBurst ? 0 : 0.35 - Double(i) * 0.08),
                            lineWidth: 2
                        )
                        .frame(width: 136 + CGFloat(i) * 34, height: 136 + CGFloat(i) * 34)
                        .scaleEffect(demoUnlockBurst ? (1.5 + CGFloat(i) * 0.18) : demoUnlockRing)
                        .opacity(demoUnlockBurst ? 0 : 1)
                }
                demoTikTokAppIcon(locked: false)
                    .scaleEffect(demoShowSuccess ? 1 : 0.55)
                    .rotationEffect(.degrees(demoShowSuccess ? 0 : -12))
            }
            .scaleEffect(demoShowSuccess ? 1 : 0.72)
            .opacity(demoShowSuccess ? 1 : 0)
            Spacer().frame(height: 22)
            Text(NSLocalizedString("questionnaire.demo.success_title", comment: "TikTok unlocked!"))
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.success)
                .opacity(demoShowSuccess ? 1 : 0)
                .offset(y: demoShowSuccess ? 0 : 10)
            Spacer().frame(height: 10)
            Text(NSLocalizedString("questionnaire.demo.success_desc", comment: ""))
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(demoShowSuccess ? 1 : 0)
            Spacer().frame(height: 16)
            Text(NSLocalizedString("questionnaire.demo.thats_it", comment: "That's how it works!"))
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [AppTheme.primaryLight, AppTheme.primary], startPoint: .leading, endPoint: .trailing)
                )
                .opacity(demoShowSuccess ? 1 : 0)
                .scaleEffect(demoShowSuccess ? 1 : 0.92)
            Spacer(minLength: 20)
        }
        .onAppear {
            demoUnlockBurst = false
            demoUnlockRing = 0.7
            withAnimation(.spring(response: 0.5, dampingFraction: 0.68)) {
                demoShowSuccess = true
            }
            withAnimation(.easeOut(duration: 0.9)) {
                demoUnlockBurst = true
                demoUnlockRing = 1.4
            }
            HapticManager.shared.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                HapticManager.shared.heavy()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                HapticManager.shared.success()
            }
        }
    }
    
    // MARK: - App Selection View
    
    private var appSelectionStepView: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "lock.iphone")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(AppTheme.primary)
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.8)
            
            // Title
            VStack(spacing: 12) {
                Text(NSLocalizedString("questionnaire.app_selection.title", comment: "Which apps steal your time"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(NSLocalizedString("questionnaire.app_selection.subtitle", comment: "Select apps to lock"))
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(NSLocalizedString("questionnaire.app_selection.optional", comment: "Optional step"))
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .opacity(animateContent ? 1 : 0)
            
            // App selection content
            VStack(spacing: 20) {
                #if canImport(FamilyControls)
                if #available(iOS 16.0, *) {
                    if shieldManager.hasShieldTargets {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.success)
                                .font(.system(size: 22))
                            Text(String(format: NSLocalizedString("questionnaire.app_selection.apps_selected", comment: "X apps selected"), shieldManager.pickerSelectionCount))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppTheme.success.opacity(0.1))
                        )
                    }
                    
                    Button(action: {
                        HapticManager.shared.medium()
                        requestFamilyControlsAndPresentPicker()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: !shieldManager.hasShieldTargets ? "plus.app.fill" : "arrow.triangle.2.circlepath")
                                .font(.system(size: 22))
                            Text(!shieldManager.hasShieldTargets ? NSLocalizedString("questionnaire.app_selection.choose_apps", comment: "Choose apps") : NSLocalizedString("questionnaire.app_selection.change", comment: "Change selection"))
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(ActionCardButtonStyle())
                    .familyActivityPicker(isPresented: $isAppPickerPresented, selection: $appSelection)
                }
                #endif
            }
            .opacity(animateOptions ? 1 : 0)
        }
        .padding(.horizontal, 28)
    }
    
    // MARK: - Difficulty Selection (after app selection, before CommitmentView)
    
    private func difficultyTint(for index: Int) -> Color {
        switch index {
        case 0:
            return Color(red: 0.28, green: 0.70, blue: 0.48)
        case 1:
            return Color(red: 0.94, green: 0.62, blue: 0.22)
        default:
            return Color(red: 0.88, green: 0.38, blue: 0.42)
        }
    }
    
    private func difficultyUnlockMinutes(for index: Int) -> Int {
        UserDataManager.onboardingUnlockMinutes(forDifficultyLevel: index)
    }
    
    private func difficultyBadgeString(for index: Int) -> String {
        let m = difficultyUnlockMinutes(for: index)
        return String(format: NSLocalizedString("questionnaire.difficulty.minutes_badge", comment: "%d min"), m)
    }
    
    /// Same chrome as `questionStepView` / referral; no inner scroll — full text wraps, never truncated.
    private var difficultySelectionStepView: some View {
        let title = NSLocalizedString("questionnaire.difficulty.title", comment: "Difficulty title")
        let subtitle = NSLocalizedString("questionnaire.difficulty.subtitle", comment: "Difficulty subtitle")
        return GeometryReader { geo in
            let pad = max(geo.size.height * 0.028, 10)
            VStack(spacing: 0) {
                Spacer(minLength: pad)
                
                VStack(spacing: 22) {
                    OnboardingHeroEmojiIcon(
                        emoji: "🎚️",
                        glowColor: AppTheme.primary,
                        revealed: animateContent
                    )
                    
                    VStack(spacing: 10) {
                        Text(title)
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitle)
                            .font(.system(size: 17))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                }
                .padding(.top, 8)
                
                VStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { idx in
                        difficultyOptionRow(index: idx, isSelected: answers[step] == idx)
                            .opacity(isTransitioning ? 0.6 : 1.0)
                            .disabled(isTransitioning)
                            .onTapGesture {
                                guard !isTransitioning else { return }
                                triggerOptionSelectionHaptic(optionIndex: idx)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    answers[step] = idx
                                }
                                userDataManager.setOnboardingDifficultyLevel(idx)
                                AnalyticsManager.shared.trackOnboardingAnswer(
                                    step: step,
                                    stepName: title,
                                    stepIdentifier: getStepIdentifier(for: step),
                                    answerIndex: idx,
                                    answerText: AnalyticsAnswerLabel.difficulty(level: idx)
                                )
                                AnalyticsManager.shared.trackOnboardingDifficultySelected(
                                    level: AnalyticsAnswerLabel.difficulty(level: idx),
                                    unlockMinutes: UserDataManager.onboardingUnlockMinutes(forDifficultyLevel: idx),
                                    source: "onboarding"
                                )
                            }
                            .opacity(animateOptions ? 1 : 0)
                            .offset(y: animateOptions ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(idx) * 0.06),
                                value: animateOptions
                            )
                    }
                }
                .padding(.top, 14)
                .padding(.bottom, 8)
                
                Spacer(minLength: pad)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard answers[step] == nil else { return }
            answers[step] = 1
            userDataManager.setOnboardingDifficultyLevel(1)
            AnalyticsManager.shared.trackOnboardingAnswer(
                step: step,
                stepName: title,
                stepIdentifier: getStepIdentifier(for: step),
                answerIndex: 1,
                answerText: AnalyticsAnswerLabel.difficulty(level: 1),
                selectionSource: "default"
            )
        }
    }
    
    private func difficultyOptionTitle(_ index: Int) -> String {
        switch index {
        case 0: return NSLocalizedString("questionnaire.difficulty.option.easy.title", comment: "")
        case 1: return NSLocalizedString("questionnaire.difficulty.option.medium.title", comment: "")
        default: return NSLocalizedString("questionnaire.difficulty.option.hard.title", comment: "")
        }
    }
    
    private func difficultyOptionSubtitle(_ index: Int) -> String {
        switch index {
        case 0: return NSLocalizedString("questionnaire.difficulty.option.easy.subtitle", comment: "")
        case 1: return NSLocalizedString("questionnaire.difficulty.option.medium.subtitle", comment: "")
        default: return NSLocalizedString("questionnaire.difficulty.option.hard.subtitle", comment: "")
        }
    }
    
    /// Matches `optionButton` chrome; level name is tint-colored; minutes pill sits in the card’s top-trailing corner.
    private func difficultyOptionRow(index: Int, isSelected: Bool) -> some View {
        let tint = difficultyTint(for: index)
        let pillFill = tint.opacity(isSelected ? 0.24 : 0.16)
        let pillStroke = tint.opacity(isSelected ? 0.45 : 0.32)
        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .strokeBorder(isSelected ? AppTheme.primary : AppTheme.textMuted.opacity(0.3), lineWidth: 2)
                    .frame(width: 26, height: 26)
                if isSelected {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 14, height: 14)
                }
            }
            .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    Text(difficultyOptionTitle(index))
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 4)
                    Text(difficultyBadgeString(for: index))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(tint)
                        .fixedSize()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule(style: .continuous).fill(pillFill))
                        .overlay(Capsule(style: .continuous).strokeBorder(pillStroke, lineWidth: 1))
                }
                Text(difficultyOptionSubtitle(index))
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? AppTheme.primary.opacity(0.08) : AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isSelected ? AppTheme.primary.opacity(0.4) : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: isSelected ? AppTheme.primary.opacity(0.15) : Color.black.opacity(0.03), radius: 8, y: 3)
    }
    
    // MARK: - Bottom Button Area
    
    @ViewBuilder
    private var bottomButtonArea: some View {
        // Immersive auto-play steps: no chrome at the bottom
        if case .demoNotification = steps[step] {
            EmptyView()
        } else if isAutoAdvancePrayerLock {
            EmptyView()
        } else {
        VStack(spacing: 12) {
            // For question types (auto-advance), only show back button
            if shouldHideButton {
                HStack {
                    // Back button for questions
                    if step > 0 {
                        Button(action: {
                            HapticManager.shared.soft()
                            withAnimation(.easeInOut(duration: 0.4)) {
                                step -= 1
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(NSLocalizedString("questionnaire.back", comment: "Back"))
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(AppTheme.card.opacity(0.8))
                            .cornerRadius(18)
                        }
                    }
                    Spacer()
                }
            } else {
                // Normal button area for other types
                VStack(spacing: 12) {
                    if showsOtherAnswerField {
                        otherAnswerField
                    }
                HStack(spacing: 12) {
                    // Back button - only show if not on first step and not centered content
                    if step > 0 && !shouldCenterContent {
                        Button(action: {
                            HapticManager.shared.soft()
                            withAnimation(.easeInOut(duration: 0.4)) {
                                step -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 56, height: 56)
                                .background(AppTheme.card)
                                .cornerRadius(20)
                        }
                    }
                    
                    Button(action: {
                        // Enhanced haptic sequence for button press
                        triggerButtonHaptic()
                        
                        // Debug logging
                        debugPrint("🔵 Button pressed on step \(step)/\(steps.count - 1)")
                        debugPrint("🔵 isButtonDisabled: \(isButtonDisabled)")
                        debugPrint("🔵 step < steps.count - 1: \(step < steps.count - 1)")
                        
                        guard !isButtonDisabled else {
                            debugPrint("⚠️ Button is disabled, cannot proceed")
                            return
                        }
                        
                        // Ensure we're on main thread
                        if Thread.isMainThread {
                            handleButtonAction()
                        } else {
                            DispatchQueue.main.async {
                                self.handleButtonAction()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(buttonText)
                                .font(.system(size: isGuideMuslimsStep ? 16 : 18, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .allowsTightening(true)
                            
                            if step < steps.count - 1 && !isGuideMuslimsStep {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 17)
                    }
                    .buttonStyle(ActionCardButtonStyle())
                    .disabled(isButtonDisabled)
                    .opacity(shouldRevealContinueButton ? 1 : 0)
                    .allowsHitTesting(shouldRevealContinueButton)
                    .animation(.easeIn(duration: 0.35), value: shouldRevealContinueButton)
                }
                }

               
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, shouldCenterContent || shouldHideButton ? 12 : 20)
        .padding(.bottom, otherFieldKeyboardLift)
        .background(
            Group {
                if showsOtherAnswerField {
                    AppTheme.background
                } else if shouldCenterContent || shouldHideButton {
                    // No background for info/visual/commitment/question pages
                    Color.clear
                } else {
                    // Card background for other pages
                    AppTheme.card
                        .shadow(color: Color.black.opacity(0.1), radius: 20, y: -10)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
        )
        } // end non-demoNotification chrome
    }
    
    // MARK: - Helper Views & Functions

    private var otherAnswerField: some View {
        TextField(
            NSLocalizedString("questionnaire.other_placeholder", comment: "Type here..."),
            text: Binding(
                get: { otherAnswers[step] ?? "" },
                set: { otherAnswers[step] = $0 }
            )
        )
        .focused($otherInputFocused)
        .textInputAutocapitalization(.sentences)
        .submitLabel(.done)
        .font(.system(size: 17, weight: .medium, design: .rounded))
        .foregroundColor(AppTheme.textPrimary)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            otherInputFocused ? AppTheme.primary.opacity(0.45) : AppTheme.border,
                            lineWidth: otherInputFocused ? 2 : 1
                        )
                )
        )
        .onSubmit { otherInputFocused = false }
    }
    
    private func optionButton(text: String, isSelected: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .strokeBorder(isSelected ? AppTheme.primary : AppTheme.textMuted.opacity(0.3), lineWidth: 2)
                    .frame(width: 26, height: 26)
                
                if isSelected {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 14, height: 14)
                }
            }
            
            Text(text)
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? AppTheme.primary.opacity(0.08) : AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isSelected ? AppTheme.primary.opacity(0.4) : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: isSelected ? AppTheme.primary.opacity(0.15) : Color.black.opacity(0.03), radius: 8, y: 3)
    }
    
    private var buttonText: String {
        switch safeCurrentStep {
        case .info(let info):
            if info.visualDemo == .fajrSetup {
                return fajrAlarm.selectedObject != nil
                    ? NSLocalizedString("questionnaire.fajr_setup.turn_on", comment: "Turn alarm on")
                    : NSLocalizedString("questionnaire.fajr_setup.skip", comment: "Skip")
            }
            if isJoinMuslimsInfoStep(info) {
                return NSLocalizedString("questionnaire.continue", comment: "Continue")
            }
            return NSLocalizedString("questionnaire.continue", comment: "Continue")
        case .prayerLock(let prayerLock):
            if let ctaKey = prayerLock.ctaKey {
                return NSLocalizedString(ctaKey, comment: "")
            }
            return NSLocalizedString("questionnaire.tap_to_continue", comment: "Tap to continue")
        case .reflection, .considerThis, .impactStats, .planIntro, .demoNotification, .allowNotifications, .patienceQuote:
            return NSLocalizedString("questionnaire.tap_to_continue", comment: "Tap to continue")
        case .guideMuslims:
            return NSLocalizedString("onboarding.guide_muslims.cta", comment: "Guide other Muslims")
        case .nameInput:
            return NSLocalizedString("questionnaire.continue", comment: "Continue")
        case .question, .referralSource, .appIconPicker:
            return NSLocalizedString("questionnaire.continue", comment: "Continue")
        case .sliderQuestion:
            return NSLocalizedString("questionnaire.continue", comment: "Continue")
        case .ageSelection:
            return NSLocalizedString("questionnaire.continue", comment: "Continue")
        case .appSelection:
            return !shieldManager.hasShieldTargets ? NSLocalizedString("questionnaire.skip_for_now", comment: "Skip for Now") : NSLocalizedString("questionnaire.continue", comment: "Continue")
        case .difficultySelection:
            return NSLocalizedString("questionnaire.continue", comment: "Continue")
        case .commitment:
            return commitmentAccepted[step] == true ? NSLocalizedString("questionnaire.i_commit", comment: "I Commit") : NSLocalizedString("questionnaire.make_commitment", comment: "Make Commitment")
        case .visual:
            return NSLocalizedString("questionnaire.continue", comment: "Continue")
        case .interactiveDemo:
            return demoCompleted ? NSLocalizedString("questionnaire.demo.continue", comment: "Continue") : NSLocalizedString("questionnaire.demo.complete_demo", comment: "Complete the demo")
        case .streakPreview:
            return NSLocalizedString("onboarding.streak.cta_continue", comment: "Continue")
        case nil:
            return NSLocalizedString("questionnaire.continue", comment: "Continue")
        }
    }
    
    /// Continue button only visible after all text and animation for this step are complete
    private var shouldRevealContinueButton: Bool {
        switch safeCurrentStep {
        case .info:
            return infoAnimationComplete
        case .reflection:
            return reflectionAnimationComplete
        case .prayerLock(let prayerLock):
            if prayerLock.autoAdvanceAfterSeconds != nil { return false }
            return prayerLockAnimationComplete
        case .planIntro:
            return planIntroAnimationComplete
        case .allowNotifications:
            return allowNotificationsReady
        case .patienceQuote:
            return patienceQuoteReady
        case .guideMuslims:
            return guideMuslimsReady
        case .appIconPicker:
            return appIconPickerRevealed
        case .visual(let v) where v.type == .transformationAfter:
            return afterLifeAnimationComplete
        case .considerThis:
            return false
        case .impactStats:
            return impactStatsAnimationComplete
        default:
            return true
        }
    }
    
    private var isButtonDisabled: Bool {
        // Disable button during transition to prevent rapid clicking
        if isTransitioning {
            return true
        }
        
        switch safeCurrentStep {
        case .info:
            // Disable button until info page animation is complete
            return !infoAnimationComplete
        case .reflection:
            return !reflectionAnimationComplete
        case .prayerLock(let prayerLock):
            if prayerLock.autoAdvanceAfterSeconds != nil { return true }
            return !prayerLockAnimationComplete
        case .considerThis:
            return !considerThisAnimationComplete
        case .impactStats:
            return !impactStatsAnimationComplete
        case .planIntro:
            return !planIntroAnimationComplete
        case .allowNotifications:
            return !allowNotificationsReady
        case .patienceQuote:
            return !patienceQuoteReady
        case .guideMuslims:
            return !guideMuslimsReady
        case .appIconPicker:
            return selectedTimeApps.isEmpty
        case .nameInput:
            return enteredName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .visual(let v) where v.type == .transformationAfter:
            return !afterLifeAnimationComplete
        case .visual, .appSelection, .sliderQuestion, .ageSelection:
            return false  // Slider and age picker always have a value (default or user-selected)
        case .difficultySelection:
            return answers[step] == nil
        case .question(let question) where isOtherAnswerSelected(question):
            return otherAnswerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .question, .referralSource:
            return answers[step] == nil
        case .commitment:
            return commitmentAccepted[step] != true
        case .interactiveDemo:
            return !demoCompleted  // Must complete the demo to continue
        case .demoNotification:
            return true
        case .streakPreview:
            return false
        case nil:
            return true
        }
    }
    
    private func resetAnimations() {
        animateContent = false
        animateOptions = false
        isTransitioning = false // Reset transition state when new step starts
        dismissOnboardingKeyboard()
        
        // Reset info page animation states
        infoIconVisible = false
        infoTitleVisible = false
        infoSubtitleVisible = false
        infoFeaturesVisible = [:]
        infoAnimationComplete = false
        joinReviewsVisible = false
        joinReviewPage = 0
        
        // Reset reflection step animation states
        reflectionTitleVisible = false
        reflectionLineVisible = [:]
        reflectionAnimationComplete = false
        
        prayerLockLineVisible = [:]
        prayerLockAnimationComplete = false
        prayerLockCardsVisible = false
        prayerLockDissolving = false
        typewriterRunner.cancel()
        narrativeTypedCount = [:]
        
        nameInputSubtitleVisible = false
        nameInputTitleVisible = false
        nameInputFieldVisible = false
        considerThisVisible = false
        considerThisAnimationComplete = false
        impactStatsLineVisible = [:]
        impactStatsAnimationComplete = false
        impactHeroVisible = false
        impactHeroScale = 0.7
        impactHeroYears = 0
        impactIconsRevealed = 0
        impactCountedHours = 0
        impactCountedDays = 0
        impactStatsSequenceID = UUID()
        planIntroLineVisible = [:]
        planIntroAnimationComplete = false
        allowNotificationsReady = false
        patienceQuoteReady = false
        guideMuslimsReady = false
        appIconPickerRevealed = false
        spiritualTypesExpanded = false
        
        screenTimeChartRevealed = false
        screenTimeBarFill = 0
        screenTimeStatCardsRevealed = false
        screenTimeFooterRevealed = false
        notAloneCard0 = false
        notAloneCard1 = false
        notAloneCard2 = false
        notAloneQuoteRevealed = false
        notAloneBuddyRevealed = false
        
        afterLifeHeaderVisible = false
        afterLifeRow0 = false
        afterLifeRow1 = false
        afterLifeRow2 = false
        afterLifeRow3 = false
        afterLifeSubtitleVisible = false
        afterLifeAnimationComplete = false

        demoLockBreath = false
        demoMicPulse = false
        demoHeartBeat = 1
        demoUnlockBurst = false
        demoUnlockRing = 0.6
        demoShowSuccess = false
    }
    
    private func startAnimations() {
        pulseAnimation = true
        
        // Strategic haptic feedback when step appears
        if !hasTriggeredStepHaptic {
            triggerStepTransitionHaptic()
            hasTriggeredStepHaptic = true
        }
        
        // Check if current step is an info step
        if case .info(let infoStep) = safeCurrentStep {
            startInfoPageAnimations(info: infoStep)
        } else if case .reflection(let reflectionStep) = safeCurrentStep {
            startReflectionAnimations(reflection: reflectionStep)
        } else if case .prayerLock(let prayerLockStep) = safeCurrentStep {
            startPrayerLockAnimations(step: prayerLockStep)
        } else if case .nameInput = safeCurrentStep {
            startNameInputAnimations()
        } else if case .considerThis = safeCurrentStep {
            startConsiderThisAnimations()
        } else if case .impactStats(let impactStep) = safeCurrentStep {
            startImpactStatsAnimations(impactStep: impactStep)
        } else if case .planIntro(let planStep) = safeCurrentStep {
            startPlanIntroAnimations(step: planStep)
        } else if case .allowNotifications = safeCurrentStep {
            allowNotificationsReady = false
            let delay = OnboardingFunnelConfig.showcaseDelayPerElement
            let fade = OnboardingFunnelConfig.showcaseFadeDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + delay * 4 + fade + 0.15) {
                allowNotificationsReady = true
            }
        } else if case .patienceQuote = safeCurrentStep {
            patienceQuoteReady = false
        } else if case .guideMuslims = safeCurrentStep {
            guideMuslimsReady = false
            let delay = OnboardingFunnelConfig.narrativeDelayPerElement
            let fade = OnboardingFunnelConfig.narrativeFadeDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + delay * 3 + fade + 0.15) {
                guideMuslimsReady = true
            }
        } else if case .appIconPicker = safeCurrentStep {
            appIconPickerRevealed = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.95)) {
                    appIconPickerRevealed = true
                }
                HapticManager.shared.animationReveal(beat: 0)
            }
        } else if case .visual(let v) = safeCurrentStep {
            switch v.type {
            case .screenTimeStats:
                startVisualScreenTimeAnimations()
            case .dailyRoutine:
                startVisualDailyRoutineAnimations()
            case .transformationAfter:
                startTransformationAfterAnimations()
            default:
                withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                    animateContent = true
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
                    animateOptions = true
                }
                scheduleQuestionRevealHaptics()
            }
        } else {
            // Original animations for non-info steps
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                animateContent = true
            }
            
            withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
                animateOptions = true
            }
            scheduleQuestionRevealHaptics()
        }
    }

    private func scheduleQuestionRevealHaptics() {
        HapticManager.shared.scheduleAnimationReveal(after: 0.1, beat: 0)
        let optionCount: Int
        switch safeCurrentStep {
        case .question(let question):
            optionCount = question.options.count
        case .referralSource:
            optionCount = Self.referralSourceSlugs.count
        case .difficultySelection:
            optionCount = 3
        default:
            optionCount = 1
        }
        for index in 0..<optionCount {
            HapticManager.shared.scheduleAnimationReveal(after: 0.25 + Double(index) * 0.06, beat: index + 1)
        }
    }
    
    /// Weekly screen time chart: title → card → bars grow → stat pills → footer copy.
    private func startVisualScreenTimeAnimations() {
        screenTimeChartRevealed = false
        screenTimeBarFill = 0
        screenTimeStatCardsRevealed = false
        screenTimeFooterRevealed = false
        
        withAnimation(.easeOut(duration: 0.48)) {
            animateContent = true
        }
        HapticManager.shared.animationReveal(beat: 0)
        withAnimation(.easeOut(duration: 0.2)) {
            animateOptions = true
        }
        withAnimation(.spring(response: 0.58, dampingFraction: 0.72).delay(0.06)) {
            screenTimeChartRevealed = true
        }
        HapticManager.shared.scheduleAnimationReveal(after: 0.06, beat: 1)
        withAnimation(.spring(response: 0.78, dampingFraction: 0.74).delay(0.16)) {
            screenTimeBarFill = 1
        }
        HapticManager.shared.scheduleAnimationReveal(after: 0.16, beat: 2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.78)) {
                screenTimeStatCardsRevealed = true
            }
            HapticManager.shared.animationReveal(beat: 3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.92) {
            withAnimation(.easeOut(duration: 0.52)) {
                screenTimeFooterRevealed = true
            }
            HapticManager.shared.animationReveal(beat: 4)
        }
    }
    
    /// “You’re not alone”: companion → staggered stat cards → quote card.
    private func startVisualDailyRoutineAnimations() {
        notAloneBuddyRevealed = false
        notAloneCard0 = false
        notAloneCard1 = false
        notAloneCard2 = false
        notAloneQuoteRevealed = false
        
        withAnimation(.easeOut(duration: 0.48)) {
            animateContent = true
        }
        HapticManager.shared.animationReveal(beat: 0)
        withAnimation(.easeOut(duration: 0.18)) {
            animateOptions = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.spring(response: 0.58, dampingFraction: 0.84)) {
                notAloneBuddyRevealed = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.56, dampingFraction: 0.74)) {
                notAloneCard0 = true
            }
            HapticManager.shared.animationReveal(beat: 1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.spring(response: 0.56, dampingFraction: 0.74)) {
                notAloneCard1 = true
            }
            HapticManager.shared.animationReveal(beat: 2)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            withAnimation(.spring(response: 0.56, dampingFraction: 0.74)) {
                notAloneCard2 = true
            }
            HapticManager.shared.animationReveal(beat: 3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                notAloneQuoteRevealed = true
            }
            HapticManager.shared.animationReveal(beat: 4)
        }
    }
    
    /// "Your Life With ScrollDeeds": calm stagger → enable Continue.
    private func startTransformationAfterAnimations() {
        afterLifeHeaderVisible = false
        afterLifeRow0 = false
        afterLifeRow1 = false
        afterLifeRow2 = false
        afterLifeRow3 = false
        afterLifeSubtitleVisible = false
        afterLifeAnimationComplete = false
        
        withAnimation(narrativeRevealAnimation(delay: 0.0)) {
            afterLifeHeaderVisible = true
        }
        HapticManager.shared.animationReveal(beat: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(narrativeRevealAnimation(delay: 0)) { afterLifeRow0 = true }
            HapticManager.shared.soft()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(narrativeRevealAnimation(delay: 0)) { afterLifeRow1 = true }
            HapticManager.shared.soft()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
            withAnimation(narrativeRevealAnimation(delay: 0)) { afterLifeRow2 = true }
            HapticManager.shared.soft()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(narrativeRevealAnimation(delay: 0)) { afterLifeRow3 = true }
            HapticManager.shared.soft()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.85) {
            withAnimation(narrativeRevealAnimation(delay: 0)) {
                afterLifeSubtitleVisible = true
            }
            HapticManager.shared.animationReveal(beat: 5)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            afterLifeAnimationComplete = true
        }
    }
    
    // MARK: - Info Page Staggered Animation
    
    private func startInfoPageAnimations(info: InfoStep) {
        let isJoinMuslims = isJoinMuslimsInfoStep(info)
        if isJoinMuslims {
            withAnimation(narrativeRevealAnimation(delay: 0.0)) {
                infoIconVisible = true
            }
            let title = NSLocalizedString("questionnaire.join.title", comment: "")
            let subtitle = NSLocalizedString("questionnaire.join.subtitle", comment: "")
            startNarrativeTypewriter(lines: [title, subtitle]) {
                withAnimation(.easeInOut(duration: 0.45)) {
                    infoSubtitleVisible = true
                    joinReviewsVisible = true
                }
                HapticManager.shared.animationReveal(beat: 2)
                infoAnimationComplete = true
            }
            return
        }

        if info.visualDemo == .fajrPhotoAlarm || info.visualDemo == .fajrSetup || info.visualDemo == .widgetDesire {
            // These pages drive their own reveal and call onReady.
            return
        }

        withAnimation(narrativeRevealAnimation(delay: 0.0)) {
            infoIconVisible = true
        }
        var lines = [info.title, info.subtitle]
        if let features = info.features {
            lines.append(contentsOf: features)
        }
        startNarrativeTypewriter(lines: lines) {
            infoAnimationComplete = true
        }
    }
    
    private func isJoinMuslimsInfoStep(_ info: InfoStep) -> Bool {
        info.icon == "person.3.sequence.fill"
    }
    
    private var isCompactOnboardingHeight: Bool {
        UIScreen.main.bounds.height <= 667
    }
    
    private func startReflectionAnimations(reflection: ReflectionStep) {
        startNarrativeTypewriter(lines: [reflection.title] + reflection.lines) {
            reflectionAnimationComplete = true
        }
    }
    
    private func startPrayerLockAnimations(step: PrayerLockStep) {
        prayerLockCardsVisible = false
        prayerLockDissolving = false
        prayerLockAutoAdvanceWorkItem?.cancel()
        prayerLockAutoAdvanceWorkItem = nil

        let lines = resolvedPrayerLockLines(step).map(\.text)
        startNarrativeTypewriter(lines: lines) {
            var extra: Double = 0
            if step.showDeedCards {
                extra = 0.7
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.easeInOut(duration: 0.55)) {
                        prayerLockCardsVisible = true
                    }
                    HapticManager.shared.animationReveal(beat: 2)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + extra) {
                prayerLockAnimationComplete = true
            }

            if step.autoAdvanceAfterSeconds != nil {
                let stepToAdvanceFrom = self.step
                let work = DispatchWorkItem {
                    guard stepToAdvanceFrom == self.step else { return }
                    let next = stepToAdvanceFrom + 1
                    withAnimation(.easeInOut(duration: 0.45)) {
                        self.prayerLockDissolving = true
                    }
                    HapticManager.shared.soft()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                        guard stepToAdvanceFrom == self.step else { return }
                        if next < self.steps.count {
                            withAnimation(.spring(response: 0.82, dampingFraction: 0.86)) {
                                self.step = next
                            }
                            HapticManager.shared.medium()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                self.trackStepViewed(step: next)
                            }
                        } else {
                            self.finishQuestionnaire()
                        }
                    }
                }
                prayerLockAutoAdvanceWorkItem = work
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + extra + OnboardingFunnelConfig.lifeChangeAutoAdvanceSeconds,
                    execute: work
                )
            }
        }
    }
    
    private func startNameInputAnimations() {
        let delayPerElement: Double = 0.9
        withAnimation(narrativeRevealAnimation(delay: 0.0)) {
            nameInputSubtitleVisible = true
        }
        scheduleTextRevealHaptic(at: 0.0, index: 0)
        withAnimation(narrativeRevealAnimation(delay: delayPerElement)) {
            nameInputTitleVisible = true
        }
        scheduleTextRevealHaptic(at: delayPerElement, index: 1)
        withAnimation(narrativeRevealAnimation(delay: delayPerElement * 2)) {
            nameInputFieldVisible = true
        }
        scheduleTextRevealHaptic(at: delayPerElement * 2, index: 2)
    }
    
    private func startConsiderThisAnimations() {
        let displayName: String = {
            let raw = userDataManager.userName?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let n = raw, !n.isEmpty { return n }
            return NSLocalizedString("questionnaire.consider_this.fallback_name", comment: "there")
        }()
        let text: String = {
            if case .considerThis(let considerStep) = safeCurrentStep {
                return String(format: NSLocalizedString(considerStep.formatKey, comment: ""), displayName)
            }
            return displayName
        }()
        startNarrativeTypewriter(lines: [text]) {
            considerThisAnimationComplete = true
            let stepToAdvanceFrom = self.step
            let work = DispatchWorkItem {
                guard stepToAdvanceFrom == self.step, stepToAdvanceFrom + 1 < self.steps.count else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.step = stepToAdvanceFrom + 1
                }
            }
            considerThisAutoAdvanceWorkItem = work
            DispatchQueue.main.asyncAfter(
                deadline: .now() + OnboardingFunnelConfig.autoAdvanceHoldSeconds,
                execute: work
            )
        }
    }
    
    private func startImpactStatsAnimations(impactStep: ImpactStatsStep) {
        impactHeroVisible = false
        impactHeroScale = 0.7
        impactHeroYears = 0
        impactIconsRevealed = 0
        impactCountedHours = 0
        impactCountedDays = 0
        let sequenceID = UUID()
        impactStatsSequenceID = sequenceID

        let hoursPerYear = screenTimeHoursPerDay * 365
        let daysPerYear = Int(round(Double(hoursPerYear) / 24.0))
        impactCountedHours = hoursPerYear
        impactCountedDays = daysPerYear
        let iconCount = selectedImpactAppIcons.count
        let iconStartDelay: Double = 1.28
        let iconStagger: Double = 0.08
        let iconsDone = iconStartDelay + Double(max(iconCount, 0)) * iconStagger + 0.12

        for i in 0..<iconCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + iconStartDelay + Double(i) * iconStagger) {
                guard impactStatsSequenceID == sequenceID else { return }
                withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) {
                    impactIconsRevealed = i + 1
                }
                HapticManager.shared.light()
            }
        }

        let displayName: String = {
            let raw = userDataManager.userName?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let n = raw, !n.isEmpty { return n }
            return NSLocalizedString("questionnaire.consider_this.fallback_name", comment: "there")
        }()
        let yearsLifetime = Int(round(Double(hoursPerYear) * 60.0 / 8760.0))
        let typedLines: [String] = (0..<impactStep.lines.count).map { index in
            switch index {
            case 0:
                return String(format: NSLocalizedString("questionnaire.impact_stats.line1_format", comment: ""), displayName, hoursPerYear)
            case 2:
                return String(format: NSLocalizedString("questionnaire.impact_stats.line3_format", comment: ""), daysPerYear)
            case 3:
                return String(format: NSLocalizedString("questionnaire.impact_stats.line4_format", comment: ""), yearsLifetime)
            default:
                return impactStep.lines[index].text
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + iconsDone) {
            guard impactStatsSequenceID == sequenceID else { return }
            startNarrativeTypewriter(lines: typedLines) {
                guard impactStatsSequenceID == sequenceID else { return }
                impactStatsAnimationComplete = true
            }
        }
    }
    
    private func startPlanIntroAnimations(step: PlanIntroStep) {
        startNarrativeTypewriter(lines: step.lines.map(\.text)) {
            planIntroAnimationComplete = true
        }
    }

    private func startNarrativeTypewriter(lines: [String], onComplete: @escaping () -> Void) {
        typewriterRunner.start(lines: lines, onCount: { index, count in
            narrativeTypedCount[index] = count
        }, onComplete: onComplete)
    }
    
    private func scheduleTextRevealHaptic(at delay: Double, index: Int) {
        HapticManager.shared.scheduleAnimationReveal(after: delay, beat: index)
    }
    
    private func triggerStepTransitionHaptic() {
        // Varied haptic feedback based on step type and index for curiosity
        guard let stepType = safeCurrentStep else { return }
        let stepIndex = step
        
        switch stepType {
        case .info, .reflection, .prayerLock, .nameInput, .considerThis, .impactStats, .planIntro, .allowNotifications, .patienceQuote, .guideMuslims:
            // Vary based on step index
            switch stepIndex % 4 {
            case 0: HapticManager.shared.soft()
            case 1: HapticManager.shared.light()
            case 2: HapticManager.shared.selection()
            case 3: HapticManager.shared.medium()
            default: HapticManager.shared.soft()
            }
        case .question, .referralSource, .appIconPicker:
            // Different pattern for questions
            switch stepIndex % 5 {
            case 0: HapticManager.shared.light()
            case 1: HapticManager.shared.soft()
            case 2: HapticManager.shared.medium()
            case 3: HapticManager.shared.selection()
            case 4: HapticManager.shared.light()
            default: HapticManager.shared.light()
            }
        case .visual:
            // Special haptic for visual steps
            HapticManager.shared.medium()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                HapticManager.shared.soft()
            }
        case .demoNotification:
            HapticManager.shared.soft()
        case .interactiveDemo:
            // Exciting haptic for demo
            HapticManager.shared.heavy()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                HapticManager.shared.medium()
            }
        case .streakPreview:
            HapticManager.shared.medium()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                HapticManager.shared.soft()
            }
        case .commitment:
            // Stronger haptic for commitment steps
            HapticManager.shared.medium()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                HapticManager.shared.selection()
            }
        case .appSelection:
            HapticManager.shared.selection()
        case .difficultySelection:
            HapticManager.shared.selection()
        case .sliderQuestion, .ageSelection:
            HapticManager.shared.selection()
        }
    }
    
    private func triggerStepChangeHaptic(from oldStep: Int, to newStep: Int) {
        // Varied haptic pattern based on direction and step type
        if newStep > oldStep {
            // Moving forward - lighter, encouraging haptics
            let hapticPattern = [HapticManager.shared.light, HapticManager.shared.soft, HapticManager.shared.selection, HapticManager.shared.medium]
            let index = newStep % hapticPattern.count
            hapticPattern[index]()
        } else {
            // Moving backward - softer haptic
            HapticManager.shared.soft()
        }
    }
    
    private func triggerButtonHaptic() {
        // Varied haptic feedback for button presses to create anticipation
        let buttonHapticPattern = [
            { HapticManager.shared.medium() },
            { HapticManager.shared.light() },
            { HapticManager.shared.selection() },
            { 
                HapticManager.shared.medium()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    HapticManager.shared.soft()
                }
            },
            { HapticManager.shared.soft() }
        ]
        
        let index = step % buttonHapticPattern.count
        buttonHapticPattern[index]()
    }
    
    private func triggerOptionSelectionHaptic(optionIndex: Int) {
        // Varied haptic feedback based on option position
        switch optionIndex % 4 {
        case 0:
            HapticManager.shared.light()
        case 1:
            HapticManager.shared.selection()
        case 2:
            HapticManager.shared.soft()
        case 3:
            HapticManager.shared.medium()
        default:
            HapticManager.shared.selection()
        }
    }
    
    // 100% SAFE button action handler
    private func handleButtonAction() {
        dismissOnboardingKeyboard()
        // Prevent action during transition
        guard !isTransitioning else { return }
        
        // Always ensure main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.handleButtonAction()
            }
            return
        }
        
        // Safety check for step bounds
        guard step >= 0 && step < steps.count else {
            debugPrint("❌ Invalid step: \(step), steps.count: \(steps.count)")
            return
        }
        
        // Last short-funnel step: review popup stays on this page (never on life-change).
        if case .guideMuslims = steps[step] {
            if didHandleGuideMuslimsReview {
                finishQuestionnaire()
                return
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                showGuideMuslimsReviewPopup = true
            }
            return
        }

        if case .info(let info) = steps[step], info.visualDemo == .fajrSetup, fajrAlarm.selectedObject != nil {
            fajrAlarm.setEnabled(true)
        }

        if step < steps.count - 1 {
            if case .streakPreview = steps[step] {
                PostHogManager.shared.trackOnboardingStreakContinueClicked()
            }
            if case .question(let question) = steps[step], isOtherAnswerSelected(question) {
                let typed = otherAnswerText.trimmingCharacters(in: .whitespacesAndNewlines)
                AnalyticsManager.shared.trackOnboardingAnswer(
                    step: step,
                    stepName: question.title,
                    stepIdentifier: getStepIdentifier(for: step),
                    answerIndex: question.otherOptionIndex ?? 0,
                    answerText: typed.isEmpty ? "Other" : "Other: \(typed)"
                )
            }
            if case .nameInput = steps[step] {
                let name = enteredName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    userDataManager.setUserName(name)
                    AnalyticsManager.shared.trackOnboardingAnswer(
                        step: step,
                        stepName: getStepName(for: step),
                        stepIdentifier: getStepIdentifier(for: step),
                        answerIndex: 1,
                        answerText: "Name provided"
                    )
                }
            }
            if case .appSelection = steps[step] {
                AnalyticsManager.shared.trackOnboardingAppsSelected(
                    count: shieldManager.pickerSelectionCount,
                    skipped: !shieldManager.hasShieldTargets
                )
            }
            if case .appIconPicker = steps[step] {
                let selected = OnboardingAppTimeOptions.all.filter { selectedTimeApps.contains($0.id) }
                let labels = selected
                    .map { AnalyticsAnswerLabel.english(key: $0.titleKey, fallback: $0.id) }
                    .joined(separator: ", ")
                AnalyticsManager.shared.trackOnboardingAnswer(
                    step: step,
                    stepName: NSLocalizedString("questionnaire.apps.title", comment: ""),
                    stepIdentifier: getStepIdentifier(for: step),
                    answerIndex: selected.count,
                    answerText: labels.isEmpty ? "None selected" : labels
                )
            }
            if getStepIdentifier(for: step) == "daily_reminder_count",
               case .sliderQuestion(let slider) = steps[step] {
                let count = sliderValues[step] ?? slider.defaultValue
                NotificationManager.shared.setDailySpiritualCount(count)
            }
            if case .allowNotifications = steps[step] {
                isTransitioning = true
                let fromStep = step
                NotificationManager.shared.requestPermission { _ in
                    DispatchQueue.main.async {
                        self.isTransitioning = false
                        let nextStep = fromStep + 1
                        guard nextStep < self.steps.count else {
                            self.finishQuestionnaire()
                            return
                        }
                        withAnimation(.easeInOut(duration: 0.4)) {
                            self.step = nextStep
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.trackStepViewed(step: nextStep)
                        }
                    }
                }
                return
            }
            advancePastCurrentStep(requestReview: false)
            return
        } else {
            debugPrint("🔵 Last step reached, finishing questionnaire")
            finishQuestionnaire()
        }
    }

    /// Advances past the current step. When `requestReview` is true (primary CTA on guide_muslims), shows the in-app review popup first.
    private func advancePastCurrentStep(requestReview: Bool) {
        guard step >= 0 && step < steps.count else { return }

        if requestReview, case .guideMuslims = steps[step] {
            OnboardingGuideMuslimsView.requestGuideReview()
        }

        if step >= steps.count - 1 {
            finishQuestionnaire()
            return
        }

        var nextStep = step + 1
        if case .sliderQuestion(let sliderQuestion) = steps[step],
           let threshold = sliderQuestion.skipNextStepWhenValueAbove {
            let value = sliderValues[step] ?? sliderQuestion.defaultValue
            if value > threshold {
                nextStep = step + 2
            }
        }
        if case .question(let question) = steps[step],
           let skipIndex = question.skipNextStepWhenAnswerIndex,
           answers[step] == skipIndex {
            nextStep = step + 2
        }
        guard nextStep < steps.count else {
            finishQuestionnaire()
            return
        }

        withAnimation(.easeInOut(duration: 0.4)) {
            step = nextStep
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.trackStepViewed(step: nextStep)
        }
    }
    
    // 100% SAFE questionnaire finish with full error handling
    private func finishQuestionnaire() {
        // Always ensure main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.finishQuestionnaire()
            }
            return
        }
        guard !isHandingOff else { return }
        
        debugPrint("🔄 Starting finishQuestionnaire...")
        isTransitioning = true
        
        // Enhanced completion haptic sequence - SAFE
        HapticManager.shared.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            HapticManager.shared.medium()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            HapticManager.shared.success()
        }
        
        // Save data safely
        localStorage.saveOnboardingAnswers(answers)
        
        if case .difficultySelection = safeCurrentStep {
            let level = min(2, max(0, answers[step] ?? 1))
            userDataManager.setOnboardingDifficultyLevel(level)
            // Selection + analytics fire when the user taps an option; persist again here at completion.
        }
        
        // Screen-time hours live on the non-mood slider. The wheel shows a default
        // even when the user never moves it, so persist that default too.
        if let idx = screenTimeStepIndex {
            let hours = sliderValues[idx] ?? answers[idx] ?? screenTimeHoursPerDay
            localStorage.onboardingScrollHours = max(0, min(12, hours))
        }
        if steps.contains(where: { if case .ageSelection = $0 { return true }; return false }) {
            userDataManager.setUserAge("\(selectedAge ?? 18)")
        }
        
        if shieldManager.hasShieldTargets {
            shieldManager.applyShield()
        }
        
        // Track completion - SAFE
        AnalyticsManager.shared.trackOnboardingCompleted(
            totalSteps: steps.count,
            appsSelected: shieldManager.pickerSelectionCount
        )
        
        debugPrint("🔄 Dissolving last onboarding page into plan loading...")
        withAnimation(AppMotion.funnelDissolve) {
            isHandingOff = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) {
            debugPrint("🔄 Executing onFinished now...")
            onFinished()
        }
    }
    
    // MARK: - Analytics Tracking
    
    private func trackStepViewed(step: Int) {
        // Safety check
        guard step >= 0 && step < steps.count else {
            debugPrint("❌ ERROR: Cannot track step \(step), steps.count = \(steps.count)")
            return
        }
        
        let stepName = getStepName(for: step)
        let stepType = getStepType(for: step)
        let stepIdentifier = getStepIdentifier(for: step) // Non-localized identifier
        debugPrint("📊 Tracking step \(step): \(stepName) (type: \(stepType), identifier: \(stepIdentifier))")
        AnalyticsManager.shared.trackOnboardingStep(step: step, stepName: stepName, stepType: stepType, totalSteps: steps.count, stepIdentifier: stepIdentifier)
    }
    
    /// The stable catalog id for a step (e.g. `demo_notification`). Deliberately not derived
    /// from the index or the localized title: reordering the funnel or editing copy must not
    /// silently rename an analytics identifier.
    private func getStepIdentifier(for stepIndex: Int) -> String {
        let ids = stepIDs
        guard stepIndex >= 0 && stepIndex < ids.count else {
            return "unknown"
        }
        return ids[stepIndex]
    }
    
    private func getStepName(for stepIndex: Int) -> String {
        guard stepIndex >= 0 && stepIndex < steps.count else {
            debugPrint("❌ ERROR: getStepName called with invalid stepIndex \(stepIndex), steps.count = \(steps.count)")
            return "unknown"
        }
        switch steps[stepIndex] {
        case .info(let info):
            return info.title
        case .reflection(let reflection):
            return reflection.title
        case .prayerLock:
            return NSLocalizedString("questionnaire.prayer_lock.title", comment: "Prayer lock")
        case .nameInput(let nameStep):
            return nameStep.title
        case .considerThis:
            return NSLocalizedString("questionnaire.consider_this.title", comment: "Consider this")
        case .impactStats:
            return NSLocalizedString("questionnaire.impact_stats.title", comment: "Impact stats")
        case .planIntro:
            return NSLocalizedString("questionnaire.plan_intro.title", comment: "Plan intro")
        case .referralSource:
            return NSLocalizedString("questionnaire.hear_about.title", comment: "")
        case .question(let question):
            return question.title
        case .sliderQuestion(let sliderQuestion):
            return sliderQuestion.title
        case .ageSelection:
            return NSLocalizedString("questionnaire.age.title", comment: "How old are you?")
        case .commitment(let commitment):
            return commitment.title
        case .appSelection:
            return "App Selection"
        case .difficultySelection:
            return NSLocalizedString("questionnaire.difficulty.title", comment: "")
        case .visual(let visual):
            return visual.title
        case .demoNotification:
            return NSLocalizedString("demo.notification.headline", comment: "Demo notification")
        case .interactiveDemo:
            return "Interactive Demo"
        case .streakPreview:
            return NSLocalizedString("onboarding.streak.step_name", comment: "Your streak")
        case .allowNotifications:
            return NSLocalizedString("onboarding.allow_notifications.step_name", comment: "Reminders")
        case .patienceQuote:
            return NSLocalizedString("onboarding.patience_quote.step_name", comment: "Patience")
        case .guideMuslims:
            return NSLocalizedString("onboarding.guide_muslims.step_name", comment: "Guide Muslims")
        case .appIconPicker:
            return NSLocalizedString("questionnaire.apps.title", comment: "Apps question")
        }
    }
    
    private func getStepType(for stepIndex: Int) -> String {
        guard stepIndex >= 0 && stepIndex < steps.count else {
            debugPrint("❌ ERROR: getStepType called with invalid stepIndex \(stepIndex), steps.count = \(steps.count)")
            return "unknown"
        }
        switch steps[stepIndex] {
        case .info: return "info"
        case .reflection: return "reflection"
        case .prayerLock: return "prayer_lock"
        case .nameInput: return "name_input"
        case .considerThis: return "consider_this"
        case .impactStats: return "impact_stats"
        case .planIntro: return "plan_intro"
        case .referralSource: return "referral_source"
        case .question: return "question"
        case .sliderQuestion: return "slider_question"
        case .ageSelection: return "age_selection"
        case .commitment: return "commitment"
        case .appSelection: return "app_selection"
        case .difficultySelection: return "difficulty_selection"
        case .visual: return "visual"
        case .demoNotification: return "demo_notification"
        case .interactiveDemo: return "interactive_demo"
        case .streakPreview: return "streak_preview"
        case .allowNotifications: return "allow_notifications"
        case .patienceQuote: return "patience_quote"
        case .guideMuslims: return "guide_muslims"
        case .appIconPicker: return "app_icon_picker"
        }
    }
    
    #if canImport(FamilyControls)
    /// Requests Screen Time authorization then opens the picker (no extra onboarding screen).
    private func requestFamilyControlsAndPresentPicker() {
        if #available(iOS 16.0, *) {
            let status = AuthorizationCenter.shared.authorizationStatus
            if status == .approved {
                isAppPickerPresented = true
                return
            }
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    await MainActor.run {
                        if AuthorizationCenter.shared.authorizationStatus == .approved {
                            isAppPickerPresented = true
                        } else {
                            showFamilyControlsDeniedAlert = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        showFamilyControlsDeniedAlert = true
                    }
                }
            }
        }
    }
    #endif
}

// MARK: - ScrollDeeds Slider Component

struct ScrollDeedsSlider: View {
    @Binding var value: Double
    let minValue: Double
    let maxValue: Double
    let unit: String
    var moodLeftLabel: String? = nil
    var moodRightLabel: String? = nil

    @State private var lastHapticValue: Int = -1
    @State private var displayedHours: Int = 0
    @State private var hasPlayedAppearCount = false

    private var isMood: Bool { moodLeftLabel != nil && moodRightLabel != nil }

    private var moodCaption: String {
        switch Int(value) {
        case 1: return moodLeftLabel ?? ""
        case 2: return NSLocalizedString("questionnaire.mood_after.level2", comment: "Low")
        case 3: return NSLocalizedString("questionnaire.mood_after.level3", comment: "Okay")
        case 4: return NSLocalizedString("questionnaire.mood_after.level4", comment: "Good")
        default: return moodRightLabel ?? ""
        }
    }

    var body: some View {
        VStack(spacing: isMood ? 20 : 32) {
            // Hours: large number. Mood: caption only (emoji lives in the hero above).
            if isMood {
                Text(moodCaption)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .animation(.easeInOut(duration: 0.2), value: Int(value))
                    .frame(height: 28)
            } else {
                VStack(spacing: 8) {
                    Text("\(displayedHours)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.primaryLight, AppTheme.primary, AppTheme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: displayedHours)

                    Text(unit)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(height: 120)
            }

            // Slider controls
            VStack(spacing: 8) {
                HStack(alignment: .top, spacing: 20) {
                    // Minus + left end label under it
                    VStack(spacing: 8) {
                        Button(action: {
                            if value > minValue {
                                HapticManager.shared.light()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    value = max(minValue, value - 1)
                                }
                                triggerHapticIfChanged()
                            } else {
                                HapticManager.shared.rigid()
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(value > minValue ? AppTheme.textPrimary : AppTheme.textMuted)
                                .frame(width: 56, height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(value > minValue ? AppTheme.card : AppTheme.card.opacity(0.5))
                                )
                        }
                        .disabled(value <= minValue)

                        if isMood, let left = moodLeftLabel {
                            Text(left)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: 64)
                        }
                    }

                    // Slider track
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppTheme.muted)
                                .frame(height: 8)

                            Capsule()
                                .fill(AppTheme.gradientPrimary)
                                .frame(width: geometry.size.width * CGFloat((value - minValue) / (maxValue - minValue)), height: 8)

                            Circle()
                                .fill(AppTheme.gradientPrimary)
                                .frame(width: 32, height: 32)
                                .shadow(color: AppTheme.primary.opacity(0.4), radius: 12, y: 4)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                )
                                .offset(x: geometry.size.width * CGFloat((value - minValue) / (maxValue - minValue)) - 16)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { dragValue in
                                            let percentage = max(0, min(1, dragValue.location.x / geometry.size.width))
                                            let newValue = minValue + (maxValue - minValue) * Double(percentage)
                                            let roundedValue = round(newValue)

                                            if roundedValue != value {
                                                value = roundedValue
                                                triggerHapticIfChanged()
                                            }
                                        }
                                )
                        }
                    }
                    .frame(height: 56)

                    // Plus + right end label under it
                    VStack(spacing: 8) {
                        Button(action: {
                            if value < maxValue {
                                HapticManager.shared.light()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    value = min(maxValue, value + 1)
                                }
                                triggerHapticIfChanged()
                            } else {
                                HapticManager.shared.rigid()
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(value < maxValue ? AppTheme.textPrimary : AppTheme.textMuted)
                                .frame(width: 56, height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(value < maxValue ? AppTheme.card : AppTheme.card.opacity(0.5))
                                )
                        }
                        .disabled(value >= maxValue)

                        if isMood, let right = moodRightLabel {
                            Text(right)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: 64)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 20)
        .onAppear {
            lastHapticValue = Int(value)
            displayedHours = Int(value)
            playHoursAppearCountIfNeeded()
        }
        .onChange(of: value) { newValue in
            displayedHours = Int(newValue)
        }
    }

    private func playHoursAppearCountIfNeeded() {
        guard !isMood, !hasPlayedAppearCount else { return }
        hasPlayedAppearCount = true
        let target = Int(value)
        guard target > 0 else { return }
        displayedHours = 0
        let steps = min(target, 24)
        let interval = 0.045
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                guard Int(value) == target else { return }
                let tick = Int(round(Double(target) * Double(i) / Double(steps)))
                withAnimation(.easeOut(duration: 0.08)) {
                    displayedHours = tick
                }
                if i == steps {
                    HapticManager.shared.soft()
                } else if i % 3 == 0 {
                    HapticManager.shared.selection()
                }
            }
        }
    }

    private func triggerHapticIfChanged() {
        let currentIntValue = Int(value)
        if currentIntValue != lastHapticValue {
            let hapticPattern = [
                HapticManager.shared.selection,
                HapticManager.shared.light,
                HapticManager.shared.soft,
                HapticManager.shared.medium
            ]
            let index = currentIntValue % hapticPattern.count
            hapticPattern[index]()
            lastHapticValue = currentIntValue
        }
    }
}

// MARK: - ScrollDeeds Age Picker Component

struct ScrollDeedsAgePicker: View {
    @Binding var selectedAge: Int
    
    @State private var lastHapticAge: Int = -1
    @State private var scrollOffset: CGFloat = 0
    @State private var isScrolling: Bool = false
    @State private var isUpdatingFromScroll: Bool = false
    @State private var internalSelectedAge: Int
    @State private var ageItemPositions: [AgeItemPreference] = []
    @State private var scrollTimer: Timer?
    
    private let minAge = 13
    private let maxAge = 100
    private let ages: [Int]
    private let itemHeight: CGFloat = 60
    
    init(selectedAge: Binding<Int>) {
        self._selectedAge = selectedAge
        self._internalSelectedAge = State(initialValue: selectedAge.wrappedValue)
        self.ages = Array(13...100)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Selection highlight box
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [AppTheme.primary.opacity(0.4), AppTheme.accent.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .frame(height: itemHeight)
                    .shadow(color: AppTheme.primary.opacity(0.2), radius: 12, y: 4)
                
                // Scrollable age list
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(ages, id: \.self) { age in
                                Text("\(age)")
                                    .font(.system(size: age == internalSelectedAge ? 32 : 20, weight: age == internalSelectedAge ? .bold : .regular))
                                    .foregroundColor(age == internalSelectedAge ? AppTheme.textPrimary : AppTheme.textSecondary)
                                    .opacity(age == internalSelectedAge ? 1.0 : 0.6)
                                    .frame(height: itemHeight)
                                    .frame(maxWidth: .infinity)
                                    .id(age)
                                    .contentShape(Rectangle())
                                    .background(
                                        GeometryReader { itemGeometry in
                                            Color.clear
                                                .preference(
                                                    key: AgeItemPreferenceKey.self,
                                                    value: [AgeItemPreference(age: age, centerY: itemGeometry.frame(in: .named("scroll")).midY)]
                                                )
                                        }
                                    )
                                    .onTapGesture {
                                        isUpdatingFromScroll = true
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            internalSelectedAge = age
                                            selectedAge = age
                                            proxy.scrollTo(age, anchor: .center)
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            isUpdatingFromScroll = false
                                        }
                                        triggerHapticIfChanged()
                                    }
                            }
                        }
                        .padding(.vertical, geometry.size.height / 2 - itemHeight / 2)
                        .background(
                            GeometryReader { scrollGeometry in
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: scrollGeometry.frame(in: .named("scroll")).minY
                                    )
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        scrollOffset = offset
                    }
                    .onPreferenceChange(AgeItemPreferenceKey.self) { items in
                        ageItemPositions = items
                        updateSelectedAgeFromPositions(geometry: geometry)
                    }
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { _ in
                                isScrolling = true
                                isUpdatingFromScroll = false
                                
                                // Start timer to continuously check position during scroll
                                scrollTimer?.invalidate()
                                scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                                    updateSelectedAgeFromPositions(geometry: geometry)
                                }
                            }
                            .onEnded { _ in
                                isScrolling = false
                                scrollTimer?.invalidate()
                                scrollTimer = nil
                                
                                // Final update
                                updateSelectedAgeFromPositions(geometry: geometry)
                                
                                // Update binding with final selected age
                                selectedAge = internalSelectedAge
                                
                                // Snap to nearest age after scrolling ends
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isUpdatingFromScroll = true
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        proxy.scrollTo(internalSelectedAge, anchor: .center)
                                    }
                                    // Reset flag after animation completes
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                        isUpdatingFromScroll = false
                                    }
                                }
                            }
                    )
                    .onChange(of: selectedAge) { newAge in
                        // Only update internal state if change came from outside (e.g., initial value)
                        if !isScrolling && !isUpdatingFromScroll && internalSelectedAge != newAge {
                            internalSelectedAge = newAge
                            isUpdatingFromScroll = true
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                proxy.scrollTo(newAge, anchor: .center)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                isUpdatingFromScroll = false
                            }
                        }
                        triggerHapticIfChanged()
                    }
                    .onAppear {
                        internalSelectedAge = selectedAge
                        // Scroll to selected age on appear
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            proxy.scrollTo(internalSelectedAge, anchor: .center)
                            lastHapticAge = internalSelectedAge
                        }
                    }
                }
            }
        }
        .frame(height: 300)
        .clipped()
    }
    
    private func calculateOffsetForAge(_ age: Int, geometry: GeometryProxy) -> CGFloat {
        guard let ageIndex = ages.firstIndex(of: age) else { return 0 }
        let centerY = geometry.size.height / 2
        let topPadding = centerY - itemHeight / 2
        return -(CGFloat(ageIndex) * itemHeight - topPadding)
    }
    
    private func updateSelectedAgeFromPositions(geometry: GeometryProxy) {
        guard !ageItemPositions.isEmpty && !isUpdatingFromScroll else { return }
        
        // Find the item closest to the center
        let centerY = geometry.size.height / 2
        let closestItem = ageItemPositions.min(by: { abs($0.centerY - centerY) < abs($1.centerY - centerY) })
        
        if let closest = closestItem, closest.age != internalSelectedAge {
            internalSelectedAge = closest.age
            triggerHapticIfChanged()
        }
    }
    
    private func triggerHapticIfChanged() {
        if internalSelectedAge != lastHapticAge {
            // Varied haptic feedback
            let hapticPattern = [
                HapticManager.shared.selection,
                HapticManager.shared.light,
                HapticManager.shared.soft,
                HapticManager.shared.medium
            ]
            let index = internalSelectedAge % hapticPattern.count
            hapticPattern[index]()
            lastHapticAge = internalSelectedAge
        }
    }
}

// MARK: - Join Muslims — review carousel card (onboarding social proof)

private struct JoinMuslimsReviewCard: View {
    var compact: Bool = false
    let name: String
    let quote: String
    var flag: String = ""

    private var initial: String {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard let c = t.first else { return "?" }
        return String(c).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 10) {
            HStack(alignment: .center, spacing: compact ? 10 : 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.primary.opacity(0.85),
                                    AppTheme.primary.opacity(0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: compact ? 38 : 44, height: compact ? 38 : 44)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        .frame(width: compact ? 38 : 44, height: compact ? 38 : 44)
                    Text(initial)
                        .font(.system(size: compact ? 16 : 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: compact ? 15 : 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    if !flag.isEmpty {
                        Text(flag)
                            .font(.system(size: compact ? 14 : 15))
                            .fixedSize()
                    }
                }
                .layoutPriority(1)
                Spacer(minLength: 6)
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: compact ? 11 : 12))
                            .foregroundColor(AppTheme.starYellow)
                    }
                }
                .fixedSize()
            }
            Text(quote)
                .font(.system(size: compact ? 13 : 14, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(compact ? 3 : 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(compact ? 12 : 16)
        .padding(.bottom, compact ? 4 : 6)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: Color.black.opacity(0.06), radius: 14, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            AppTheme.primary.opacity(0.55),
                            AppTheme.accent.opacity(0.45),
                            AppTheme.primary.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Helper for scroll offset tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Helper for tracking age item positions
struct AgeItemPreference: Equatable {
    let age: Int
    let centerY: CGFloat
}

struct AgeItemPreferenceKey: PreferenceKey {
    static var defaultValue: [AgeItemPreference] = []
    static func reduce(value: inout [AgeItemPreference], nextValue: () -> [AgeItemPreference]) {
        value.append(contentsOf: nextValue())
    }
}


#Preview {
    QuestionnaireView(onFinished: {}, shieldManager: ShieldManager.shared, localStorage: LocalStorageManager.shared, userDataManager: UserDataManager.shared)
}
