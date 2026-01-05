import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif

// MARK: - Onboarding Step Types

enum OnboardingStepType {
    case info(InfoStep)
    case question(QuestionStep)
    case appSelection
    case difficultySelection
    case commitment(CommitmentStep)
    case freeTrialInfo
    case visual(VisualStep) // NEW: Visual/Illustration screens
}

struct InfoStep {
    let icon: String
    let title: String
    let subtitle: String
    let features: [String]?
    let animationType: AnimationType
    
    enum AnimationType {
        case pulse
        case float
        case glow
        case shake
    }
}

struct QuestionStep {
    let icon: String
    let title: String
    let subtitle: String
    let options: [String]
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
        case transformationBefore // Before state
        case transformationAfter  // After state
        case dhikrDemo         // Shows dhikr recitation demo
        case lockScreen        // Shows the lock screen mockup
        case unlockFlow        // Shows the unlock flow
        case dailyRoutine      // Shows daily routine comparison
    }
}

// MARK: - Main View

struct QuestionnaireView: View {
    let onFinished: () -> Void
    @ObservedObject var shieldManager: ShieldManager
    @ObservedObject var localStorage: LocalStorageManager
    @ObservedObject var userDataManager: UserDataManager
    
    @State private var step: Int = 0
    @State private var answers: [Int: Int] = [:]
    @State private var isAppPickerPresented: Bool = false
    @State private var showPermissionView: Bool = false
    @State private var selectedDifficultyLevel: DifficultyLevel? = nil
    @State private var showDifficultyInfo: DifficultyLevel? = nil
    @State private var commitmentAccepted: [Int: Bool] = [:]
    
    // Animation states (simplified for performance)
    @State private var animateContent = false
    @State private var animateOptions = false
    @State private var pulseAnimation = false
    
    #if canImport(FamilyControls)
    @State private var appSelection = FamilyActivitySelection()
    #endif
    
    // MARK: - Onboarding Steps (40+ screens with visuals, tutorials & questions)
    
    private let steps: [OnboardingStepType] = [
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 1: WELCOME & HOOK
        // ═══════════════════════════════════════════════════════════════
        
        .info(InfoStep(
            icon: "moon.stars.fill",
            title: "Assalamu Alaikum",
            subtitle: "You're about to change your relationship with your phone forever.",
            features: nil,
            animationType: .glow
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 2: PROBLEM CONFIRMATION
        // ═══════════════════════════════════════════════════════════════
        
        .question(QuestionStep(
            icon: "clock.fill",
            title: "Be honest with yourself",
            subtitle: "How many hours do you spend on your phone daily?",
            options: ["Less than 2 hours", "2-4 hours", "4-6 hours", "More than 6 hours"]
        )),
        
        .question(QuestionStep(
            icon: "app.badge.fill",
            title: "Which apps consume most of your time?",
            subtitle: "Think about where the hours go...",
            options: ["Social media (Instagram, TikTok)", "YouTube & videos", "Games", "Multiple apps"]
        )),
        
        // 📊 VISUAL: Screen Time Stats
        .visual(VisualStep(
            type: .screenTimeStats,
            title: "The Average Person",
            subtitle: "Spends 4+ hours daily on their phone. That's 60+ days per year lost to scrolling."
        )),
        
        .question(QuestionStep(
            icon: "hand.raised.slash.fill",
            title: "Can you stop when you want to?",
            subtitle: "When you decide to put your phone down...",
            options: ["Yes, easily", "Sometimes I can", "It's very difficult", "Almost impossible"]
        )),
        
        .question(QuestionStep(
            icon: "bell.badge.fill",
            title: "How often do you check notifications?",
            subtitle: "Every buzz, every ping...",
            options: ["Only important ones", "A few times an hour", "Constantly", "I can't ignore them"]
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 3: PAIN AMPLIFICATION
        // ═══════════════════════════════════════════════════════════════
        
        .question(QuestionStep(
            icon: "heart.slash.fill",
            title: "How do you feel after scrolling?",
            subtitle: "That feeling when you realize an hour has passed...",
            options: ["Fine, no problem", "A bit guilty", "Very guilty", "Empty and regretful"]
        )),
        
        // 📊 VISUAL: You're Not Alone Stats
        .visual(VisualStep(
            type: .dailyRoutine,
            title: "You're Not Alone",
            subtitle: "87% of Muslims feel guilty about phone usage"
        )),
        
        .question(QuestionStep(
            icon: "moon.zzz.fill",
            title: "Has it affected your sleep?",
            subtitle: "Staying up late scrolling, tired for Fajr...",
            options: ["Never", "Sometimes", "Often", "Every night"]
        )),
        
        .question(QuestionStep(
            icon: "sun.horizon.fill",
            title: "Has it made Fajr harder?",
            subtitle: "Waking up tired, hitting snooze...",
            options: ["Never", "Occasionally", "Frequently", "It's a daily struggle"]
        )),
        
        .question(QuestionStep(
            icon: "moon.fill",
            title: "Has it affected your prayers?",
            subtitle: "Distracted during salah, missing prayers, rushing...",
            options: ["Never", "Occasionally", "Frequently", "Yes, significantly"]
        )),
        
        .question(QuestionStep(
            icon: "person.2.slash.fill",
            title: "Has it affected your relationships?",
            subtitle: "Less quality time with family, distracted conversations...",
            options: ["Not at all", "A little", "Noticeably", "It's causing problems"]
        )),
        
        .question(QuestionStep(
            icon: "brain.head.profile",
            title: "Has it affected your focus?",
            subtitle: "Difficulty concentrating, shorter attention span...",
            options: ["Not really", "Sometimes", "Often", "I can barely focus anymore"]
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 4: FIRST COMMITMENT
        // ═══════════════════════════════════════════════════════════════
        
        .commitment(CommitmentStep(
            icon: "checkmark.circle.fill",
            title: "Acknowledge the Problem",
            commitmentText: "I acknowledge that my phone usage is affecting my life"
        )),
        
        .info(InfoStep(
            icon: "hands.clap.fill",
            title: "That's Brave",
            subtitle: "Most people never admit there's a problem. You've already taken the hardest step.",
            features: nil,
            animationType: .glow
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 5: PERSONAL CONTEXT
        // ═══════════════════════════════════════════════════════════════
        
        .question(QuestionStep(
            icon: "eye.slash.fill",
            title: "What are you avoiding?",
            subtitle: "Be honest about what scrolling helps you escape from...",
            options: ["Work or responsibilities", "Difficult emotions", "Boredom", "All of the above"]
        )),
        
        .question(QuestionStep(
            icon: "arrow.counterclockwise",
            title: "Have you tried to change before?",
            subtitle: "Screen time limits, deleting apps, willpower alone...",
            options: ["Never tried", "Once or twice", "Many times", "I've tried everything"]
        )),
        
        .question(QuestionStep(
            icon: "xmark.circle.fill",
            title: "Why didn't it work?",
            subtitle: "What made previous attempts fail?",
            options: ["Lack of motivation", "Too easy to bypass", "Forgot about it", "Didn't have support"]
        )),
        
        .question(QuestionStep(
            icon: "exclamationmark.triangle.fill",
            title: "What's your biggest struggle?",
            subtitle: "When it comes to phone usage...",
            options: ["Starting to scroll", "Stopping once started", "The guilt after", "All of the above"]
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 6: BEFORE/AFTER TRANSFORMATION
        // ═══════════════════════════════════════════════════════════════
        
        // 📊 VISUAL: Before State
        .visual(VisualStep(
            type: .transformationBefore,
            title: "Your Life Right Now",
            subtitle: "Endless scrolling, guilt, missed prayers, wasted time..."
        )),
        
        // 📊 VISUAL: After State
        .visual(VisualStep(
            type: .transformationAfter,
            title: "Your Life With ScrollDeeds",
            subtitle: "Control, peace, daily dhikr, meaningful time..."
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 7: TUTORIAL - HOW IT WORKS (WITH VISUALS)
        // ═══════════════════════════════════════════════════════════════
        
        .info(InfoStep(
            icon: "wand.and.stars",
            title: "There's a Better Way",
            subtitle: "What if every time you wanted to scroll, you did something that brought you closer to Allah ﷻ?",
            features: nil,
            animationType: .glow
        )),
        
        .info(InfoStep(
            icon: "lock.shield.fill",
            title: "How ScrollDeeds Works",
            subtitle: "We don't just block your apps. We transform the habit into worship.",
            features: [
                "Choose which apps to lock",
                "Recite dhikr 3 times to unlock",
                "AI verifies your recitation",
                "Apps unlock for limited time"
            ],
            animationType: .float
        )),
        
        // 📱 VISUAL: Phone Mockup with Apps
        .visual(VisualStep(
            type: .phoneMockup,
            title: "Step 1: Choose Your Apps",
            subtitle: "Select the apps that distract you most"
        )),
        
        // 🔒 VISUAL: Lock Screen
        .visual(VisualStep(
            type: .lockScreen,
            title: "Step 2: Apps Get Locked",
            subtitle: "When you open them, you see a beautiful reminder"
        )),
        
        // 🎤 VISUAL: Dhikr Demo
        .visual(VisualStep(
            type: .dhikrDemo,
            title: "Step 3: Recite Dhikr",
            subtitle: "SubhanAllah, Alhamdulillah, Allahu Akbar — 3 times each"
        )),
        
        // 🔓 VISUAL: Unlock Flow
        .visual(VisualStep(
            type: .unlockFlow,
            title: "Step 4: Apps Unlock",
            subtitle: "After sincere recitation, enjoy your apps guilt-free"
        )),
        
        .info(InfoStep(
            icon: "sparkles",
            title: "The Magic",
            subtitle: "Every time you want to scroll, you'll say dhikr first. Imagine doing that 20, 30, 50 times a day...",
            features: nil,
            animationType: .glow
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 8: SECOND COMMITMENT
        // ═══════════════════════════════════════════════════════════════
        
        .commitment(CommitmentStep(
            icon: "hand.raised.fill",
            title: "Make a Promise",
            commitmentText: "I commit to replacing mindless scrolling with dhikr"
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 9: DREAM OUTCOME
        // ═══════════════════════════════════════════════════════════════
        
        .question(QuestionStep(
            icon: "clock.badge.checkmark.fill",
            title: "What if you had 2 extra hours daily?",
            subtitle: "Imagine reclaiming that time...",
            options: ["More Quran & worship", "Quality family time", "Career growth", "Self improvement"]
        )),
        
        .question(QuestionStep(
            icon: "star.fill",
            title: "What's your spiritual goal?",
            subtitle: "What do you want to achieve?",
            options: ["Pray all 5 on time", "Read Quran daily", "Better khushu in salah", "Strengthen my iman"]
        )),
        
        .question(QuestionStep(
            icon: "target",
            title: "In 30 days, what would success look like?",
            subtitle: "Visualize your transformation...",
            options: ["Complete control over my phone", "More time for what matters", "Stronger connection to Allah", "All of the above"]
        )),
        
        .info(InfoStep(
            icon: "chart.line.uptrend.xyaxis",
            title: "What You'll Achieve",
            subtitle: "Based on your answers, here's what ScrollDeeds can help you with:",
            features: [
                "Break phone addiction in 21 days",
                "Save 2+ hours daily",
                "100+ daily adhkar without trying",
                "Finally feel in control"
            ],
            animationType: .glow
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 10: SOCIAL PROOF
        // ═══════════════════════════════════════════════════════════════
        
        .info(InfoStep(
            icon: "person.3.sequence.fill",
            title: "Join 10,000+ Muslims",
            subtitle: "Who have already transformed their screen time into worship. The average user does 47 dhikr per day — just by using their phone normally.",
            features: nil,
            animationType: .pulse
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 11: FREE TRIAL EXPLANATION
        // ═══════════════════════════════════════════════════════════════
        
        .freeTrialInfo,
        
        .info(InfoStep(
            icon: "checkmark.shield.fill",
            title: "No Risk. No Commitment.",
            subtitle: "Try ScrollDeeds free for 1 month. If it doesn't change your life, cancel anytime. You won't be charged a single cent.",
            features: nil,
            animationType: .glow
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 12: FINAL QUESTIONS
        // ═══════════════════════════════════════════════════════════════
        
        .question(QuestionStep(
            icon: "flame.fill",
            title: "How committed are you?",
            subtitle: "Real change requires real commitment...",
            options: ["Just curious", "Somewhat ready", "Very committed", "100% ready to change"]
        )),
        
        .question(QuestionStep(
            icon: "calendar",
            title: "When do you want to start?",
            subtitle: "The best time to plant a tree was yesterday...",
            options: ["Maybe later", "This week", "Today", "Right now!"]
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 13: FINAL COMMITMENT
        // ═══════════════════════════════════════════════════════════════
        
        .commitment(CommitmentStep(
            icon: "checkmark.seal.fill",
            title: "Your Journey Starts Now",
            commitmentText: "I'm ready to transform my screen time into worship"
        )),
        
        .info(InfoStep(
            icon: "party.popper.fill",
            title: "You Did It!",
            subtitle: "You've taken the first step. Now let's set up your app and start your transformation.",
            features: nil,
            animationType: .glow
        )),
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 14: SETUP
        // ═══════════════════════════════════════════════════════════════
        
        .appSelection,
        
        .difficultySelection
    ]
    
    var body: some View {
        ZStack {
            // Animated background
            animatedBackground
            
            VStack(spacing: 0) {
                // Content area
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        currentStepContent
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 140)
                }
                
                // Bottom button area
                bottomButtonArea
            }
        }
        .onChange(of: step) { newStep in
            resetAnimations()
            startAnimations()
            // Track step view
            trackStepViewed(step: newStep)
        }
        .onAppear {
            startAnimations()
            // Track onboarding started
            AnalyticsManager.shared.trackOnboardingStarted()
            trackStepViewed(step: 0)
        }
        .onDisappear {
            // Track abandonment if not completed
            if step < steps.count - 1 {
                AnalyticsManager.shared.trackOnboardingAbandoned(
                    atStep: step,
                    stepName: getStepName(for: step)
                )
            }
        }
        #if canImport(FamilyControls)
        .onChange(of: isAppPickerPresented) { _ in
            if !isAppPickerPresented {
                shieldManager.updateSelection(apps: appSelection.applications)
            }
        }
        .fullScreenCover(isPresented: $showPermissionView) {
            FamilyControlsPermissionView(isPresented: $showPermissionView) {
                isAppPickerPresented = true
            }
        }
        #endif
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
        switch steps[step] {
        case .info(let info):
            infoStepView(info)
        case .question(let question):
            questionStepView(question)
        case .appSelection:
            appSelectionStepView
        case .difficultySelection:
            difficultySelectionView
        case .commitment(let commitment):
            commitmentStepView(commitment)
        case .freeTrialInfo:
            freeTrialInfoView
        case .visual(let visual):
            visualStepView(visual)
        }
    }
    
    // MARK: - Info Step View
    
    private func infoStepView(_ info: InfoStep) -> some View {
        VStack(spacing: 32) {
            // Icon with subtle glow (optimized)
            ZStack {
                // Single glow ring
                Circle()
                    .stroke(AppTheme.primary.opacity(0.12), lineWidth: 2)
                    .frame(width: 110, height: 110)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 90, height: 90)
                
                Image(systemName: info.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.9)
            
            // Title & Subtitle
            VStack(spacing: 16) {
                Text(info.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(info.subtitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 30)
            
            // Features list (if any)
            if let features = info.features {
                VStack(spacing: 16) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primary.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.primary)
                            }
                            
                            Text(feature)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.card)
                        )
                        .opacity(animateOptions ? 1 : 0)
                        .offset(x: animateOptions ? 0 : -50)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(index) * 0.1),
                            value: animateOptions
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Question Step View
    
    private func questionStepView(_ question: QuestionStep) -> some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Image(systemName: question.icon)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundColor(AppTheme.primary)
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.8)
            
            // Question text
            VStack(spacing: 12) {
                Text(question.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(question.subtitle)
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            
            // Options
            VStack(spacing: 12) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    optionButton(text: option, isSelected: answers[step] == index)
                        .onTapGesture {
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                answers[step] = index
                            }
                            // Track answer
                            AnalyticsManager.shared.trackOnboardingAnswer(
                                step: step,
                                stepName: question.title,
                                answerIndex: index,
                                answerText: option
                            )
                        }
                        .opacity(animateOptions ? 1 : 0)
                        .offset(y: animateOptions ? 0 : 30)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(index) * 0.08),
                            value: animateOptions
                        )
                }
            }
        }
    }
    
    // MARK: - Commitment Step View
    
    private func commitmentStepView(_ commitment: CommitmentStep) -> some View {
        VStack(spacing: 40) {
            // Icon (simplified for performance)
            ZStack {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.15), lineWidth: 2)
                    .frame(width: 110, height: 110)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: commitment.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.9)
            
            // Title
            Text(commitment.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(animateContent ? 1 : 0)
            
            // Commitment card
            VStack(spacing: 20) {
                Text("\"")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppTheme.primary.opacity(0.3))
                    .frame(height: 30)
                
                Text(commitment.commitmentText)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                
                // Commitment checkbox
                Button(action: {
                    HapticManager.shared.medium()
                    let newValue = !(commitmentAccepted[step] ?? false)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        commitmentAccepted[step] = newValue
                    }
                    // Track commitment
                    AnalyticsManager.shared.trackOnboardingCommitment(
                        step: step,
                        stepName: commitment.title,
                        committed: newValue
                    )
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    commitmentAccepted[step] == true ? AppTheme.primary : AppTheme.textMuted.opacity(0.3),
                                    lineWidth: 2
                                )
                                .frame(width: 28, height: 28)
                            
                            if commitmentAccepted[step] == true {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppTheme.primary)
                                    .frame(width: 22, height: 22)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("I commit to this")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(commitmentAccepted[step] == true ? AppTheme.primary : AppTheme.textSecondary)
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                commitmentAccepted[step] == true ? AppTheme.primary.opacity(0.5) : AppTheme.muted,
                                lineWidth: 2
                            )
                    )
            )
            .shadow(color: commitmentAccepted[step] == true ? AppTheme.primary.opacity(0.2) : Color.clear, radius: 20, y: 10)
            .opacity(animateOptions ? 1 : 0)
            .offset(y: animateOptions ? 0 : 40)
        }
    }
    
    // MARK: - Free Trial Info View
    
    private var freeTrialInfoView: some View {
        VStack(spacing: 32) {
            // Icon (simplified)
            ZStack {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.15), lineWidth: 2)
                    .frame(width: 110, height: 110)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.9)
            
            // Title
            VStack(spacing: 12) {
                Text("Try It Free")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("for 1 Month")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accentLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .opacity(animateContent ? 1 : 0)
            
            // How it works
            VStack(spacing: 16) {
                trialStep(number: "1", text: "Start your free trial today", icon: "play.fill")
                trialStep(number: "2", text: "Use ScrollDeeds for 30 days free", icon: "calendar")
                trialStep(number: "3", text: "Cancel anytime before trial ends", icon: "xmark.circle")
                trialStep(number: "4", text: "Only pay if you love it", icon: "heart.fill")
            }
            .opacity(animateOptions ? 1 : 0)
            .offset(y: animateOptions ? 0 : 30)
            
            // Guarantee badge
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.success)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("100% Risk Free")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Cancel anytime, no questions asked")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.success.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.success.opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(animateOptions ? 1 : 0)
        }
    }
    
    private func trialStep(number: String, text: String, icon: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
            }
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.card)
        )
    }
    
    // MARK: - Visual Step View (Illustrations & Mockups)
    
    private func visualStepView(_ visual: VisualStep) -> some View {
        VStack(spacing: 28) {
            // Title with better typography
            Text(visual.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            
            // Visual Illustration based on type
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
                case .transformationBefore:
                    transformationBeforeVisual
                case .transformationAfter:
                    transformationAfterVisual
                case .dailyRoutine:
                    dailyRoutineVisual
                }
            }
            .opacity(animateOptions ? 1 : 0)
            .scaleEffect(animateOptions ? 1 : 0.92)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateOptions)
            
            // Subtitle with better visibility
            Text(visual.subtitle)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)
                .opacity(animateContent ? 1 : 0)
        }
    }
    
    // MARK: - Visual Components
    
    private var screenTimeStatsVisual: some View {
        VStack(spacing: 24) {
            // Bar chart visualization - ENHANCED
            VStack(spacing: 16) {
                // Chart header
                HStack {
                    Text("Weekly Screen Time")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("This Week")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.primary.opacity(0.15))
                        )
                }
                
                HStack(alignment: .bottom, spacing: 14) {
                    ForEach(0..<7, id: \.self) { index in
                        VStack(spacing: 10) {
                            // Hour label on top
                            Text("\([3, 4, 5, 4, 4, 5, 6][index])h")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(index == 6 ? AppTheme.primary : AppTheme.textSecondary)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: index == 6 ? [AppTheme.primary, AppTheme.primaryLight] : [Color.gray.opacity(0.4), Color.gray.opacity(0.25)],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 36, height: CGFloat([55, 75, 95, 70, 75, 95, 120][index]))
                                .shadow(color: index == 6 ? AppTheme.primary.opacity(0.3) : .clear, radius: 8, y: 4)
                            
                            Text(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][index])
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(index == 6 ? AppTheme.textPrimary : AppTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.card)
                    .shadow(color: Color.black.opacity(0.08), radius: 20, y: 8)
            )
            
            // Stats row - ENHANCED
            HStack(spacing: 12) {
                statBubble(value: "4.2", unit: "hrs/day", color: Color(hex: "FF6B6B"), icon: "clock.fill")
                statBubble(value: "96", unit: "pickups", color: Color(hex: "FFB347"), icon: "hand.tap.fill")
                statBubble(value: "60+", unit: "days/yr", color: AppTheme.primary, icon: "calendar")
            }
        }
    }
    
    private func statBubble(value: String, unit: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(color)
            Text(unit)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.card)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
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
                Text("Choose Apps to Lock")
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
                    
                    Text("Complete dhikr to unlock")
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
                    Text("Start Dhikr")
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
    
    private var transformationBeforeVisual: some View {
        VStack(spacing: 20) {
            // "Before" badge - ENHANCED
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "FF6B6B"))
                    .frame(width: 10, height: 10)
                Text("YOUR LIFE NOW")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "FF6B6B"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(hex: "FF6B6B").opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "FF6B6B").opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Negative items - ENHANCED
            VStack(spacing: 14) {
                negativeItem(icon: "clock.fill", text: "4+ hours scrolling daily", subtext: "Wasted time")
                negativeItem(icon: "moon.zzz.fill", text: "Missing Fajr", subtext: "Late nights")
                negativeItem(icon: "heart.slash.fill", text: "Feeling guilty & empty", subtext: "After every session")
                negativeItem(icon: "brain.head.profile", text: "Can't focus anymore", subtext: "Short attention span")
            }
        }
    }
    
    private func negativeItem(icon: String, text: String, subtext: String = "") -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FF6B6B").opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "FF6B6B"))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                if !subtext.isEmpty {
                    Text(subtext)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "FF6B6B").opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "FF6B6B").opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
        )
    }
    
    private var transformationAfterVisual: some View {
        VStack(spacing: 20) {
            // "After" badge - ENHANCED
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.success)
                Text("WITH SCROLLDEEDS")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.success)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(AppTheme.success.opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.success.opacity(0.25), lineWidth: 1)
                    )
            )
            
            // Positive items - ENHANCED
            VStack(spacing: 14) {
                positiveItem(icon: "clock.badge.checkmark.fill", text: "Reclaim 2+ hours daily", subtext: "Every single day")
                positiveItem(icon: "sun.horizon.fill", text: "Wake up for Fajr easily", subtext: "Well rested")
                positiveItem(icon: "heart.fill", text: "Peace and barakah", subtext: "In your life")
                positiveItem(icon: "sparkles", text: "100+ daily adhkar", subtext: "Without even trying")
            }
        }
    }
    
    private func positiveItem(icon: String, text: String, subtext: String = "") -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.success.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.success)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                if !subtext.isEmpty {
                    Text(subtext)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(AppTheme.success)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.success.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
        )
    }
    
    private var dailyRoutineVisual: some View {
        VStack(spacing: 24) {
            // Stat circles - ENHANCED
            HStack(spacing: 20) {
                statCircle(percentage: 87, label: "Feel\nGuilty", color: Color(hex: "FF6B6B"), icon: "heart.slash.fill")
                statCircle(percentage: 96, label: "Daily\nPickups", color: Color(hex: "FFB347"), icon: "hand.tap.fill")
                statCircle(percentage: 70, label: "Want\nChange", color: AppTheme.primary, icon: "arrow.up.heart.fill")
            }
            
            // Quote - ENHANCED
            VStack(spacing: 12) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.primary.opacity(0.4))
                
                Text("The guilt you feel is your fitrah")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("telling you something needs to change")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.primary.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
            )
        }
    }
    
    private func statCircle(percentage: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                // Background track
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100)
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                // Center content
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                    Text("\(percentage)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                }
            }
            
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
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
                Text("Which Apps Steal Your Time?")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Select the apps you want to lock with dhikr")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(animateContent ? 1 : 0)
            
            // App selection content
            VStack(spacing: 20) {
                #if canImport(FamilyControls)
                if #available(iOS 16.0, *) {
                    if !shieldManager.selectedApplications.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.success)
                                .font(.system(size: 22))
                            Text("\(shieldManager.selectedApplications.count) apps selected")
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
                        showPermissionView = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: shieldManager.selectedApplications.isEmpty ? "plus.app.fill" : "arrow.triangle.2.circlepath")
                                .font(.system(size: 22))
                            Text(shieldManager.selectedApplications.isEmpty ? "Choose Apps to Lock" : "Change Selection")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.gradientPrimary)
                        .cornerRadius(18)
                        .shadow(color: AppTheme.primary.opacity(0.4), radius: 16, y: 8)
                    }
                    .familyActivityPicker(isPresented: $isAppPickerPresented, selection: $appSelection)
                }
                #endif
            }
            .opacity(animateOptions ? 1 : 0)
            .offset(y: animateOptions ? 0 : 30)
        }
    }
    
    // MARK: - Difficulty Selection View
    
    private var difficultySelectionView: some View {
        VStack(spacing: 28) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(AppTheme.primary)
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.8)
            
            // Title
            VStack(spacing: 10) {
                Text("Choose Your Challenge")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("How long should apps stay unlocked?")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .opacity(animateContent ? 1 : 0)
            
            // Grid of options
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(Array(DifficultyLevel.allCases.enumerated()), id: \.element) { index, level in
                    DifficultyCard(
                        level: level,
                        isSelected: selectedDifficultyLevel == level,
                        onTap: {
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedDifficultyLevel = level
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showDifficultyInfo = level
                            }
                        }
                    )
                    .opacity(animateOptions ? 1 : 0)
                    .offset(y: animateOptions ? 0 : 30)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(Double(index) * 0.08),
                        value: animateOptions
                    )
                }
            }
            .sheet(item: $showDifficultyInfo) { level in
                DifficultyLevelInfoView(level: level) {
                    showDifficultyInfo = nil
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Bottom Button Area
    
    private var bottomButtonArea: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if step > 0 {
                    Button(action: {
                        HapticManager.shared.soft()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            step -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 56, height: 56)
                            .background(AppTheme.card)
                            .cornerRadius(16)
                    }
                }
                
                Button(action: {
                    HapticManager.shared.medium()
                    if step < steps.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            step += 1
                        }
                    } else {
                        finishQuestionnaire()
                    }
                }) {
                    HStack(spacing: 10) {
                        Text(buttonText)
                            .font(.system(size: 18, weight: .bold))
                        
                        if step < steps.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Group {
                            if isButtonDisabled {
                                AppTheme.muted
                            } else {
                                AppTheme.gradientPrimary
                            }
                        }
                    )
                    .cornerRadius(16)
                    .shadow(color: isButtonDisabled ? Color.clear : AppTheme.primary.opacity(0.4), radius: 16, y: 8)
                }
                .disabled(isButtonDisabled)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            AppTheme.card
                .shadow(color: Color.black.opacity(0.1), radius: 20, y: -10)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Helper Views & Functions
    
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
        switch steps[step] {
        case .info:
            return "Continue"
        case .question:
            return "Continue"
        case .appSelection:
            return shieldManager.selectedApplications.isEmpty ? "Select Apps" : "Continue"
        case .difficultySelection:
            return step == steps.count - 1 ? "Let's Go!" : "Continue"
        case .commitment:
            return commitmentAccepted[step] == true ? "I Commit" : "Make Commitment"
        case .freeTrialInfo:
            return "I Understand"
        case .visual:
            return "Continue"
        }
    }
    
    private var isButtonDisabled: Bool {
        switch steps[step] {
        case .info, .freeTrialInfo, .visual:
            return false
        case .question:
            return answers[step] == nil
        case .appSelection:
            return shieldManager.selectedApplications.isEmpty
        case .difficultySelection:
            return selectedDifficultyLevel == nil
        case .commitment:
            return commitmentAccepted[step] != true
        }
    }
    
    private func resetAnimations() {
        animateContent = false
        animateOptions = false
    }
    
    private func startAnimations() {
        pulseAnimation = true
        
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            animateContent = true
        }
        
        withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
            animateOptions = true
        }
    }
    
    private func finishQuestionnaire() {
        HapticManager.shared.success()
        
        localStorage.saveOnboardingAnswers(answers)
        
        // Step 2 is "How many hours do you scroll daily?"
        if let scrollHoursAnswer = answers[1] {
            let hours = [1, 3, 5, 7][scrollHoursAnswer]
            localStorage.onboardingScrollHours = hours
        }
        
        if let level = selectedDifficultyLevel {
            userDataManager.setDifficultyLevel(level)
        }
        
        if !shieldManager.selectedApplications.isEmpty {
            shieldManager.applyShield()
        }
        
        // Track completion
        AnalyticsManager.shared.trackOnboardingCompleted(
            totalSteps: steps.count,
            appsSelected: shieldManager.selectedApplications.count,
            difficultyLevel: selectedDifficultyLevel?.rawValue ?? "unknown"
        )
        
        onFinished()
    }
    
    // MARK: - Analytics Tracking
    
    private func trackStepViewed(step: Int) {
        let stepName = getStepName(for: step)
        let stepType = getStepType(for: step)
        AnalyticsManager.shared.trackOnboardingStep(step: step, stepName: stepName, stepType: stepType)
    }
    
    private func getStepName(for stepIndex: Int) -> String {
        guard stepIndex < steps.count else { return "unknown" }
        switch steps[stepIndex] {
        case .info(let info):
            return info.title
        case .question(let question):
            return question.title
        case .commitment(let commitment):
            return commitment.title
        case .appSelection:
            return "App Selection"
        case .difficultySelection:
            return "Difficulty Selection"
        case .freeTrialInfo:
            return "Free Trial Info"
        case .visual(let visual):
            return visual.title
        }
    }
    
    private func getStepType(for stepIndex: Int) -> String {
        guard stepIndex < steps.count else { return "unknown" }
        switch steps[stepIndex] {
        case .info: return "info"
        case .question: return "question"
        case .commitment: return "commitment"
        case .appSelection: return "app_selection"
        case .difficultySelection: return "difficulty_selection"
        case .freeTrialInfo: return "free_trial"
        case .visual: return "visual"
        }
    }
}

// MARK: - Difficulty Card Component

struct DifficultyCard: View {
    let level: DifficultyLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon with glow
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(level.color.opacity(0.2))
                            .frame(width: 64, height: 64)
                            .blur(radius: 8)
                    }
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    level.color.opacity(isSelected ? 0.25 : 0.12),
                                    level.color.opacity(isSelected ? 0.15 : 0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: level.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(level.color)
                }
                
                // Title
                Text(level.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                
                // Duration badge
                Text(level.displayDuration)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(level.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(level.color.opacity(0.12))
                    .cornerRadius(8)
                
                // Selection indicator
                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Selected")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(level.color)
                } else {
                    Text("Tap to select")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? level.color : AppTheme.muted.opacity(0.3),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? level.color.opacity(0.25) : Color.black.opacity(0.05),
                radius: isSelected ? 12 : 6,
                y: isSelected ? 6 : 3
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    QuestionnaireView(onFinished: {}, shieldManager: ShieldManager.shared, localStorage: LocalStorageManager.shared, userDataManager: UserDataManager())
}
