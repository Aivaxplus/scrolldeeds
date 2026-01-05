//
//  SettingsView.swift
//  scrolldeeds
//
//  Settings page for appearance and preferences
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var localStorage: LocalStorageManager
    @ObservedObject var userDataManager: UserDataManager
    @AppStorage("userAppearance") private var userAppearance: Int = 0 // 0 = Dark, 1 = Light, 2 = System
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showQuickGuide: Bool = false
    @State private var showReminderSettings: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var showDifficultyInfo: DifficultyLevel? = nil
    @State private var showCustomerCenter: Bool = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header with Close Button
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.shared.soft()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)
                
                ScrollView {
                VStack(spacing: 24) {
                    // Notifications Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notifications")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)
                                
                                Text("Push Notifications")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: notificationManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(notificationManager.isAuthorized ? .green : .red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            
                            if !notificationManager.isAuthorized {
                                Divider()
                                    .padding(.leading, 64)
                                
                                Button(action: {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "gear")
                                            .font(.system(size: 20))
                                            .foregroundColor(AppTheme.primary)
                                            .frame(width: 32)
                                        
                                        Text("Enable in Settings")
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            }
                            
                            Divider()
                                .padding(.leading, 64)
                            
                            Button(action: {
                                showReminderSettings = true
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppTheme.primary)
                                        .frame(width: 32)
                                    
                                    Text("Daily Reminders")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.textMuted)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                        }
                        .background(AppTheme.card)
                        .cornerRadius(16)
                    }
                    
                    // Appearance Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appearance")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        VStack(spacing: 0) {
                            ForEach(0..<3) { index in
                                Button(action: {
                                    HapticManager.shared.appearanceChanged()
                                    withAnimation {
                                        userAppearance = index
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: appearanceIcon(for: index))
                                            .font(.system(size: 20))
                                            .foregroundColor(AppTheme.primary)
                                            .frame(width: 32)
                                        
                                        Text(appearanceTitle(for: index))
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.textPrimary)
                                        
                                        Spacer()
                                        
                                        if userAppearance == index {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(AppTheme.primary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                                
                                if index < 2 {
                                    Divider()
                                        .padding(.leading, 64)
                                }
                            }
                        }
                        .background(AppTheme.card)
                        .cornerRadius(16)
                    }
                    
                    // Difficulty Level Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Difficulty Level")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        // 2x2 Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(DifficultyLevel.allCases, id: \.self) { level in
                                let isSelected = userDataManager.difficultyLevel == level
                                Button(action: {
                                    HapticManager.shared.selection()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        userDataManager.setDifficultyLevel(level)
                                    }
                                    showDifficultyInfo = level
                                }) {
                                    VStack(spacing: 10) {
                                        // Icon
                                        ZStack {
                                            Circle()
                                                .fill(level.color.opacity(isSelected ? 0.2 : 0.1))
                                                .frame(width: 48, height: 48)
                                            Image(systemName: level.icon)
                                                .font(.system(size: 22, weight: .semibold))
                                                .foregroundColor(level.color)
                                        }
                                        
                                        // Name
                                        Text(level.displayName)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                                        
                                        // Duration
                                        Text(level.displayDuration)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(level.color)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(level.color.opacity(0.1))
                                            .cornerRadius(6)
                                        
                                        // Selection indicator
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(level.color)
                                        } else {
                                            Circle()
                                                .stroke(AppTheme.textMuted.opacity(0.3), lineWidth: 1.5)
                                                .frame(width: 16, height: 16)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(AppTheme.card)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(isSelected ? level.color : AppTheme.muted.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                                            )
                                    )
                                    .shadow(color: isSelected ? level.color.opacity(0.15) : Color.clear, radius: 8, y: 4)
                                    .scaleEffect(isSelected ? 1.02 : 1.0)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
                            }
                        }
                    }
                    
                    // Help Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Help")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Button(action: { showQuickGuide = true }) {
                            HStack(spacing: 16) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)
                                
                                Text("How to Use ScrollDeeds")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .background(AppTheme.card)
                        .cornerRadius(16)
                    }
                    
                    // Subscription Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Subscription")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Button(action: {
                            showCustomerCenter = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)
                                
                                Text("Manage Subscription")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .background(AppTheme.card)
                        .cornerRadius(16)
                    }
                    
                    // Share Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Share")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Button(action: {
                            showShareSheet = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)
                                
                                Text("Share ScrollDeeds")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .background(AppTheme.card)
                        .cornerRadius(16)
                    }
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        VStack(spacing: 0) {
                            settingRow(
                                icon: "info.circle.fill",
                                title: "Version",
                                value: "1.0.1",
                                showDivider: true
                            )
                            
                            settingRow(
                                icon: "heart.fill",
                                title: "Made for Muslims",
                                value: "🌙",
                                showDivider: false
                            )
                        }
                        .background(AppTheme.card)
                        .cornerRadius(16)
                    }
                    
                    // Actions Section
                    VStack(spacing: 12) {
                        #if DEBUG
                        Button(action: {
                            HapticManager.shared.soft()
                            // Reset all local data
                            localStorage.resetOnboarding()
                            UserDataManager().resetAllData()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 18))
                                Text("Reset App (Debug)")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.error.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.card)
                            .cornerRadius(16)
                        }
                        #endif
                    }
                }
                .padding(20)
                }
            }
        }
        .preferredColorScheme(colorScheme(for: userAppearance))
        .fullScreenCover(isPresented: $showQuickGuide) {
            QuickGuideView(onComplete: {
                showQuickGuide = false
            })
        }
        .sheet(isPresented: $showReminderSettings) {
            ReminderSettingsView()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [
                "Check out ScrollDeeds - a mindful way to break scrolling habits with dhikr! 🌙",
                URL(string: "https://apps.apple.com/app/id6754699333")!
            ])
        }
        .sheet(item: $showDifficultyInfo) { level in
            DifficultyLevelInfoView(level: level) {
                showDifficultyInfo = nil
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showCustomerCenter) {
            CustomerCenterView()
        }
    }
    
    private func settingRow(icon: String, title: String, value: String, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 32)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            if showDivider {
                Divider()
                    .padding(.leading, 64)
            }
        }
    }
    
    private func appearanceIcon(for index: Int) -> String {
        switch index {
        case 0: return "moon.fill"
        case 1: return "sun.max.fill"
        case 2: return "circle.lefthalf.filled"
        default: return "moon.fill"
        }
    }
    
    private func appearanceTitle(for index: Int) -> String {
        switch index {
        case 0: return "Dark Mode"
        case 1: return "Light Mode"
        case 2: return "System Default"
        default: return "Dark Mode"
        }
    }
    
    private func colorScheme(for index: Int) -> ColorScheme? {
        switch index {
        case 0: return .dark
        case 1: return .light
        case 2: return nil // System default
        default: return .dark
        }
    }
    
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = controller.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        SettingsView(localStorage: LocalStorageManager.shared, userDataManager: UserDataManager())
    }
}


