//
//  LockedAppsToolPage.swift
//  scrolldeeds
//
//  Dashboard tool: choose which apps stay behind the shield.
//

import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif

struct LockedAppsToolPage: View {
    @ObservedObject var shieldManager: ShieldManager
    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                SDPageBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(NSLocalizedString("nafsi.tools.locked_apps.body", comment: ""))
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        SelectionView(shieldManager: shieldManager)
                            .id(languageManager.currentLanguage)

                        #if canImport(FamilyControls)
                        if #available(iOS 16.0, *), shieldManager.hasShieldTargets {
                            HStack(spacing: 8) {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textMuted)
                                Text(NSLocalizedString("dashboard.apps_hidden", comment: "App icons hidden for privacy"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.textMuted)
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppTheme.muted.opacity(0.7))
                            )
                        }
                        #endif
                    }
                    .padding(20)
                }
            }
            .navigationTitle(NSLocalizedString("nafsi.tools.locked_apps", comment: "Locked apps"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SDDismissButton {
                        HapticManager.shared.soft()
                        dismiss()
                    }
                }
            }
        }
    }
}
