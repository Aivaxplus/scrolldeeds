//
//  SelectionView.swift
//  scrolldeeds
//
//  Lets the user pick apps/categories to shield.
//

import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

#if canImport(ManagedSettings)
import ManagedSettings
#endif

struct SelectionView: View {
    @ObservedObject var shieldManager: ShieldManager
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var isPickerPresented: Bool = false
    @State private var showPermissionAlert: Bool = false
    #if canImport(FamilyControls)
    @State private var selection = FamilyActivitySelection()
    #endif

    var body: some View {
        VStack(spacing: 12) {
            #if canImport(FamilyControls)
            if #available(iOS 16.0, *) {
                Button(action: { 
                    // Request permission first
                    requestFamilyControlsPermission()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text(NSLocalizedString("selection.choose_apps", comment: "Choose Apps to Lock"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .buttonStyle(SecondaryButtonStyle(isLarge: false))
                .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
                // Presented full-screen (not as a small `.overlay` on this button) so the
                // alert always renders correctly above the whole dashboard instead of
                // getting sandwiched between the surrounding cards.
                .fullScreenCover(isPresented: $showPermissionAlert) {
                    CustomAlertView(
                        title: NSLocalizedString("selection.permission_title", comment: "Permission Required"),
                        message: NSLocalizedString("selection.permission_message", comment: "Family Controls permission was denied. Please enable it in Settings → Screen Time → ScrollDeeds"),
                        icon: "lock.shield.fill",
                        iconColor: AppTheme.primary,
                        isPresented: $showPermissionAlert,
                        primaryAction: {
                            showPermissionAlert = false
                        },
                        primaryActionTitle: NSLocalizedString("common.ok", comment: "OK"),
                        dimBackground: false
                    )
                }
            } else {
                Text(NSLocalizedString("selection.requires_ios16", comment: "Requires iOS 16+"))
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
            #else
            Text(NSLocalizedString("selection.not_available", comment: "FamilyControls not available"))
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
            #endif
        }
        .id(languageManager.currentLanguage)
        #if canImport(FamilyControls)
        .onAppear {
            #if canImport(FamilyControls)
            if #available(iOS 16.0, *) {
                selection = shieldManager.currentFamilySelection()
            }
            #endif
        }
        .onChange(of: isPickerPresented) { _ in
            if !isPickerPresented {
                if #available(iOS 16.0, *) {
                    shieldManager.commitPickerSelection(selection)
                    if shieldManager.hasShieldTargets {
                        shieldManager.applyShield()
                    }
                }
            }
        }
        #endif
    }
    
    // MARK: - Functions
    
    private func requestFamilyControlsPermission() {
        #if canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            debugPrint("🔐 Requesting Family Controls permission...")
            
            // Check current authorization status
            let currentStatus = AuthorizationCenter.shared.authorizationStatus
            debugPrint("🔐 Current authorization status: \(currentStatus.rawValue)")
            
            // If already approved, just open picker
            if currentStatus == .approved {
                debugPrint("✅ Already approved! Opening picker...")
                isPickerPresented = true
                return
            }
            
            // Request authorization using async/await (modern API)
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    await MainActor.run {
                        let newStatus = AuthorizationCenter.shared.authorizationStatus
                        debugPrint("✅ Authorization SUCCESS! Status: \(newStatus.rawValue)")
                        
                        if newStatus == .approved {
                            debugPrint("✅ Permission APPROVED! Opening picker...")
                            isPickerPresented = true
                        } else {
                            debugPrint("⚠️ Success but not approved. Status: \(newStatus.rawValue)")
                            showPermissionAlert = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        debugPrint("❌ Authorization FAILED: \(error.localizedDescription)")
                        showPermissionAlert = true
                    }
                }
            }
        }
        #endif
    }
}

#Preview {
    SelectionView(shieldManager: ShieldManager.shared)
}


