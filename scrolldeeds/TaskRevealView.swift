//
//  TaskRevealView.swift
//  scrolldeeds
//
//  Calm but visually rich selection screen.
//  Titles flip upward like a departures board, slowing down before landing.
//

import SwiftUI

struct TaskRevealView: View {
    let selectedTask: GoodDeedTask
    let onRevealComplete: () -> Void

    @ObservedObject private var languageManager = LanguageManager.shared
    private var allTasks: [GoodDeedTask] { GoodDeedTaskManager.shared.allTasks }

    @State private var displayTitle  = ""
    @State private var titleOpacity: Double = 0

    @State private var appeared      = false
    @State private var isLanded      = false
    @State private var fillProgress: Double = 0   // 0→1 progress line
    @State private var badgeScale: CGFloat  = 0.7
    @State private var badgeOpacity: Double = 0
    @State private var cardGlow: Double     = 0

    // Total animation duration (matches buildSchedule last delay + padding)
    private let totalDuration: Double = 3.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                AppTheme.background
                LinearGradient(
                    colors: [AppTheme.primary.opacity(0.0), AppTheme.primary.opacity(0.07)],
                    startPoint: .top, endPoint: .bottom
                )

                VStack(spacing: 0) {

                    stepDots
                        .padding(.top, 16)

                    // ── Header ────────────────────────────────────────
                    VStack(alignment: .center, spacing: 4) {
                        Text(NSLocalizedString("task.reveal.selecting_line1", comment: ""))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(NSLocalizedString("task.reveal.selecting_line2", comment: ""))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.primaryLight, AppTheme.primary],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                    .padding(.horizontal, 36)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8), value: appeared)

                    Spacer()

                    // ── Cycling card ──────────────────────────────────
                    VStack(spacing: 16) {

                        // Difficulty badge — only visible after landing
                        DeedCoinBadge(coins: selectedTask.coins, size: 13)
                        .foregroundColor(selectedTask.difficulty.accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedTask.difficulty.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(selectedTask.difficulty.accentColor.opacity(0.25), lineWidth: 1))
                        .scaleEffect(badgeScale)
                        .opacity(badgeOpacity)

                        // Title display area — no fixed height so long titles always fit
                        ZStack {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(AppTheme.card)
                                .shadow(
                                    color: isLanded
                                        ? selectedTask.difficulty.accentColor.opacity(0.22)
                                        : Color.black.opacity(0.07),
                                    radius: isLanded ? 28 : 16,
                                    y: 8
                                )
                                .animation(.easeInOut(duration: 0.5), value: isLanded)

                            RoundedRectangle(cornerRadius: 22)
                                .stroke(
                                    isLanded
                                        ? selectedTask.difficulty.accentColor.opacity(0.4)
                                        : AppTheme.textMuted.opacity(0.08),
                                    lineWidth: isLanded ? 1.5 : 1
                                )
                                .animation(.easeInOut(duration: 0.5), value: isLanded)

                            Text(displayTitle)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 36)
                                .opacity(titleOpacity)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 120)
                        .padding(.horizontal, 28)
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.15), value: appeared)

                    // ── Progress bar ──────────────────────────────────
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.textMuted.opacity(0.12))
                            .frame(height: 3)
                        GeometryReader { bar in
                            Capsule()
                                .fill(
                                    isLanded
                                        ? LinearGradient(colors: [selectedTask.difficulty.accentColor, selectedTask.difficulty.accentColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: bar.size.width * fillProgress)
                                .animation(.linear(duration: 0.05), value: fillProgress)
                        }
                        .frame(height: 3)
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 28)
                    .padding(.top, 14)
                    .opacity(appeared ? 1 : 0)

                    Spacer()

                    // ── Decorative footer ─────────────────────────────
                    Text("﷽")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.textMuted.opacity(0.35))
                        .padding(.bottom, 56)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { appeared = true }
            // Kick off the progress bar over the full animation window
            withAnimation(.linear(duration: totalDuration - 0.15)) { fillProgress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { startCycling() }
        }
    }

    // MARK: - Step dots (consistent with practice flow)

    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(1...2, id: \.self) { i in
                Capsule()
                    .fill(i <= 2 ? AppTheme.primary : AppTheme.textMuted.opacity(0.22))
                    .frame(width: i == 2 ? 26 : 8, height: 6)
            }
        }
    }

    // MARK: - Localized title (user's language)

    private func localizedTitle(for task: GoodDeedTask) -> String {
        NSLocalizedString("task.\(task.id).title", value: task.title, comment: "")
    }

    // MARK: - Animation engine

    private func startCycling() {
        let others = allTasks.filter { $0.id != selectedTask.id }
        let toCycle = others.isEmpty ? allTasks : others
        let shuffled = toCycle.shuffled()
        let schedule = buildSchedule()

        for (i, delay) in schedule.enumerated() {
            let task = shuffled[i % shuffled.count]
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                flipTo(localizedTitle(for: task))
            }
        }

        // Land on selected task (in user's language)
        let landDelay = (schedule.last ?? 2.5) + 0.28
        DispatchQueue.main.asyncAfter(deadline: .now() + landDelay) {
            landOn(localizedTitle(for: selectedTask))
        }

        // Callback
        DispatchQueue.main.asyncAfter(deadline: .now() + landDelay + 1.2) {
            onRevealComplete()
        }
    }

    /// Time points at which each title change fires (accelerating then decelerating)
    private func buildSchedule() -> [Double] {
        var delays: [Double] = []
        var t: Double = 0
        while t < 1.5  { delays.append(t); t += 0.100 }  // fast
        while t < 2.2  { delays.append(t); t += 0.190 }  // medium
        while t < 2.65 { delays.append(t); t += 0.340 }  // slow
        return delays
    }

    /// Cross-fade to a new title — no offset so no clipping of long text
    private func flipTo(_ title: String) {
        HapticManager.shared.taskCycling()
        withAnimation(.easeOut(duration: 0.07)) { titleOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            displayTitle = title
            withAnimation(.easeIn(duration: 0.09)) { titleOpacity = 1 }
        }
    }

    /// Final landing: slower fade-in + reveal difficulty badge
    private func landOn(_ title: String) {
        withAnimation(.easeOut(duration: 0.14)) { titleOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            displayTitle = title
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                titleOpacity = 1
                isLanded     = true
            }
            HapticManager.shared.taskLanded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                    badgeScale   = 1.0
                    badgeOpacity = 1.0
                }
            }
        }
    }
}
