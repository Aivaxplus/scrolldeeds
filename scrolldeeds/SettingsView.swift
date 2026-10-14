//
//  SettingsView.swift
//  scrolldeeds
//
//  Settings page for appearance and preferences
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var localStorage: LocalStorageManager
    @ObservedObject private var userDataManager = UserDataManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var appearanceManager = AppearanceManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showQuickGuide: Bool = false
    @State private var showDifficultySettings: Bool = false
    @State private var showStatistics: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var showCustomerCenter: Bool = false
    @State private var showLanguageSettings: Bool = false
    @State private var showInAppFeedback: Bool = false
    @ObservedObject private var languageManager = LanguageManager.shared

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

                ScrollView {
                VStack(spacing: 24) {
                    // Notifications Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("settings.notifications", comment: "Notifications"))
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("settings.push_notifications", comment: "Push Notifications"))
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textPrimary)

                                    if !notificationManager.notificationsEnabled {
                                        Text(NSLocalizedString("settings.notifications_off_hint", comment: "Notifications off hint"))
                                            .font(.system(size: 13))
                                            .foregroundColor(AppTheme.textMuted)
                                    } else if !notificationManager.isAuthorized {
                                        Text(NSLocalizedString("settings.notifications_permission_hint", comment: "Notifications permission hint"))
                                            .font(.system(size: 13))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                }

                                Spacer()

                                Toggle("", isOn: notificationsToggleBinding)
                                    .labelsHidden()
                                    .tint(AppTheme.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            if !notificationManager.isAuthorized && notificationManager.notificationsEnabled {
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
                                        
                                        Text(NSLocalizedString("settings.enable_in_settings", comment: "Enable in Settings"))
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
                        }
                        .background(AppTheme.card)
                        .cornerRadius(16)
                    }

                    // Statistics Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("tab.stats", comment: "Stats"))
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppTheme.textPrimary)

                        Button(action: {
                            HapticManager.shared.soft()
                            showStatistics = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("settings.statistics", comment: "Statistics"))
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textPrimary)

                                    Text(NSLocalizedString("settings.statistics.subtitle", comment: "Your full history"))
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

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

                    // Practice Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("settings.practice", comment: "Practice"))
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppTheme.textPrimary)

                        Button(action: {
                            showDifficultySettings = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("settings.difficulty_level", comment: "Difficulty Level"))
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textPrimary)

                                    Text(currentDifficultySummary())
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.textSecondary)
                                }

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

                    // Appearance Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("settings.appearance", comment: "Appearance"))
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppTheme.textPrimary)

                        VStack(spacing: 0) {
                            ForEach(Array(AppearanceMode.allCases.enumerated()), id: \.element) { index, mode in
                                if index > 0 {
                                    Divider().padding(.leading, 64)
                                }
                                Button(action: {
                                    HapticManager.shared.selection()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        appearanceManager.mode = mode
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: mode.icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(appearanceManager.mode == mode ? AppTheme.primary : AppTheme.textMuted)
                                            .frame(width: 32)

                                        Text(mode.label)
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.textPrimary)

                                        Spacer()

                                        if appearanceManager.mode == mode {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(AppTheme.primary)
                                        } else {
                                            Circle()
                                                .stroke(AppTheme.textMuted.opacity(0.3), lineWidth: 1.5)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .background(AppTheme.card)
                        .cornerRadius(16)
                    }

                    // Language Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("settings.language", comment: "Language"))
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Button(action: {
                            showLanguageSettings = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "globe")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("settings.app_language", comment: "App Language"))
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Text(currentLanguageName())
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text(currentLanguageFlag())
                                    .font(.system(size: 24))
                                
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
                    
                    InAppFeedbackCard(source: .settings, isPresented: $showInAppFeedback)

                    // Help Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("settings.help", comment: "Help"))
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Button(action: { showQuickGuide = true }) {
                            HStack(spacing: 16) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)
                                
                                Text(NSLocalizedString("settings.how_to_use", comment: "How to Use ScrollDeeds"))
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
                        Text(NSLocalizedString("settings.subscription", comment: "Subscription"))
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Button(action: {
                            showCustomerCenter = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)
                                
                                Text(NSLocalizedString("settings.manage_subscription", comment: "Manage Subscription"))
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
                        Text(NSLocalizedString("settings.share", comment: "Share"))
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Button(action: {
                            showShareSheet = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)
                                
                                Text(NSLocalizedString("settings.share_app", comment: "Share ScrollDeeds"))
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
                        Text(NSLocalizedString("settings.about", comment: "About"))
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        VStack(spacing: 0) {
                            settingRow(
                                icon: "info.circle.fill",
                                title: NSLocalizedString("settings.version", comment: "Version"),
                                value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—",
                                showDivider: true
                            )
                            
                            settingRow(
                                icon: "heart.fill",
                                title: NSLocalizedString("settings.made_for_muslims", comment: "Made for Muslims"),
                                value: "🌙",
                                showDivider: false
                            )
                        }
                        .background(AppTheme.card)
                        .cornerRadius(16)
                    }
                }
                .padding(20)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(appearanceManager.preferredColorScheme)
        .fullScreenCover(isPresented: $showQuickGuide) {
            QuickGuideView(onComplete: {
                showQuickGuide = false
            })
        }
        .sheet(isPresented: $showStatistics) {
            NavigationView {
                ProgressView(localStorage: localStorage)
            }
        }
        .sheet(isPresented: $showDifficultySettings) {
            DifficultySettingsView()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [
                NSLocalizedString("settings.share_text", comment: "Check out Nafsi - a mindful way to break scrolling habits with good deeds! 🌙"),
                URL(string: "https://apps.apple.com/app/id6754699333")!
            ])
        }
        .sheet(isPresented: $showCustomerCenter) {
            CustomerCenterView()
        }
        .sheet(isPresented: $showLanguageSettings) {
            LanguageSettingsView()
        }
        .sheet(isPresented: $showInAppFeedback) {
            InAppFeedbackSheet(source: .settings, isPresented: $showInAppFeedback)
        }
        .onAppear {
            PostHogManager.shared.screen(AnalyticsScreen.settings)
            notificationManager.checkAuthorizationStatus()
            NafsiWidgetSettings.shared.publish()
        }
    }

    private var notificationsToggleBinding: Binding<Bool> {
        Binding(
            get: { notificationManager.notificationsEnabled },
            set: { enabled in
                HapticManager.shared.selection()
                if enabled {
                    if notificationManager.isAuthorized {
                        notificationManager.setNotificationsEnabled(true)
                    } else {
                        notificationManager.requestPermission { granted in
                            notificationManager.setNotificationsEnabled(granted)
                        }
                    }
                } else {
                    notificationManager.setNotificationsEnabled(false)
                }
            }
        )
    }

    private func currentDifficultySummary() -> String {
        let level = userDataManager.onboardingDifficultyLevel
        let title: String
        switch level {
        case 0: title = NSLocalizedString("questionnaire.difficulty.option.easy.title", comment: "")
        case 2: title = NSLocalizedString("questionnaire.difficulty.option.hard.title", comment: "")
        default: title = NSLocalizedString("questionnaire.difficulty.option.medium.title", comment: "")
        }
        let minutes = UserDataManager.onboardingUnlockMinutes(forDifficultyLevel: level)
        return String(format: NSLocalizedString("settings.difficulty.summary", comment: "Difficulty summary"), title, minutes)
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
    
    private func currentLanguageName() -> String {
        let language = LanguageManager.supportedLanguages.first { $0.code == languageManager.currentLanguage }
        return language?.nativeName ?? "English"
    }
    
    private func currentLanguageFlag() -> String {
        let language = LanguageManager.supportedLanguages.first { $0.code == languageManager.currentLanguage }
        return language?.flag ?? "🇬🇧"
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
        SettingsView(localStorage: LocalStorageManager.shared)
    }
}


