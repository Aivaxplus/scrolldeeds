//
//  CustomLockView.swift
//
//  Quiet lock page: Nafsi character, earn coins, or buy hearts.
//

import SwiftUI

struct CustomLockView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showDhikr = false
    @State private var appeared = false
    var onUnlock: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    var onRequiresUpgrade: (() -> Void)? = nil
    var onBuyHearts: (() -> Void)? = nil

    var body: some View {
        ZStack {
            SDPageBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    PaywallCloseButton(
                        iconColor: UIColor(AppTheme.textMuted),
                        backgroundColor: UIColor(AppTheme.card),
                        action: { onDismiss?() }
                    )
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer(minLength: 24)

                VStack(spacing: 26) {
                    VStack(spacing: 16) {
                        WeakNafsiLockArt()
                            .scaleEffect(appeared ? 1 : 0.94)

                        emptyHeartsFrame
                    }

                    VStack(spacing: 10) {
                        Text(NSLocalizedString("lock.title", comment: "Your apps are locked"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(NSLocalizedString("lock.unlock_message", comment: "Nafsi has no hearts and needs them refilled"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 32)

                    if subscriptionManager.hasLapsedAccess {
                        Text(NSLocalizedString("access.expired.lock_note", comment: "Your access has ended — reactivate to unlock."))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    Button(action: startDeed) {
                        Text(NSLocalizedString("deed.cta", comment: "Earn coins"))
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        HapticManager.shared.soft()
                        onBuyHearts?()
                    } label: {
                        Text(NSLocalizedString("nafsi.hearts.buy", comment: "Buy hearts"))
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .fullScreenCover(isPresented: $showDhikr) {
            PracticeSessionView(detector: RecitationDetector()) {
                showDhikr = false
                onUnlock?()
            }
        }
        .trackScreen(AnalyticsScreen.lock)
    }

    private func startDeed() {
        HapticManager.shared.medium()
        // Match dashboard `startDeedFlow`: show paywall immediately when access is gone.
        // Do not block the tap on a network refresh (that felt like “nothing happens”).
        if subscriptionManager.hasPremiumAccess {
            showDhikr = true
            Task { @MainActor in
                guard await subscriptionManager.refreshPremiumStatus() else {
                    showDhikr = false
                    onRequiresUpgrade?()
                    return
                }
            }
            return
        }
        onRequiresUpgrade?()
    }

    /// Five empty hearts, so the lock reads as an empty tank.
    private var emptyHeartsFrame: some View {
        HStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                Image(systemName: "heart")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.textMuted.opacity(0.72))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border.opacity(0.6), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(format: NSLocalizedString("nafsi.hearts.count", comment: "%d of %d hearts"), 0, 5)
        )
    }
}

/// Drained Nafsi: a red outline that fades outward while the figure pulses.
private struct WeakNafsiLockArt: View {
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let outline = Color(red: 0.86, green: 0.15, blue: 0.18)

    var body: some View {
        ZStack {
            silhouette
                .blur(radius: pulse ? 20 : 7)
                .opacity(pulse ? 0.08 : 0.62)
                .scaleEffect(pulse ? 1.09 : 1.03)

            silhouette
                .blur(radius: pulse ? 5 : 1.2)
                .opacity(pulse ? 0.16 : 0.9)
                .scaleEffect(pulse ? 1.05 : 1.015)

            Image("NafsiPoseWeak")
                .resizable()
                .scaledToFit()
                .scaleEffect(pulse ? 1.04 : 0.985)
        }
        .frame(height: 196)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.45).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityHidden(true)
    }

    private var silhouette: some View {
        Image("NafsiPoseWeak")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(outline)
    }
}

#Preview {
    CustomLockView(onUnlock: nil, onDismiss: nil)
}
