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
                            
                            Text(NSLocalizedString("customer_center.title", comment: "Manage Subscription"))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text(NSLocalizedString("customer_center.subtitle", comment: "View and manage your subscription settings"))
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
                                    Text(NSLocalizedString("customer_center.restore", comment: "Restore Purchases"))
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
                            if subscriptionManager.customerInfo != nil {
                                Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                                    HStack {
                                        Image(systemName: "external-link")
                                            .font(.system(size: 18, weight: .semibold))
                                        Text(NSLocalizedString("customer_center.manage_app_store", comment: "Manage in App Store"))
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
                                Text(NSLocalizedString("customer_center.debug_info", comment: "Debug Info"))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(String(format: NSLocalizedString("customer_center.user_id", comment: "User ID: %@"), customerInfo.originalAppUserId))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Text(String(format: NSLocalizedString("customer_center.active_subs", comment: "Active Subscriptions: %@"), customerInfo.activeSubscriptions.joined(separator: ", ")))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    if let expirationDate = subscriptionManager.getEntitlementExpirationDate("Scrolldeeds Pro") {
                                        Text(String(format: NSLocalizedString("customer_center.expires", comment: "Expires: %@"), expirationDate.formatted()))
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
            .navigationTitle(NSLocalizedString("customer_center.account", comment: "Account"))
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
                        title: NSLocalizedString("customer_center.error", comment: "Error"),
                        message: errorMessage ?? NSLocalizedString("customer_center.unknown_error", comment: "An unknown error occurred"),
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        isPresented: $showError,
                        primaryAction: {
                            showError = false
                        },
                        primaryActionTitle: NSLocalizedString("common.ok", comment: "OK")
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
        
        await subscriptionManager.restorePurchases()
        await MainActor.run {
            if !subscriptionManager.hasPremiumAccess {
                errorMessage = NSLocalizedString("paywall.restore.none", comment: "")
                showError = true
            }
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
                Text(isPremium ? NSLocalizedString("customer_center.premium_active", comment: "Premium Active") : NSLocalizedString("customer_center.no_subscription", comment: "No Active Subscription"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(isPremium ? NSLocalizedString("customer_center.premium_message", comment: "You have access to all premium features") : NSLocalizedString("customer_center.subscribe_message", comment: "Subscribe to unlock premium features"))
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

