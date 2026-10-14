import SwiftUI

struct ReferralCodeOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var referralManager = ReferralManager.shared
    @State private var enteredCode: String = ""
    @FocusState private var codeFocused: Bool

    let initialCode: String
    let onContinue: (String?) -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            SDPageBackground()

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
                        endRadius: 170
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 36)
                .offset(y: -180)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                    referralManager.clearAll()
                        onSkip()
                        dismiss()
                    } label: {
                        Text(NSLocalizedString("referral.skip", comment: "Skip"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer().frame(height: 28)

                VStack(alignment: .leading, spacing: 24) {
                    Text(NSLocalizedString("referral.optional", comment: "Optional"))
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.95))

                    Text(NSLocalizedString("referral.title", comment: "Do you have a referral code?"))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField(NSLocalizedString("referral.placeholder", comment: "Enter referral code"), text: $enteredCode)
                        .focused($codeFocused)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(AppTheme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    AppTheme.primary.opacity(0.18),
                                                    AppTheme.border.opacity(0.35)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )

                    Text(NSLocalizedString("referral.helper", comment: "Enter a code from a creator or friend."))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                Button {
                    let sanitized = enteredCode
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .uppercased()
                    if sanitized.isEmpty {
                        referralManager.clearAll()
                        onContinue(nil)
                        dismiss()
                        return
                    }
                    Task {
                        let valid = await referralManager.validateCode(sanitized)
                        if valid {
                            onContinue(sanitized)
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if referralManager.isValidating {
                            SwiftUI.ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        }
                        Text(
                            referralManager.isValidating
                            ? NSLocalizedString("referral.checking", comment: "Checking...")
                            : NSLocalizedString("referral.continue", comment: "Continue")
                        )
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(referralManager.isValidating)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .bottom) {
            if let error = referralManager.validationError, !error.isEmpty {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.red.opacity(0.95))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
        }
        .onAppear {
            enteredCode = initialCode
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                codeFocused = true
            }
        }
    }
}

struct PaywallInlineRedeem: View {
    @Binding var isPresented: Bool
    @Binding var draft: String
    var appliedCode: String?
    var isApplying: Bool
    var error: String?
    var onApply: () -> Void
    var onRestore: () -> Void
    var showsRestore: Bool = true

    var body: some View {
        HStack(spacing: 18) {
            Button(action: presentSheet) {
                HStack(spacing: 5) {
                    if let appliedCode {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                        Text(appliedCode)
                    } else {
                        Text(NSLocalizedString("conv_paywall.redeem", comment: "Redeem code"))
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .buttonStyle(.plain)

            if showsRestore {
                Button(action: onRestore) {
                    Text(NSLocalizedString("paywall.restore", comment: "Restore"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func presentSheet() {
        if let appliedCode, draft.isEmpty {
            draft = appliedCode
        }
        HapticManager.shared.soft()
        isPresented = true
    }
}

struct RedeemCodeSheet: View {
    @Binding var draft: String
    var isApplying: Bool
    var error: String?
    var onApply: () -> Void
    var onClose: () -> Void

    @FocusState private var fieldFocused: Bool

    private var canApply: Bool {
        !isApplying && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                PaywallCloseButton(
                    iconColor: UIColor(AppTheme.textMuted),
                    backgroundColor: UIColor(AppTheme.cardSecondary),
                    action: onClose
                )
                .frame(width: 28, height: 28)
            }

            SDIconBadge(systemName: "ticket.fill", size: 52, iconSize: 22)

            VStack(spacing: 8) {
                Text(NSLocalizedString("conv_paywall.redeem", comment: "Redeem code"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(NSLocalizedString("referral.helper", comment: "Enter a code from a creator or friend."))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextField(
                NSLocalizedString("referral.placeholder", comment: "Enter referral code"),
                text: $draft
            )
            .focused($fieldFocused)
            .textInputAutocapitalization(.characters)
            .disableAutocorrection(true)
            .submitLabel(.done)
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(AppTheme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                fieldFocused ? AppTheme.primary.opacity(0.55) : AppTheme.border.opacity(0.75),
                                lineWidth: fieldFocused ? 1.5 : 1
                            )
                    )
            )
            .onSubmit {
                guard canApply else { return }
                onApply()
            }

            if let error, !error.isEmpty {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.error)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button(action: onApply) {
                HStack(spacing: 8) {
                    if isApplying {
                        SwiftUI.ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(
                        isApplying
                        ? NSLocalizedString("referral.checking", comment: "Checking...")
                        : NSLocalizedString("paywall.redeem.apply", comment: "Apply")
                    )
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canApply)
            .opacity(canApply ? 1 : 0.55)
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.border.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 24, y: 10)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                fieldFocused = true
            }
        }
    }
}

