//
//  ProgressView.swift
//  scrolldeeds
//
//  Modern, clean progress view with dhikr tracking and line chart
//

import SwiftUI
import Charts

struct ProgressView: View {
    @ObservedObject private var userDataManager = UserDataManager.shared
    @ObservedObject var localStorage: LocalStorageManager
    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // 1 task = 1 good deed (no multiplier)
    private var totalGoodDeeds: Int {
        userDataManager.totalSessions
    }
    
    private var todayGoodDeeds: Int {
        userDataManager.todaySessions
    }
    
    var body: some View {
        ZStack {
            SDPageBackground()
            
            VStack(spacing: 0) {
                SDBrandHeader {
                    SDDismissButton(action: {
                        HapticManager.shared.soft()
                        dismiss()
                    })
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header - same style as PracticeSessionView
                        HStack {
                            headerSection
                            Spacer()
                        }
                        .padding(.horizontal, 0)
                    
                    // Show "no data yet" message if user hasn't done any sessions
                    if userDataManager.totalSessions == 0 {
                        noDataYetCard
                    } else {
                        // Today's Stats - Large Cards
                        todayStatsSection
                        
                        // Weekly Chart
                        weeklyChartCard
                        
                        // Overall Stats Grid
                        overallStatsGrid
                        
                        // Streak Card
                        streakCard
                    }
                }
                .padding(20)
                }
            }
        }
        .id(languageManager.currentLanguage)
        .toolbar(.hidden, for: .navigationBar)
        .trackScreen(AnalyticsScreen.stats)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if userDataManager.totalSessions == 0 {
                Text(NSLocalizedString("progress.start_journey", comment: "Start Your Journey"))
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppTheme.textPrimary)
                Text(NSLocalizedString("progress.first_session", comment: "Complete your first dhikr session"))
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
            } else {
                Text(NSLocalizedString("progress.your_progress", comment: "Your Progress"))
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppTheme.textPrimary)
                Text(NSLocalizedString("progress.growing_practice", comment: "See how your mindful practice is growing"))
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
    
    // MARK: - No Data Card
    
    private var noDataYetCard: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.primary)
            }
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("progress.no_data", comment: "No Data Yet"))
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppTheme.textPrimary)
                Text(NSLocalizedString("progress.no_data_message", comment: "Complete your first dhikr session to start tracking your progress"))
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(AppTheme.card)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.06), radius: 20, y: 8)
    }
    
    // MARK: - Today's Stats Section
    
    private var todayStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(NSLocalizedString("progress.today", comment: "Today"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Today's good deeds
                todayStatCard(
                    icon: "hands.sparkles.fill",
                    value: "\(todayGoodDeeds)",
                    label: NSLocalizedString("progress.good_deeds_today", comment: "Good Deeds Today"),
                    subtitle: String(format: NSLocalizedString("progress.deeds_count", comment: "%d good deed(s)"), userDataManager.todaySessions),
                    color: AppTheme.primary
                )
                
                // Today's Time
                todayStatCard(
                    icon: "clock.fill",
                    value: formatDuration(seconds: userDataManager.todayMinutes * 60),
                    label: NSLocalizedString("progress.minutes_unlocked", comment: "Minutes Unlocked"),
                    subtitle: NSLocalizedString("progress.today", comment: "Today"),
                    color: AppTheme.accent
                )
            }
        }
    }
    
    private func todayStatCard(icon: String, value: String, label: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppTheme.card)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 12, y: 4)
    }
    
    // MARK: - Weekly Chart
    
    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.primary)
                Text(NSLocalizedString("progress.daily_good_deeds", comment: "Daily Good Deeds"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            
            if #available(iOS 16.0, *) {
                let chartData = getLast7DaysData()
                let maxValue = max(1, chartData.map { $0.dhikrCount }.max() ?? 1)
                
                Chart(chartData, id: \.id) { item in
                    LineMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Dhikr", item.dhikrCount)
                    )
                    .foregroundStyle(AppTheme.primary)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Dhikr", item.dhikrCount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.primary.opacity(0.3), AppTheme.primary.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Dhikr", item.dhikrCount)
                    )
                    .foregroundStyle(AppTheme.primary)
                    .symbolSize(60)
                }
                .frame(height: 200)
                .chartYScale(domain: 0...(maxValue + 1))
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.textSecondary)
                            .font(.system(size: 11, weight: .medium))
                        AxisGridLine()
                            .foregroundStyle(AppTheme.muted.opacity(0.2))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            let weekday = Calendar.current.component(.weekday, from: date)
                            let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
                            let dayLabel = dayLabels[weekday - 1]
                            AxisValueLabel {
                                Text(dayLabel)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                    }
                }
            } else {
                // Fallback for iOS 15
                simplifiedLineChart
            }
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.primary.opacity(0.6))
                Text(NSLocalizedString("progress.chart_info", comment: "Shows your daily dhikr count over the last 7 days"))
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(20)
        .background(AppTheme.card)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 15, y: 8)
    }
    
    @available(iOS 15.0, *)
    private var simplifiedLineChart: some View {
        GeometryReader { geometry in
            let data = getLast7DaysData()
            let maxDhikr = max(1, data.map { $0.dhikrCount }.max() ?? 1)
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Background grid
                Path { path in
                    for i in 0...4 {
                        let y = height * CGFloat(i) / 4
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(AppTheme.muted.opacity(0.2), lineWidth: 1)
                
                // Line chart
                Path { path in
                    let spacing = width / CGFloat(max(data.count - 1, 1))
                    for (index, item) in data.enumerated() {
                        let x = spacing * CGFloat(index)
                        let y = height - (height * CGFloat(item.dhikrCount) / CGFloat(maxDhikr))
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                // Points
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    let spacing = width / CGFloat(max(data.count - 1, 1))
                    let x = spacing * CGFloat(index)
                    let y = height - (height * CGFloat(item.dhikrCount) / CGFloat(maxDhikr))
                    
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
                
                // Day labels
                VStack {
                    Spacer()
                    HStack {
                        ForEach(data) { item in
                            Text(item.day)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                            if item.id != data.last?.id {
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .frame(height: 200)
    }
    
    // MARK: - Overall Stats Grid
    
    private var overallStatsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("progress.overall_stats", comment: "Overall Stats"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    statCard(
                        icon: "hands.sparkles.fill",
                        value: "\(totalGoodDeeds)",
                        label: NSLocalizedString("progress.total_good_deeds", comment: "Total Good Deeds"),
                        color: AppTheme.primary
                    )
                    statCard(
                        icon: "checkmark.circle.fill",
                        value: "\(userDataManager.totalSessions)",
                        label: NSLocalizedString("progress.total_sessions", comment: "Total Sessions"),
                        color: AppTheme.success
                    )
                }
                
                HStack(spacing: 12) {
                    statCard(
                        icon: "clock.fill",
                        value: formatDuration(seconds: userDataManager.totalMinutes * 60),
                        label: NSLocalizedString("progress.total_time", comment: "Total Time"),
                        color: AppTheme.accent
                    )
                    statCard(
                        icon: "chart.line.uptrend.xyaxis.circle.fill",
                        value: "\(getAverageSessions())",
                        label: NSLocalizedString("progress.avg_per_day", comment: "Avg/Day"),
                        color: AppTheme.primary
                    )
                }
            }
        }
    }
    
    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(AppTheme.card)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
    }
    
    // MARK: - Streak Card
    
    private var streakCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppTheme.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: NSLocalizedString("progress.streak", comment: "%d Day Streak!"), userDataManager.currentStreak))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(NSLocalizedString("progress.streak_message", comment: "Keep it going! Don't break the chain."))
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [AppTheme.accent.opacity(0.1), AppTheme.accent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Functions

    /// Formats duration in seconds as "Xh Xm" / "Xu Xm" etc. when >= 60 min, else "Xm Ys" or "Xs". Uses same locale keys as dashboard.
    private func formatDuration(seconds: Int) -> String {
        let s = max(0, seconds)
        if s >= 3600 {
            return String(format: NSLocalizedString("dashboard.time_format_hours", comment: "%dh %dm"), s / 3600, (s % 3600) / 60)
        } else if s >= 60 {
            return String(format: NSLocalizedString("dashboard.time_format", comment: "%dm %ds"), s / 60, s % 60)
        } else {
            return String(format: NSLocalizedString("dashboard.time_format_seconds", comment: "%ds"), s)
        }
    }

    private func getAverageSessions() -> Int {
        let practiced = userDataManager.dailyHistory.filter { $0.sessions > 0 }
        let days = max(1, practiced.count)
        let sessions = practiced.reduce(0) { $0 + $1.sessions }
        return sessions / days
    }
    
    private func getLast7DaysData() -> [DayData] {
        let last7Days = userDataManager.getLast7Days()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage)
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        
        // Map to day labels correctly - use short day names
        return last7Days.map { stats in
            let dayLabel = formatter.string(from: stats.date)
            // 1 session = 1 good deed
            let goodDeedCount = stats.sessions
            return DayData(day: dayLabel, date: stats.date, dhikrCount: goodDeedCount)
        }
    }
}

struct DayData: Identifiable {
    let id = UUID()
    let day: String
    let date: Date
    let dhikrCount: Int
}

#Preview {
    NavigationView {
        ProgressView(localStorage: LocalStorageManager.shared)
    }
}
