//
//  ForceAppSelectionView.swift
//  scrolldeeds
//
//  Forces premium users to select apps before using the app
//

import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct ForceAppSelectionView: View {
    @ObservedObject var shieldManager: ShieldManager
    /// Optional override for the continue CTA (defaults to “Start Using ScrollDeeds”).
    var continueButtonTitle: String? = nil
    let onComplete: () -> Void
    
    #if canImport(FamilyControls)
    @State private var appSelection = FamilyActivitySelection()
    #endif
    @State private var isAppPickerPresented = false
    @State private var showPermissionAlert = false
    @State private var animateContent = false
    
    private var resolvedContinueTitle: String {
        continueButtonTitle
            ?? NSLocalizedString("force_app_selection.start_using", comment: "Start Using ScrollDeeds")
    }
    
    var body: some View {
        ZStack {
            // Background
            SDPageBackground()
            
            // Subtle glow
            RadialGradient(
                colors: [AppTheme.primary.opacity(0.08), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main content
                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.12))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "lock.iphone")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.8)
                    
                    // Title & Description
                    VStack(spacing: 16) {
                        Text(NSLocalizedString("force_app_selection.title", comment: "One More Step"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text(NSLocalizedString("force_app_selection.subtitle", comment: "Select the apps you want to lock.\nThis is required to use ScrollDeeds."))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .opacity(animateContent ? 1 : 0)
                    
                    // Info card
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.primary)
                            
                            Text(NSLocalizedString("force_app_selection.why_title", comment: "Why do I need to select apps?"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Spacer()
                        }
                        
                        Text(NSLocalizedString("force_app_selection.why_message", comment: "ScrollDeeds works by locking your distracting apps. When you want to use them, you'll need to complete dhikr first. This helps you build mindful habits."))
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.cardSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .opacity(animateContent ? 1 : 0)
                    
                    // Selected apps indicator
                    #if canImport(FamilyControls)
                    if shieldManager.hasShieldTargets {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.success)
                                .font(.system(size: 22))
                            Text(String(format: NSLocalizedString("force_app_selection.apps_selected", comment: "%d apps selected"), shieldManager.pickerSelectionCount))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppTheme.success.opacity(0.15))
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    #endif
                    
                    // Select Apps Button
                    #if canImport(FamilyControls)
                    if #available(iOS 16.0, *) {
                        Button(action: {
                            HapticManager.shared.medium()
                            requestFamilyControlsPermission()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: !shieldManager.hasShieldTargets ? "plus.app.fill" : "arrow.triangle.2.circlepath")
                                    .font(.system(size: 18, weight: .bold))
                                Text(!shieldManager.hasShieldTargets ? NSLocalizedString("force_app_selection.choose_apps", comment: "Choose Apps to Lock") : NSLocalizedString("force_app_selection.change_selection", comment: "Change Selection"))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .familyActivityPicker(isPresented: $isAppPickerPresented, selection: $appSelection)
                        .onChange(of: isAppPickerPresented) { isPresented in
                            if !isPresented {
                                if #available(iOS 16.0, *) {
                                    shieldManager.commitPickerSelection(appSelection)
                                    if shieldManager.hasShieldTargets {
                                        shieldManager.applyShield()
                                    }
                                }
                            }
                        }
                    }
                    #endif
                    
                    // Continue Button (only shows when apps are selected)
                    if shieldManager.hasShieldTargets {
                        Button(action: {
                            HapticManager.shared.success()
                            onComplete()
                        }) {
                            HStack(spacing: 12) {
                                Text(resolvedContinueTitle)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 28)
                
                Spacer()
            }
            
            // Permission Alert
            if showPermissionAlert {
                CustomAlertView(
                    title: NSLocalizedString("force_app_selection.permission_title", comment: "Permission Required"),
                    message: NSLocalizedString("force_app_selection.permission_message", comment: "Family Controls permission was denied. Please enable it in Settings → Screen Time → ScrollDeeds"),
                    icon: "lock.shield.fill",
                    iconColor: AppTheme.primary,
                    isPresented: $showPermissionAlert,
                    primaryAction: {
                        showPermissionAlert = false
                    },
                    primaryActionTitle: NSLocalizedString("common.ok", comment: "OK")
                )
            }
        }
        .onAppear {
            PostHogManager.shared.screen(AnalyticsScreen.appSelection)
            #if canImport(FamilyControls)
            if #available(iOS 16.0, *) {
                appSelection = shieldManager.currentFamilySelection()
            }
            #endif
            withAnimation(.easeOut(duration: 0.5)) {
                animateContent = true
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shieldManager.hasShieldTargets)
    }
    
    // MARK: - Family Controls Permission
    
    private func requestFamilyControlsPermission() {
        #if canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            let currentStatus = AuthorizationCenter.shared.authorizationStatus
            
            if currentStatus == .approved {
                isAppPickerPresented = true
                return
            }
            
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    await MainActor.run {
                        if AuthorizationCenter.shared.authorizationStatus == .approved {
                            isAppPickerPresented = true
                        } else {
                            showPermissionAlert = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        showPermissionAlert = true
                    }
                }
            }
        }
        #endif
    }
}

#Preview {
    ForceAppSelectionView(shieldManager: ShieldManager.shared, onComplete: {})
}
