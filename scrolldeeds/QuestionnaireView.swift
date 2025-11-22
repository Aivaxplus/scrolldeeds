import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif

struct QuestionnaireView: View {
    struct Question {
        let icon: String
        let title: String
        let subtitle: String
        let options: [String]
        let isAppSelection: Bool
        
        init(icon: String, title: String, subtitle: String, options: [String], isAppSelection: Bool = false) {
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
            self.options = options
            self.isAppSelection = isAppSelection
        }
    }

    let onFinished: () -> Void
    @ObservedObject var shieldManager: ShieldManager
    @ObservedObject var localStorage: LocalStorageManager
    
    @State private var step: Int = 0
    @State private var answers: [Int: Int] = [:]
    @State private var isAppPickerPresented: Bool = false
    @State private var showPermissionView: Bool = false
    
    #if canImport(FamilyControls)
    @State private var appSelection = FamilyActivitySelection()
    #endif

    private let questions: [Question] = [
        .init(icon: "clock.fill", title: "How many hours do you scroll every day?", subtitle: "Be honest. Check your screen time right now.", options: ["Less than 2 hours","2-4 hours","4-6 hours","More than 6 hours"]),
        .init(icon: "exclamationmark.circle.fill", title: "How hard is it for you to stop scrolling?", subtitle: "Can you put your phone down when you want to?", options: ["Easy to stop","Somewhat difficult","Very difficult","Almost impossible"]),
        .init(icon: "heart.fill", title: "Do you feel guilty after scrolling?", subtitle: "That empty feeling when you realize you wasted time.", options: ["Rarely","Sometimes","Often","Always"]),
        .init(icon: "target", title: "What are you avoiding by scrolling?", subtitle: "Be honest about what you're running from.", options: ["Work or responsibilities","Difficult emotions","Real connections","Everything"]),
        .init(icon: "lock.iphone", title: "Which apps do you want to lock?", subtitle: "Select the apps you spend too much time on.", options: [], isAppSelection: true)
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                VStack(spacing: 12) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppTheme.muted)
                            Capsule()
                                .fill(AppTheme.gradientPrimary)
                                .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(questions.count))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("Question \(step + 1) of \(questions.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text("\(Int((Double(step + 1) / Double(questions.count)) * 100))%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 32)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        let q = questions[step]
                        
                        // Icon
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: q.icon)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(AppTheme.primary)
                        }
                        .padding(.top, 8)
                        
                        // Question
                        VStack(spacing: 12) {
                            Text(q.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                            
                            Text(q.subtitle)
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .padding(.horizontal, 24)
                        
                        // Options or App Picker
                        if q.isAppSelection {
                            // App Selection Screen
                            appSelectionView
                        } else {
                            // Regular Options
                            VStack(spacing: 12) {
                                ForEach(q.options.indices, id: \.self) { idx in
                                    optionButton(text: q.options[idx], isSelected: answers[step] == idx)
                                        .onTapGesture {
                                            HapticManager.shared.selection()
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                answers[step] = idx
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.bottom, 120)
                }
                
                // Bottom Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        if step > 0 {
                            Button(action: {
                                HapticManager.shared.onboardingBack()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    step -= 1
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Back")
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle(isLarge: false))
                        }
                        
                        Button(action: {
                            if step < questions.count - 1 {
                                // Move to next step
                                HapticManager.shared.onboardingNext()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    step += 1
                                }
                            } else {
                                // Last step - lock apps and finish
                                finishQuestionnaire()
                            }
                        }) {
                            HStack {
                                let currentQ = questions[step]
                                Text(getButtonText(for: currentQ))
                                if step < questions.count - 1 {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isButtonDisabled)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    AppTheme.card
                        .shadow(color: Color.black.opacity(0.08), radius: 20, y: -10)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        #if canImport(FamilyControls)
        .onChange(of: isAppPickerPresented) { _ in
            if !isAppPickerPresented {
                // Save selected apps
                shieldManager.updateSelection(apps: appSelection.applications)
            }
        }
        .fullScreenCover(isPresented: $showPermissionView) {
            FamilyControlsPermissionView(isPresented: $showPermissionView) {
                // Permission approved! Now show app picker
                debugPrint("✅ Permission approved from permission view!")
                isAppPickerPresented = true
            }
        }
        #endif
    }
    
    private func getButtonText(for question: Question) -> String {
        if step == questions.count - 1 {
            return "Get Started" // Last step
        } else if question.isAppSelection {
            return "Continue"
        } else {
            return "Continue"
        }
    }
    
    private var isButtonDisabled: Bool {
        let currentQuestion = questions[step]
        if currentQuestion.isAppSelection {
            return shieldManager.selectedApplications.isEmpty
        } else {
            return answers[step] == nil
        }
    }
    
    private var appSelectionView: some View {
        VStack(spacing: 20) {
            #if canImport(FamilyControls)
            if #available(iOS 16.0, *) {
                // Selected apps count
                if !shieldManager.selectedApplications.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.success)
                        Text("\(shieldManager.selectedApplications.count) apps selected")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.success.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Choose Apps Button
                Button(action: {
                    // First request permission, then show picker
                    showPermissionView = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.app.fill")
                            .font(.system(size: 20))
                        Text(shieldManager.selectedApplications.isEmpty ? "Choose Apps to Lock" : "Change Selection")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.gradientPrimary)
                    .cornerRadius(16)
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 12, y: 6)
                }
                .familyActivityPicker(isPresented: $isAppPickerPresented, selection: $appSelection)
                
                // Info card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppTheme.primary)
                        Text("How it works")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    Text("These apps will be locked by default. Recite dhikr 3 times to earn 15 minutes of access. When time is up, ScrollDeeds keeps sounding alarms until you relock.")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineSpacing(4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                )
            } else {
                Text("App locking requires iOS 16+")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
            }
            #else
            Text("App locking not available")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textSecondary)
            #endif
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    
    private func finishQuestionnaire() {
        HapticManager.shared.onboardingComplete()
        
        // Save all answers locally
        localStorage.saveOnboardingAnswers(answers)
        
        // Save the first answer (scroll hours) for progress tracking
        if let scrollHoursAnswer = answers[0] {
            // Map answer index to hours: 0:<2, 1:2-4, 2:4-6, 3:>6
            let hours = [1, 3, 5, 7][scrollHoursAnswer]
            localStorage.onboardingScrollHours = hours
        }
        
        // Apply shield to lock selected apps
        if !shieldManager.selectedApplications.isEmpty {
            shieldManager.applyShield()
        }
        
        // Mark onboarding as complete and finish
        onFinished()
    }

    private func optionButton(text: String, isSelected: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .strokeBorder(isSelected ? AppTheme.primary : AppTheme.textMuted.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 12, height: 12)
                }
            }
            
            Text(text)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
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
                        .strokeBorder(isSelected ? AppTheme.primary.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: isSelected ? AppTheme.primary.opacity(0.15) : Color.black.opacity(0.04), radius: isSelected ? 8 : 4, y: 2)
    }
}

#Preview { QuestionnaireView(onFinished: {}, shieldManager: ShieldManager.shared, localStorage: LocalStorageManager.shared) }


