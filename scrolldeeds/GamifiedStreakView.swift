//
//  GamifiedStreakView.swift
//  scrolldeeds
//
//  Cal AI-style week streak strip in a soft Nafsi card.
//

import SwiftUI
import Combine

// MARK: - Week Streak Strip

/// Drives `sheet(item:)` so the milestone sheet always has a concrete value (never an empty `if let` body).
private struct MilestoneSheetItem: Identifiable {
    let id: Int
}

struct GamifiedStreakView: View {
    @ObservedObject var userDataManager: UserDataManager
    /// While the practice session sheet is presented, streak celebration sheets must not stack on top — iOS 18+ often shows a blank dark sheet instead.
    @Binding var practiceSheetPresented: Bool
    @ObservedObject private var languageManager = LanguageManager.shared

    @State private var appeared          = false
    @State private var showDailyAchieve  = false
    @State private var milestoneSheetItem: MilestoneSheetItem?
    @State private var dailyAchieveWorkItem: DispatchWorkItem?
    @State private var milestoneWorkItem: DispatchWorkItem?

    private let milestones = [3, 7, 14, 30, 60, 100]
    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            weekStrip
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.border.opacity(0.45), lineWidth: 1)
        )
        .id(languageManager.currentLanguage)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.08)) {
                appeared = true
            }
            scheduleDailyAchievementCheck()
            scheduleMilestoneCheck()
        }
        // Use Combine so we always react to goal completion (onChange single-arg vs iOS 17+ two-arg),
        // and so we still fire when the view was off-screen while completeSession ran.
        .onReceive(userDataManager.$dailyGoalCompleted.removeDuplicates()) { completed in
            if completed { scheduleDailyAchievementCheck() }
        }
        .onReceive(userDataManager.$currentStreak.removeDuplicates()) { _ in
            scheduleMilestoneCheck()
        }
        .onChange(of: practiceSheetPresented) { isPresented in
            if !isPresented {
                scheduleDailyAchievementCheck()
                scheduleMilestoneCheck()
            }
        }
        // Daily goal achieved popup
        .sheet(isPresented: $showDailyAchieve) {
            DailyAchievementSheet(
                streak: userDataManager.currentStreak,
                onDisplayed: {
                    UserDefaults.standard.set(true, forKey: dailyAchieveShownKey())
                }
            )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        // Milestone celebration sheet
        .sheet(item: $milestoneSheetItem) { item in
            MilestoneCelebrationSheet(
                milestone: item.id,
                onDisplayed: {
                    UserDefaults.standard.set(true, forKey: "milestone_celebrated_\(item.id)")
                }
            )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
    }

    // MARK: - Week strip

    private var weekStrip: some View {
        let days = currentWeekDays()
        return HStack(spacing: 0) {
            ForEach(days.indices, id: \.self) { i in
                DayCell(
                    day: days[i],
                    userDataManager: userDataManager,
                    animDelay: Double(i) * 0.05
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    // Sunday … Saturday of the current week
    private func currentWeekDays() -> [Date] {
        let today    = cal.startOfDay(for: Date())
        let weekday  = cal.component(.weekday, from: today) // 1=Sun
        let sunday   = cal.date(byAdding: .day, value: -(weekday - 1), to: today)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: sunday) }
    }

    // MARK: - Helpers

    private func dailyAchieveShownKey() -> String {
        "daily_achieve_shown_\(Int(cal.startOfDay(for: Date()).timeIntervalSince1970))"
    }

    /// Delays until the practice sheet is dismissed; stacking sheets under practice breaks on newer iOS (blank dark sheet).
    /// UserDefaults is set only when the sheet actually appears so a skipped attempt can retry after practice closes.
    private func scheduleDailyAchievementCheck() {
        guard userDataManager.dailyGoalCompleted else { return }
        let key = dailyAchieveShownKey()
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        dailyAchieveWorkItem?.cancel()
        let work = DispatchWorkItem {
            guard userDataManager.dailyGoalCompleted else { return }
            guard !UserDefaults.standard.bool(forKey: key) else { return }
            guard !practiceSheetPresented else { return }
            guard !showDailyAchieve else { return }
            showDailyAchieve = true
        }
        dailyAchieveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05, execute: work)
    }

    private func scheduleMilestoneCheck() {
        let s = userDataManager.currentStreak
        guard milestones.contains(s) else { return }
        let key = "milestone_celebrated_\(s)"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        milestoneWorkItem?.cancel()
        let work = DispatchWorkItem {
            let live = userDataManager.currentStreak
            guard milestones.contains(live) else { return }
            let k = "milestone_celebrated_\(live)"
            guard !UserDefaults.standard.bool(forKey: k) else { return }
            guard !practiceSheetPresented else { return }
            guard milestoneSheetItem == nil else { return }
            milestoneSheetItem = MilestoneSheetItem(id: live)
        }
        milestoneWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85, execute: work)
    }
}

// MARK: - Day cell

private struct DayCell: View {
    let day: Date
    @ObservedObject var userDataManager: UserDataManager
    @ObservedObject private var languageManager = LanguageManager.shared
    let animDelay: Double

    @State private var appeared = false

    private let cal = Calendar.current

    private var isToday:  Bool { cal.isDateInToday(day) }
    private var isFuture: Bool { day > cal.startOfDay(for: Date()) }

    private var dayName: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale(identifier: languageManager.currentLanguage)
        return f.string(from: day)
    }
    private var dayNumber: Int { cal.component(.day, from: day) }

    private enum DayStatus { case completed, partial, missed, future }

    private var status: DayStatus {
        if isFuture { return .future }
        if isToday  { return userDataManager.dailyGoalCompleted ? .completed : .partial }
        // Check history for past days
        if let stats = userDataManager.dailyHistory.first(where: {
            cal.isDate($0.date, inSameDayAs: day)
        }) {
            return stats.sessions >= userDataManager.dailyGoalSessions ? .completed : .missed
        }
        return .missed
    }

    private var progress: CGFloat {
        guard isToday, !userDataManager.dailyGoalCompleted else { return 0 }
        return CGFloat(userDataManager.todaySessions) / CGFloat(max(1, userDataManager.dailyGoalSessions))
    }

    var body: some View {
        VStack(spacing: 5) {
            // Day abbreviation
            Text(dayName)
                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? AppTheme.textPrimary : AppTheme.textMuted)

            // Circle
            ZStack {
                // Fill
                Circle()
                    .fill(fillColor)
                    .frame(width: 36, height: 36)

                // Border / progress arc
                switch status {
                case .completed:
                    Circle()
                        .stroke(completedBorderColor, lineWidth: 2)
                        .frame(width: 36, height: 36)

                case .partial:
                    // Background ring
                    Circle()
                        .stroke(AppTheme.textMuted.opacity(0.18), lineWidth: 2.5)
                        .frame(width: 36, height: 36)
                    // Progress arc
                    Circle()
                        .trim(from: 0, to: min(1, progress))
                        .stroke(
                            AppTheme.primary,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: progress)

                case .missed:
                    Circle()
                        .stroke(AppTheme.textMuted.opacity(0.20), lineWidth: 1.5)
                        .frame(width: 36, height: 36)

                case .future:
                    Circle()
                        .stroke(
                            style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                        )
                        .foregroundColor(AppTheme.textMuted.opacity(0.18))
                        .frame(width: 36, height: 36)
                }

                // Icon / number
                Group {
                    if status == .completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(completedTextColor)
                    } else {
                        Text("\(dayNumber)")
                            .font(.system(size: 13, weight: isToday ? .bold : .medium))
                            .foregroundColor(numberColor)
                    }
                }
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.68).delay(animDelay)) {
                appeared = true
            }
        }
    }

    // MARK: Colours

    private var fillColor: Color {
        switch status {
        case .completed: return AppTheme.primary
        case .partial:   return AppTheme.primary.opacity(0.08)
        case .missed:    return AppTheme.textMuted.opacity(0.06)
        case .future:    return Color.clear
        }
    }

    private var completedBorderColor: Color {
        AppTheme.primary
    }

    private var completedTextColor: Color {
        .white
    }

    private var numberColor: Color {
        switch status {
        case .completed: return .white
        case .partial:   return AppTheme.textPrimary
        case .missed:    return AppTheme.textMuted
        case .future:    return AppTheme.textMuted.opacity(0.4)
        }
    }
}

// MARK: - Daily Achievement Popup

struct DailyAchievementSheet: View {
    let streak: Int
    var onDisplayed: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var fireBounce = false

    private var motivationMessage: String {
        switch streak {
        case 0..<3:
            return NSLocalizedString("streak.achieve.message_early",  comment: "")
        case 3..<7:
            return NSLocalizedString("streak.achieve.message_growing", comment: "")
        case 7..<30:
            return NSLocalizedString("streak.achieve.message_strong", comment: "")
        default:
            return NSLocalizedString("streak.achieve.message_legend", comment: "")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Fire icon with bounce
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .scaleEffect(appeared ? 1.0 : 0.3)

                Text("🔥")
                    .font(.system(size: 60))
                    .scaleEffect(appeared ? 1.0 : 0.2)
                    .rotationEffect(.degrees(appeared ? 0 : -20))
                    .offset(y: fireBounce ? -6 : 0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: fireBounce)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.62), value: appeared)
            .padding(.bottom, 28)

            // Streak count
            VStack(spacing: 6) {
                Text(String(format: NSLocalizedString("streak.achieve.day_count", comment: "Day %d complete!"), streak))
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.textPrimary, AppTheme.accent],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .multilineTextAlignment(.center)

                Text(motivationMessage)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            Spacer()

            Button {
                HapticManager.shared.success()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Text(NSLocalizedString("streak.achieve.cta", comment: "Keep it up!"))
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(ActionCardButtonStyle())
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            onDisplayed?()
            withAnimation(.spring(response: 0.52, dampingFraction: 0.66)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { fireBounce = true }
            }
        }
    }
}

// MARK: - Milestone Celebration Sheet (unchanged)

struct MilestoneCelebrationSheet: View {
    let milestone: Int
    var onDisplayed: (() -> Void)?
    @State private var appeared = false
    @Environment(\.dismiss) private var dismiss

    private var icon: String {
        switch milestone {
        case ...3:  return "leaf.fill"
        case ...7:  return "bolt.fill"
        case ...14: return "flame.fill"
        case ...30: return "star.fill"
        case ...60: return "crown.fill"
        default:    return "trophy.fill"
        }
    }

    private var accent: Color {
        switch milestone {
        case ...3:  return AppTheme.primary
        case ...7:  return Color(red: 0.3, green: 0.55, blue: 1.0)
        case ...14: return Color.orange
        case ...30: return AppTheme.accent
        case ...60: return Color.purple
        default:    return Color(red: 1, green: 0.84, blue: 0)
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(accent)
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(appeared ? 1.0 : 0.4)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 8) {
                Text(NSLocalizedString("streak.milestone_reached", comment: "Milestone Reached!"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.4)

                Text(String(format: NSLocalizedString("streak.milestone_days", comment: "%d Days!"), milestone))
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [AppTheme.textPrimary, accent],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Text(milestoneCaption)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            Spacer()

            Button { dismiss() } label: {
                Text(NSLocalizedString("streak.milestone_cta", comment: "Keep going →"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [accent, AppTheme.primary],
                                                 startPoint: .leading, endPoint: .trailing))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
            .opacity(appeared ? 1 : 0)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            onDisplayed?()
            withAnimation(.spring(response: 0.52, dampingFraction: 0.68)) { appeared = true }
        }
    }

    private var milestoneCaption: String {
        switch milestone {
        case 3:   return NSLocalizedString("streak.caption_3",   comment: "")
        case 7:   return NSLocalizedString("streak.caption_7",   comment: "")
        case 14:  return NSLocalizedString("streak.caption_14",  comment: "")
        case 30:  return NSLocalizedString("streak.caption_30",  comment: "")
        case 60:  return NSLocalizedString("streak.caption_60",  comment: "")
        default:  return NSLocalizedString("streak.caption_100", comment: "")
        }
    }
}
