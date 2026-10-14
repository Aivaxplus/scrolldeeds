//
//  PostSubscribeDifficultyView.swift
//  scrolldeeds
//
//  Difficulty picker shown after Thank You → app selection (post-paywall).
//

import SwiftUI

struct PostSubscribeDifficultyView: View {
    let onContinue: () -> Void

    @ObservedObject private var userDataManager = UserDataManager.shared
    @State private var selectedIndex: Int = 1
    @State private var animateContent = false
    @State private var animateOptions = false

    var body: some View {
        ZStack {
            SDPageBackground()

            RadialGradient(
                colors: [AppTheme.primary.opacity(0.08), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)

                            VStack(spacing: 12) {
                                OnboardingHeroEmojiIcon(
                                    emoji: "🎚️",
                                    glowColor: AppTheme.primary,
                                    revealed: animateContent
                                )

                                VStack(spacing: 8) {
                                    Text(NSLocalizedString("questionnaire.difficulty.title", comment: "Difficulty title"))
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Text(NSLocalizedString("questionnaire.difficulty.subtitle", comment: "Difficulty subtitle"))
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                            }

                            VStack(spacing: 10) {
                                ForEach(0..<3, id: \.self) { index in
                                    difficultyRow(index: index)
                                        .opacity(animateOptions ? 1 : 0)
                                        .offset(y: animateOptions ? 0 : 20)
                                        .animation(
                                            .spring(response: 0.5, dampingFraction: 0.7)
                                                .delay(Double(index) * 0.06),
                                            value: animateOptions
                                        )
                                }
                            }
                            .padding(.top, 16)

                            Spacer(minLength: 8)
                        }
                        .padding(.horizontal, 24)
                        .frame(minHeight: geo.size.height)
                    }
                }

                Button(action: {
                    HapticManager.shared.success()
                    userDataManager.setOnboardingDifficultyLevel(selectedIndex)
                    let minutes = UserDataManager.onboardingUnlockMinutes(forDifficultyLevel: selectedIndex)
                    AnalyticsManager.shared.trackOnboardingDifficultySelected(
                        level: AnalyticsAnswerLabel.difficulty(level: selectedIndex),
                        unlockMinutes: minutes,
                        source: "post_subscribe"
                    )
                    PostHogManager.shared.identifyCurrentUser()
                    onContinue()
                }) {
                    Text(NSLocalizedString("questionnaire.continue", comment: "Continue"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 16)
                .opacity(animateContent ? 1 : 0)
            }
        }
        .onAppear {
            PostHogManager.shared.screen(AnalyticsScreen.difficultySelection)
            selectedIndex = min(2, max(0, userDataManager.onboardingDifficultyLevel))
            userDataManager.setOnboardingDifficultyLevel(selectedIndex)
            withAnimation(.easeOut(duration: 0.45)) {
                animateContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animateOptions = true
                }
            }
        }
    }

    private func difficultyRow(index: Int) -> some View {
        let isSelected = selectedIndex == index
        let tint = tint(for: index)
        let minutes = UserDataManager.onboardingUnlockMinutes(forDifficultyLevel: index)
        let badge = String(
            format: NSLocalizedString("questionnaire.difficulty.minutes_badge", comment: "%d min"),
            minutes
        )
        let pillFill = tint.opacity(isSelected ? 0.24 : 0.16)
        let pillStroke = tint.opacity(isSelected ? 0.45 : 0.32)

        return Button {
            HapticManager.shared.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedIndex = index
            }
            userDataManager.setOnboardingDifficultyLevel(index)
        } label: {
            HStack(alignment: .top, spacing: 14) {
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
                        Text(title(for: index))
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(tint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 4)
                        Text(badge)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(tint)
                            .fixedSize()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule(style: .continuous).fill(pillFill))
                            .overlay(Capsule(style: .continuous).strokeBorder(pillStroke, lineWidth: 1))
                    }
                    Text(subtitle(for: index))
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
        }
        .buttonStyle(.plain)
    }

    private func tint(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.28, green: 0.70, blue: 0.48)
        case 1: return Color(red: 0.94, green: 0.62, blue: 0.22)
        default: return Color(red: 0.88, green: 0.38, blue: 0.42)
        }
    }

    private func title(for index: Int) -> String {
        switch index {
        case 0: return NSLocalizedString("questionnaire.difficulty.option.easy.title", comment: "")
        case 1: return NSLocalizedString("questionnaire.difficulty.option.medium.title", comment: "")
        default: return NSLocalizedString("questionnaire.difficulty.option.hard.title", comment: "")
        }
    }

    private func subtitle(for index: Int) -> String {
        switch index {
        case 0: return NSLocalizedString("questionnaire.difficulty.option.easy.subtitle", comment: "")
        case 1: return NSLocalizedString("questionnaire.difficulty.option.medium.subtitle", comment: "")
        default: return NSLocalizedString("questionnaire.difficulty.option.hard.subtitle", comment: "")
        }
    }
}
