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
                        Text("Choose Apps to Lock")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .buttonStyle(SecondaryButtonStyle(isLarge: false))
                .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
                .overlay {
                    if showPermissionAlert {
                        CustomAlertView(
                            title: "Permission Required",
                            message: "Family Controls permission was denied. Please enable it in Settings → Screen Time → ScrollDeeds",
                            icon: "lock.shield.fill",
                            iconColor: AppTheme.primary,
                            isPresented: $showPermissionAlert,
                            primaryAction: {
                                showPermissionAlert = false
                            },
                            primaryActionTitle: "OK"
                        )
                    }
                }
            } else {
                Text("Requires iOS 16+")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
            #else
            Text("FamilyControls not available")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
            #endif
        }
        #if canImport(FamilyControls)
        .onChange(of: isPickerPresented) { _ in
            if !isPickerPresented {
                shieldManager.updateSelection(apps: selection.applications)
                // Apply shield immediately after selection
                if !shieldManager.selectedApplications.isEmpty {
                    shieldManager.applyShield()
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
            
            // Request authorization using completion handler (more reliable)
            AuthorizationCenter.shared.requestAuthorization { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        let newStatus = AuthorizationCenter.shared.authorizationStatus
                        debugPrint("✅ Authorization SUCCESS! Status: \(newStatus.rawValue)")
                        
                        if newStatus == .approved {
                            debugPrint("✅ Permission APPROVED! Opening picker...")
                            isPickerPresented = true
                        } else {
                            debugPrint("⚠️ Success but not approved. Status: \(newStatus.rawValue)")
                            showPermissionAlert = true
                        }
                        
                    case .failure(let error):
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


