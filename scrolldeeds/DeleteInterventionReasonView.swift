import SwiftUI

private enum LeaveReasonOption: String, CaseIterable, Identifiable {
    case expensive
    case noTime
    case unclear
    case noResults
    case technical
    case other

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .expensive: return "delete_intervention.reason.option.expensive"
        case .noTime: return "delete_intervention.reason.option.no_time"
        case .unclear: return "delete_intervention.reason.option.unclear"
        case .noResults: return "delete_intervention.reason.option.no_results"
        case .technical: return "delete_intervention.reason.option.technical"
        case .other: return "delete_intervention.reason.option.other"
        }
    }

    var title: String {
        NSLocalizedString(titleKey, comment: "")
    }
}

struct DeleteInterventionReasonView: View {
    let onContinue: () -> Void
    let onDismiss: () -> Void

    @State private var selectedOption: LeaveReasonOption?
    @State private var customReasonText: String = ""
    @FocusState private var editorFocused: Bool

    private static let pageBg = AppTheme.background
    private let maxCustomLength = 500

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DeleteInterventionReasonView.pageBg
                    .ignoresSafeArea()

                RadialGradient(
                    colors: [
                        AppTheme.primary.opacity(0.12),
                        AppTheme.primary.opacity(0.04),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 420
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(AppTheme.card.opacity(0.85))
                                        .overlay(
                                            Circle()
                                                .stroke(AppTheme.border.opacity(0.45), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, geometry.safeAreaInsets.top + 8)

                    Spacer().frame(height: 16)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(NSLocalizedString("delete_intervention.reason.screen_title", comment: ""))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(NSLocalizedString("delete_intervention.reason.intro", comment: ""))
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(NSLocalizedString("delete_intervention.reason.pick_prompt", comment: ""))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.top, 4)

                            VStack(spacing: 10) {
                                ForEach(LeaveReasonOption.allCases) { option in
                                    reasonRow(option: option)
                                }
                            }

                            if selectedOption == .other {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(NSLocalizedString("delete_intervention.reason.custom_title", comment: ""))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)

                                    ZStack(alignment: .topLeading) {
                                        TextEditor(text: $customReasonText)
                                            .focused($editorFocused)
                                            .scrollContentBackground(.hidden)
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(AppTheme.textPrimary)
                                            .frame(minHeight: 100, maxHeight: 160)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(AppTheme.background.opacity(0.35))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .stroke(AppTheme.border.opacity(0.5), lineWidth: 1)
                                                    )
                                            )
                                            .onChange(of: customReasonText) { newValue in
                                                if newValue.count > maxCustomLength {
                                                    customReasonText = String(newValue.prefix(maxCustomLength))
                                                }
                                            }

                                        if customReasonText.isEmpty {
                                            Text(NSLocalizedString("delete_intervention.reason.custom_placeholder", comment: ""))
                                                .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(AppTheme.textMuted)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 18)
                                                .allowsHitTesting(false)
                                        }
                                    }

                                    Text("\(customReasonText.count)/\(maxCustomLength)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppTheme.textMuted)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                .padding(.top, 4)
                            }

                            Text(NSLocalizedString("delete_intervention.reason.footer_encourage", comment: ""))
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(NSLocalizedString("delete_intervention.reason.footer_growth", comment: ""))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.primary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 22)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(AppTheme.card.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(AppTheme.border.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }

                    Button(action: submitAndContinue) {
                        HStack(spacing: 10) {
                            Text(NSLocalizedString("delete_intervention.reason.cta_continue", comment: ""))
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                    }
                    .buttonStyle(ActionCardButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(24, geometry.safeAreaInsets.bottom + 8))
                }
            }
        }
    }

    @ViewBuilder
    private func reasonRow(option: LeaveReasonOption) -> some View {
        let isSelected = selectedOption == option
        Button {
            HapticManager.shared.soft()
            selectedOption = option
            if option != .other {
                editorFocused = false
                customReasonText = ""
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Text(option.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? AppTheme.primary : AppTheme.textMuted.opacity(0.5),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? AppTheme.primary.opacity(0.08) : AppTheme.cardSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? AppTheme.primary.opacity(0.85) : AppTheme.border.opacity(0.45),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func submitAndContinue() {
        editorFocused = false
        let trimmedCustom = customReasonText.trimmingCharacters(in: .whitespacesAndNewlines)

        var props: [String: Any] = [
            "has_selection": selectedOption != nil
        ]
        if let opt = selectedOption {
            props["reason_option"] = opt.rawValue
        }
        if selectedOption == .other {
            props["has_custom_text"] = !trimmedCustom.isEmpty
            if !trimmedCustom.isEmpty {
                props["custom_preview"] = String(trimmedCustom.prefix(500))
            }
        }

        PostHogManager.shared.track("Delete Intervention Reason Submitted", properties: props)
        onContinue()
    }
}

#Preview {
    DeleteInterventionReasonView(onContinue: {}, onDismiss: {})
}
