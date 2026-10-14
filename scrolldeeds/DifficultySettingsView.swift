//
//  DifficultySettingsView.swift
//  scrolldeeds
//
//  Change unlock duration tier (Easy / Medium / Hard) after onboarding.
//

import SwiftUI

struct DifficultySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userDataManager = UserDataManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppTheme.primary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("settings.difficulty_level", comment: "Difficulty Level"))
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)

                                    Text(NSLocalizedString("settings.difficulty.subtitle", comment: "Difficulty settings subtitle"))
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(NSLocalizedString("questionnaire.difficulty.subtitle", comment: "Difficulty subtitle"))
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        VStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { index in
                                difficultyRow(index: index)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("common.close", comment: "Close")) {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func difficultyRow(index: Int) -> some View {
        let isSelected = userDataManager.onboardingDifficultyLevel == index
        let minutes = UserDataManager.onboardingUnlockMinutes(forDifficultyLevel: index)

        Button {
            HapticManager.shared.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                userDataManager.setOnboardingDifficultyLevel(index)
            }
            AnalyticsManager.shared.trackOnboardingDifficultySelected(
                level: AnalyticsAnswerLabel.difficulty(level: index),
                unlockMinutes: minutes,
                source: "settings"
            )
            PostHogManager.shared.identifyCurrentUser()
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(difficultyTitle(for: index))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text(String(format: NSLocalizedString("questionnaire.difficulty.minutes_badge", comment: "%d min"), minutes))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isSelected ? .white : AppTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(isSelected ? AppTheme.primary : AppTheme.primary.opacity(0.12))
                            )
                    }

                    Text(difficultySubtitle(for: index))
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.primary)
                } else {
                    Circle()
                        .stroke(AppTheme.textMuted.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppTheme.primary.opacity(0.08) : AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.primary.opacity(0.45) : AppTheme.border, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func difficultyTitle(for index: Int) -> String {
        switch index {
        case 0: return NSLocalizedString("questionnaire.difficulty.option.easy.title", comment: "")
        case 1: return NSLocalizedString("questionnaire.difficulty.option.medium.title", comment: "")
        default: return NSLocalizedString("questionnaire.difficulty.option.hard.title", comment: "")
        }
    }

    private func difficultySubtitle(for index: Int) -> String {
        switch index {
        case 0: return NSLocalizedString("questionnaire.difficulty.option.easy.subtitle", comment: "")
        case 1: return NSLocalizedString("questionnaire.difficulty.option.medium.subtitle", comment: "")
        default: return NSLocalizedString("questionnaire.difficulty.option.hard.subtitle", comment: "")
        }
    }
}

#Preview {
    DifficultySettingsView()
}
