//
//  ProgressView.swift
//  scrolldeeds
//
//  Modern, clean progress view with dhikr tracking and line chart
//

import SwiftUI
import Charts

struct ProgressView: View {
    @ObservedObject var userDataManager: UserDataManager
    @ObservedObject var localStorage: LocalStorageManager
    @Environment(\.dismiss) private var dismiss
    
    // Computed properties for dhikr counts
    private var totalDhikr: Int {
        userDataManager.totalSessions * 3
    }
    
    private var todayDhikr: Int {
        userDataManager.todaySessions * 3
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
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
        .navigationTitle("Your Progress")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if userDataManager.totalSessions == 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Your Journey")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Complete your first dhikr session")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textSecondary)
                }
            } else {
                Text("Track your mindful moments")
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
                Text("No Data Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Complete your first dhikr session to start tracking your progress")
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
                Text("Today")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Today's Dhikr Count
                todayStatCard(
                    icon: "hands.sparkles.fill",
                    value: "\(todayDhikr)",
                    label: "Dhikr Today",
                    subtitle: "\(userDataManager.todaySessions) sessions",
                    color: AppTheme.primary
                )
                
                // Today's Time
                todayStatCard(
                    icon: "clock.fill",
                    value: "\(userDataManager.todayMinutes)",
                    label: "Minutes Unlocked",
                    subtitle: "Today",
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
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
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
                Text("Daily Dhikr Progress")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            
            if #available(iOS 16.0, *) {
                let chartData = getLast7DaysData()
                let maxValue = max(1, chartData.map { $0.dhikrCount }.max() ?? 1)
                let yAxisStep = max(1, (maxValue + 2) / 4) // Dynamic step based on max value
                
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
                            let calendar = Calendar.current
                            let weekday = calendar.component(.weekday, from: date)
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
                Text("Shows your daily dhikr count over the last 7 days")
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
                Text("Overall Stats")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    statCard(
                        icon: "hands.sparkles.fill",
                        value: "\(totalDhikr)",
                        label: "Total Dhikr",
                        color: AppTheme.primary
                    )
                    statCard(
                        icon: "checkmark.circle.fill",
                        value: "\(userDataManager.totalSessions)",
                        label: "Total Sessions",
                        color: AppTheme.success
                    )
                }
                
                HStack(spacing: 12) {
                    statCard(
                        icon: "clock.fill",
                        value: "\(userDataManager.totalMinutes / 60)h",
                        label: "Total Time",
                        color: AppTheme.accent
                    )
                    statCard(
                        icon: "chart.line.uptrend.xyaxis.circle.fill",
                        value: "\(getAverageSessions())",
                        label: "Avg/Day",
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
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
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
                Text("\(userDataManager.currentStreak) Day Streak!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Keep it going! Don't break the chain.")
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
    
    private func getAverageSessions() -> Int {
        let days = max(1, userDataManager.currentStreak)
        return userDataManager.totalSessions / days
    }
    
    private func getLast7DaysData() -> [DayData] {
        let calendar = Calendar.current
        let last7Days = userDataManager.getLast7Days()
        
        // Map to day labels correctly - use short day names
        return last7Days.map { stats in
            let weekday = calendar.component(.weekday, from: stats.date)
            // Sunday = 1, Monday = 2, ..., Saturday = 7
            let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let dayLabel = dayLabels[weekday - 1]
            // Each session = 3 dhikr
            let dhikrCount = stats.sessions * 3
            return DayData(day: dayLabel, date: stats.date, dhikrCount: dhikrCount)
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
        ProgressView(userDataManager: UserDataManager(), localStorage: LocalStorageManager.shared)
    }
}
