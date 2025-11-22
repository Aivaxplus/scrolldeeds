//
//  SettingsView.swift
//  scrolldeeds
//
//  Settings page for appearance and preferences
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var localStorage: LocalStorageManager
    @AppStorage("userAppearance") private var userAppearance: Int = 0 // 0 = Dark, 1 = Light, 2 = System
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showQuickGuide: Bool = false
    @State private var showReminderSettings: Bool = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
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
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        VStack(spacing: 0) {
                            settingRow(
                                icon: "info.circle.fill",
                                title: "Version",
                                value: "1.0.0",
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
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(colorScheme(for: userAppearance))
        .fullScreenCover(isPresented: $showQuickGuide) {
            QuickGuideView(onComplete: {
                showQuickGuide = false
            })
        }
        .sheet(isPresented: $showReminderSettings) {
            ReminderSettingsView()
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

#Preview {
    NavigationView {
        SettingsView(localStorage: LocalStorageManager.shared)
    }
}

