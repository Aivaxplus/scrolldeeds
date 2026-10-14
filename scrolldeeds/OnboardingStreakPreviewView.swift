//
//  OnboardingStreakPreviewView.swift
//  scrolldeeds
//
//  Shown in the questionnaire after the interactive demo (“That’s how it works”).
//

import SwiftUI

struct OnboardingStreakPreviewView: View {

    @State private var flameOn = false
    @State private var flamePulse = false
    @State private var numberOn = false
    @State private var subtitleOn = false
    @State private var bodyOn = false
    @State private var cardOn = false

    private let previewStreak = 1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let contentW = min(w, 420)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                streakContent(maxWidth: contentW)
                    .frame(maxWidth: contentW)

                Spacer(minLength: 0)
            }
            .frame(width: w, height: geo.size.height)
        }
        .onAppear {
            PostHogManager.shared.screen(AnalyticsScreen.streakPreview)
            PostHogManager.shared.trackOnboardingStreakPreviewViewed()
            runEntranceAnimation()
        }
    }

    // MARK: - Content

    private func streakContent(maxWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Flame
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.accent.opacity(0.28), AppTheme.accent.opacity(0.06), Color.clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 72
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(flameOn ? 1 : 0.4)
                    .opacity(flameOn ? 1 : 0)

                Text("🔥")
                    .font(.system(size: 64))
                    .scaleEffect(flameOn ? 1 : 0.35)
                    .rotationEffect(.degrees(flameOn ? 0 : -18))
                    .offset(y: flamePulse ? -5 : 0)
                    .animation(
                        flameOn
                            ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                            : .default,
                        value: flamePulse
                    )
            }
            .padding(.bottom, 8)

            // Big number + “day streak”
            VStack(spacing: 4) {
                Text("\(previewStreak)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.textPrimary, AppTheme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(numberOn ? 1 : 0.5)
                    .opacity(numberOn ? 1 : 0)
                    .blur(radius: numberOn ? 0 : 4)

                Text(NSLocalizedString("onboarding.streak.day_streak_label", comment: "day streak"))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .opacity(subtitleOn ? 1 : 0)
                    .offset(y: subtitleOn ? 0 : 4)
            }
            .padding(.bottom, 14)

            Text(NSLocalizedString("onboarding.streak.preview_body", comment: ""))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 28)
                .opacity(bodyOn ? 1 : 0)
                .offset(y: bodyOn ? 0 : 4)
                .padding(.bottom, 22)

            // Week strip card
            OnboardingPreviewWeekStrip(cardRevealed: cardOn)
                .padding(.vertical, 18)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppTheme.card.opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(AppTheme.border.opacity(0.35), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .scaleEffect(cardOn ? 1 : 0.92)
                .opacity(cardOn ? 1 : 0)
                .offset(y: cardOn ? 0 : 24)
        }
        .frame(maxWidth: maxWidth)
    }

    private func runEntranceAnimation() {
        withAnimation(.easeInOut(duration: 0.85)) {
            flameOn = true
        }
        HapticManager.shared.animationReveal(beat: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            flamePulse = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.95)) {
                numberOn = true
            }
            HapticManager.shared.animationReveal(beat: 1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeInOut(duration: 1.0)) {
                subtitleOn = true
            }
            HapticManager.shared.animationReveal(beat: 2)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 1.1)) {
                bodyOn = true
            }
            HapticManager.shared.animationReveal(beat: 3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            withAnimation(.easeInOut(duration: 1.0)) {
                cardOn = true
            }
            HapticManager.shared.animationReveal(beat: 4)
        }
    }
}

// MARK: - Week strip (preview: today highlighted, ScrollDeeds green)

private struct OnboardingPreviewWeekStrip: View {
    var cardRevealed: Bool
    private let cal = Calendar.current

    var body: some View {
        let days = weekDays()
        HStack(spacing: 0) {
            ForEach(days.indices, id: \.self) { i in
                OnboardingPreviewDayCell(date: days[i], animDelay: Double(i) * 0.055, cardRevealed: cardRevealed)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func weekDays() -> [Date] {
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let sunday = cal.date(byAdding: .day, value: -(weekday - 1), to: today)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: sunday) }
    }
}

private struct OnboardingPreviewDayCell: View {
    let date: Date
    let animDelay: Double
    var cardRevealed: Bool

    @ObservedObject private var languageManager = LanguageManager.shared
    private let cal = Calendar.current

    @State private var appeared = false

    private var isToday: Bool { cal.isDateInToday(date) }
    private var isFuture: Bool { date > cal.startOfDay(for: Date()) }

    private var dayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale(identifier: languageManager.currentLanguage)
        return f.string(from: date).prefix(2).lowercased()
    }

    private var dayNumber: Int { cal.component(.day, from: date) }

    var body: some View {
        VStack(spacing: 6) {
            Text(String(dayLabel))
                .font(.system(size: 11, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? AppTheme.textPrimary : AppTheme.textMuted)

            ZStack {
                if isToday {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 38, height: 38)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                        .frame(width: 38, height: 38)
                    Text("\(dayNumber)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else if isFuture {
                    Circle()
                        .stroke(
                            style: StrokeStyle(lineWidth: 1.2, dash: [3, 3])
                        )
                        .foregroundColor(AppTheme.textMuted.opacity(0.22))
                        .frame(width: 36, height: 36)
                    Text("\(dayNumber)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textMuted.opacity(0.45))
                } else {
                    Circle()
                        .fill(AppTheme.textMuted.opacity(0.08))
                        .frame(width: 36, height: 36)
                    Circle()
                        .strokeBorder(AppTheme.textMuted.opacity(0.18), lineWidth: 1)
                        .frame(width: 36, height: 36)
                    Text("\(dayNumber)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textMuted.opacity(0.55))
                }
            }
            .scaleEffect(appeared ? 1 : 0.4)
            .opacity(appeared ? 1 : 0)
        }
        .onChange(of: cardRevealed) { revealed in
            guard revealed else { return }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72).delay(animDelay)) {
                appeared = true
            }
        }
    }
}

#Preview {
    ZStack {
        OnboardingView.pageBg.ignoresSafeArea()
        OnboardingStreakPreviewView()
    }
}
