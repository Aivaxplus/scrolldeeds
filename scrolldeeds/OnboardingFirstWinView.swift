//
//  OnboardingFirstWinView.swift
//  scrolldeeds
//
//  First real product success before the hard paywall.
//  Uses PracticeSessionView (real deed UI) but does NOT grant Screen Time unlock.
//

import SwiftUI

struct OnboardingFirstWinView: View {
    let userName: String?
    let onFinished: () -> Void

    private enum Phase {
        case intro
        case celebration
    }

    @State private var phase: Phase = .intro
    @State private var showPractice = false
    @State private var practiceCompleted = false
    @StateObject private var detector = RecitationDetector()
    @State private var appeared = false
    @State private var celebratePulse = false

    private var displayName: String {
        let trimmed = userName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty { return trimmed }
        return NSLocalizedString("commitment.fallback_name", comment: "there")
    }

    var body: some View {
        ZStack {
            SDPageBackground()
            RadialGradient(
                colors: [
                    AppTheme.primary.opacity(0.12),
                    AppTheme.accent.opacity(0.05),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            switch phase {
            case .intro:
                introContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .celebration:
                celebrationContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .fullScreenCover(isPresented: $showPractice, onDismiss: {
            if practiceCompleted {
                withAnimation(.easeInOut(duration: 0.35)) {
                    phase = .celebration
                }
            }
        }) {
            PracticeSessionView(detector: detector) {
                HeartJourneyManager.shared.clearPendingDeedCoins()
                practiceCompleted = true
                showPractice = false
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    // MARK: - Intro

    private var introContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.14))
                        .frame(width: 108, height: 108)
                        .scaleEffect(appeared ? 1 : 0.85)
                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.primaryLight, AppTheme.primary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                Text(String(format: NSLocalizedString("firstwin.intro.title", comment: ""), displayName))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Text(NSLocalizedString("firstwin.intro.subtitle", comment: ""))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            Spacer(minLength: 24)

            VStack(spacing: 12) {
                Button {
                    HapticManager.shared.heavy()
                    practiceCompleted = false
                    showPractice = true
                } label: {
                    Text(NSLocalizedString("firstwin.intro.cta", comment: ""))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                }
                .buttonStyle(ActionCardButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Celebration

    private var celebrationContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 20) {
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(AppTheme.success.opacity(celebratePulse ? 0 : 0.28 - Double(i) * 0.07), lineWidth: 2)
                            .frame(width: 110 + CGFloat(i) * 30, height: 110 + CGFloat(i) * 30)
                            .scaleEffect(celebratePulse ? 1.45 + CGFloat(i) * 0.12 : 0.85)
                    }
                    Circle()
                        .fill(AppTheme.success.opacity(0.16))
                        .frame(width: 108, height: 108)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundColor(AppTheme.success)
                        .scaleEffect(appeared ? 1 : 0.6)
                }

                Text(NSLocalizedString("firstwin.celebrate.title", comment: ""))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Text(NSLocalizedString("firstwin.celebrate.subtitle", comment: ""))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer(minLength: 24)

            Button {
                HapticManager.shared.heavy()
                onFinished()
            } label: {
                Text(NSLocalizedString("firstwin.celebrate.cta", comment: ""))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
            }
            .buttonStyle(ActionCardButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .onAppear {
            appeared = false
            celebratePulse = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.95)) {
                celebratePulse = true
            }
            HapticManager.shared.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                HapticManager.shared.heavy()
            }
        }
    }
}
