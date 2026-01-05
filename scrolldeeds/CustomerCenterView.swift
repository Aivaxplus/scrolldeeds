//
//  CustomerCenterView.swift
//  scrolldeeds
//
//  RevenueCat Customer Center integration for managing subscriptions
//

import SwiftUI
import RevenueCat

struct CustomerCenterView: View {
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.primary)
                            
                            Text("Manage Subscription")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("View and manage your subscription settings")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Subscription Status
                        if subscriptionManager.isPremium {
                            SubscriptionStatusCard(isPremium: true)
                        } else {
                            SubscriptionStatusCard(isPremium: false)
                        }
                        
                        // Actions
                        VStack(spacing: 16) {
                            // Restore Purchases
                            Button(action: {
                                Task {
                                    await restorePurchases()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Restore Purchases")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(AppTheme.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.primary.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .disabled(isLoading)
                            
                            // Open RevenueCat Customer Center (if available)
                            if let customerInfo = subscriptionManager.customerInfo {
                                Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                                    HStack {
                                        Image(systemName: "external-link")
                                            .font(.system(size: 18, weight: .semibold))
                                        Text("Manage in App Store")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppTheme.card)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Customer Info (Debug - remove in production)
                        #if DEBUG
                        if let customerInfo = subscriptionManager.customerInfo {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Debug Info")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("User ID: \(customerInfo.originalAppUserId)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Text("Active Subscriptions: \(customerInfo.activeSubscriptions.joined(separator: ", "))")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    if let expirationDate = subscriptionManager.getEntitlementExpirationDate("Scrolldeeds Pro") {
                                        Text("Expires: \(expirationDate.formatted())")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                            }
                            .padding()
                            .background(AppTheme.card)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        #endif
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .overlay {
                if showError {
                    CustomAlertView(
                        title: "Error",
                        message: errorMessage ?? "An unknown error occurred",
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        isPresented: $showError,
                        primaryAction: {
                            showError = false
                        },
                        primaryActionTitle: "OK"
                    )
                }
            }
        }
        .task {
            // Load customer info when view appears
            do {
                _ = try await subscriptionManager.getCustomerInfo()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await subscriptionManager.restorePurchases()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Subscription Status Card

struct SubscriptionStatusCard: View {
    let isPremium: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isPremium ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(isPremium ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isPremium ? "Premium Active" : "No Active Subscription")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(isPremium ? "You have access to all premium features" : "Subscribe to unlock premium features")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }
}

