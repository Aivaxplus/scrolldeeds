//
//  FamilyControlsPermissionView.swift
//  scrolldeeds
//
//  Dedicated view to request Family Controls permission
//

import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

// Simple activity indicator to avoid naming conflict with ProgressView
struct ActivityIndicator: View {
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.white, lineWidth: 3)
            .frame(width: 20, height: 20)
            .rotationEffect(Angle(degrees: 0))
            .onAppear {
                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                    // Rotation animation
                }
            }
    }
}

struct FamilyControlsPermissionView: View {
    @Binding var isPresented: Bool
    let onApproved: () -> Void
    
    @State private var isRequesting = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.primary)
                }
                
                // Title
                VStack(spacing: 12) {
                    Text("Enable App Locking")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("ScrollDeeds needs permission to lock your selected apps using Screen Time.")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Info cards
                VStack(spacing: 16) {
                    infoRow(icon: "checkmark.shield.fill", text: "Your data stays private and local")
                    infoRow(icon: "lock.fill", text: "Only selected apps will be locked")
                    infoRow(icon: "hand.raised.fill", text: "You can change settings anytime")
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                }
                
                // Button
                Button(action: requestPermission) {
                    HStack(spacing: 12) {
                        if isRequesting {
                            ActivityIndicator()
                        } else {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 18))
                            Text("Allow App Locking")
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.gradientPrimary)
                    .cornerRadius(16)
                }
                .disabled(isRequesting)
                .padding(.horizontal, 30)
                
                Button("Skip for Now") {
                    isPresented = false
                }
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppTheme.primary)
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textSecondary)
            
            Spacer()
        }
    }
    
    private func requestPermission() {
        #if canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            isRequesting = true
            errorMessage = nil
            
            debugPrint("🔐 REQUESTING Family Controls permission...")
            debugPrint("🔐 Current status: \(AuthorizationCenter.shared.authorizationStatus.rawValue)")
            
            // Use the NEW iOS 16+ API
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    
                    await MainActor.run {
                        let status = AuthorizationCenter.shared.authorizationStatus
                        debugPrint("✅ Request completed! New status: \(status.rawValue)")
                        
                        isRequesting = false
                        
                        if status == .approved {
                            debugPrint("🎉 APPROVED! Calling onApproved...")
                            isPresented = false
                            onApproved()
                        } else {
                            debugPrint("❌ Not approved. Status: \(status)")
                            errorMessage = "Permission was not granted. Please enable Screen Time in Settings."
                        }
                    }
                } catch {
                    await MainActor.run {
                        isRequesting = false
                        errorMessage = "Error: \(error.localizedDescription)"
                        debugPrint("❌ Error requesting permission: \(error)")
                    }
                }
            }
        }
        #endif
    }
}

#Preview {
    FamilyControlsPermissionView(isPresented: .constant(true), onApproved: {
        debugPrint("Permission approved!")
    })
}

