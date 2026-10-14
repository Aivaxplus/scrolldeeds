//
//  InAppFeedbackView.swift
//  scrolldeeds
//
//  Dashboard + Settings card that opens a sheet. Submissions go to PostHog.
//

import SwiftUI

enum InAppFeedbackSource: String {
    case dashboard
    case settings
}

struct InAppFeedbackCard: View {
    let source: InAppFeedbackSource
    @Binding var isPresented: Bool
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppTheme.primary.opacity(0.12)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(NSLocalizedString("inapp_feedback.card.title", comment: "Send us feedback"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(NSLocalizedString("inapp_feedback.card.badge", comment: "Goes to the ScrollDeeds team"))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.primary)
                }
            }

            Text(NSLocalizedString("inapp_feedback.card.body", comment: "Tell us what to fix, add, or make clearer."))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                HapticManager.shared.medium()
                PostHogManager.shared.trackInAppFeedbackOpened(source: source.rawValue)
                isPresented = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(NSLocalizedString("inapp_feedback.card.cta", comment: "Write feedback"))
                }
            }
            .buttonStyle(PrimaryButtonStyle(verticalPadding: 14))
        }
        .sdSurfaceCard(cornerRadius: AppRadius.lg, padding: AppSpacing.lg)
        .id(languageManager.currentLanguage)
    }
}

struct InAppFeedbackSheet: View {
    let source: InAppFeedbackSource
    @Binding var isPresented: Bool

    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEditorFocused: Bool

    @State private var message = ""
    @State private var didSend = false
    @State private var isSending = false

    private let maxCharacters = 2000

    private var trimmed: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        trimmed.count >= 3 && trimmed.count <= maxCharacters && !isSending
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if didSend {
                    thanksState
                } else {
                    composeState
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.close", comment: "Close")) {
                        HapticManager.shared.soft()
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .id(languageManager.currentLanguage)
        .onAppear {
            PostHogManager.shared.screen(AnalyticsScreen.inAppFeedback)
        }
    }

    private var composeState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("inapp_feedback.sheet.title", comment: "How can we do better?"))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(NSLocalizedString("inapp_feedback.sheet.subtitle", comment: "A bug, an idea, or something that felt unclear — we read every note."))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        Text(NSLocalizedString("inapp_feedback.sheet.placeholder", comment: "Write your feedback here…"))
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textMuted)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $message)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(minHeight: 180)
                        .focused($isEditorFocused)
                        .onChange(of: message) { newValue in
                            if newValue.count > maxCharacters {
                                message = String(newValue.prefix(maxCharacters))
                            }
                        }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppTheme.border.opacity(0.55), lineWidth: 1)
                )

                Text("\(trimmed.count)/\(maxCharacters)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Button {
                    send()
                } label: {
                    HStack(spacing: 8) {
                        if isSending {
                            SwiftUI.ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text(NSLocalizedString("inapp_feedback.sheet.send", comment: "Send to the team"))
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canSend)
                .opacity(canSend ? 1 : 0.55)
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var thanksState: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundColor(AppTheme.primary)
            Text(NSLocalizedString("inapp_feedback.sheet.thanks_title", comment: "JazakAllahu khayran"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
            Text(NSLocalizedString("inapp_feedback.sheet.thanks_body", comment: "Your note reached the team. We use this to make ScrollDeeds better."))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            Button {
                HapticManager.shared.success()
                isPresented = false
            } label: {
                Text(NSLocalizedString("inapp_feedback.sheet.done", comment: "Done"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 8)
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private func send() {
        guard canSend else { return }
        isEditorFocused = false
        isSending = true
        HapticManager.shared.medium()
        PostHogManager.shared.trackInAppFeedbackSubmitted(
            message: trimmed,
            source: source.rawValue
        )
        isSending = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            didSend = true
        }
        HapticManager.shared.success()
    }
}
