//
//  SoftPaywallView.swift
//  scrolldeeds
//
//  Soft Paywall - Can be skipped with X button (shown after onboarding)
//  Hard paywall is shown later when user tries to unlock apps
//

import SwiftUI
import RevenueCat

struct SoftPaywallView: View {
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var pulseAnimation = false
    @State private var shineOffset: CGFloat = -200
    @State private var showCloseButton = false // Delayed close button
    @State private var showThankYou = false // Thank you page after purchase
    
    let onSubscribed: () -> Void
    let onSkip: () -> Void
    
    private var yearlyPackage: Package? {
        subscriptionManager.offerings?.current?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier.contains("yearly")
        })
    }
    
    private var monthlyPackage: Package? {
        subscriptionManager.offerings?.current?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier.contains("monthly")
        })
    }
    
    private var monthlyPrice: Decimal {
        monthlyPackage?.storeProduct.price as? Decimal ?? 4.99
    }
    
    private var yearlyMonthlyEquivalent: String {
        guard let yearly = yearlyPackage else { return "$3.75" }
        let monthly = (yearly.storeProduct.price as Decimal) / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearly.storeProduct.priceFormatter?.locale ?? Locale.current
        return formatter.string(from: monthly as NSNumber) ?? "$3.75"
    }
    
    private var savingsPercentage: Int {
        guard let yearly = yearlyPackage, let monthly = monthlyPackage else { return 25 }
        let monthlyTotal = (monthly.storeProduct.price as Decimal) * 12
        let yearlyPrice = yearly.storeProduct.price as Decimal
        guard monthlyTotal > 0 else { return 25 }
        let savings = ((monthlyTotal - yearlyPrice) / monthlyTotal) * 100
        let percentage = Int(truncating: savings as NSNumber)
        return (percentage > 0 && percentage < 100) ? percentage : 25
    }
    
    var body: some View {
        ZStack {
            // Show Thank You page after successful purchase
            if showThankYou {
                ThankYouView(onContinue: {
                    onSubscribed()
                })
                .transition(.opacity)
            } else {
                // Main paywall content
                paywallContent
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showThankYou)
    }
    
    private var paywallContent: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.08, blue: 0.06),
                    Color(red: 0.08, green: 0.14, blue: 0.10),
                    Color(red: 0.06, green: 0.10, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Glow effect
            RadialGradient(
                colors: [AppTheme.primary.opacity(0.1), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                    // Close button (X) - Appears after 5 seconds
                    HStack {
                        Spacer()
                        if showCloseButton {
                            Button(action: {
                                HapticManager.shared.soft()
                                AnalyticsManager.shared.trackSoftPaywallSkipped()
                                onSkip()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .frame(height: 52) // Fixed height to prevent layout shift
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero Section
                        heroSection
                            .padding(.top, 20)
                        
                        // Benefits
                        benefitsSection
                            .padding(.top, 28)
                        
                        // Pricing
                        if subscriptionManager.isLoading {
                            SwiftUI.ProgressView()
                                .tint(AppTheme.accent)
                                .padding(.vertical, 40)
                        } else {
                            pricingSection
                                .padding(.top, 24)
                        }
                        
                        // CTA Button
                        ctaButton
                            .padding(.top, 24)
                        
                        // Skip text - only shows after close button appears
                        if showCloseButton {
                            Button(action: {
                                HapticManager.shared.soft()
                                AnalyticsManager.shared.trackSoftPaywallSkipped()
                                onSkip()
                            }) {
                                Text("Maybe later")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(.top, 16)
                            }
                            .transition(.opacity)
                        }
                        
                        // Terms
                        termsSection
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Error overlay
            if showError {
                CustomAlertView(
                    title: "Something went wrong",
                    message: errorMessage,
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    isPresented: $showError,
                    primaryAction: { showError = false },
                    primaryActionTitle: "OK"
                )
            }
        }
        .onAppear {
            // Track soft paywall shown
            AnalyticsManager.shared.trackSoftPaywallShown()
            
            Task {
                await subscriptionManager.loadOfferings()
                if let yearly = yearlyPackage {
                    selectedPackage = yearly
                }
            }
            
            // Start subtle animations
            pulseAnimation = true
            
            // Button shine effect
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false).delay(1)) {
                shineOffset = 400
            }
            
            // Show close button after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showCloseButton = true
                }
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Crown icon with subtle glow
            ZStack {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.12), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
            }
            
            // Title - NO animation
            VStack(spacing: 8) {
                Text("Unlock Your")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Full Potential")
                    .font(.system(size: 30, weight: .black))
                    .foregroundColor(AppTheme.accent)
            }
            
            // Subtitle
            Text("Transform screen time into spiritual growth")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(spacing: 12) {
            BenefitItem(icon: "lock.open.fill", text: "Unlock apps with dhikr")
            BenefitItem(icon: "chart.line.uptrend.xyaxis", text: "Track spiritual progress")
            BenefitItem(icon: "bell.badge.fill", text: "Smart reminders")
            BenefitItem(icon: "infinity", text: "Unlimited sessions")
        }
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: 14) {
            // Yearly - Best Value
            if let yearly = yearlyPackage {
                PlanCard(
                    title: "Yearly",
                    price: yearly.storeProduct.localizedPriceString,
                    period: "/year",
                    subtitle: "Just \(yearlyMonthlyEquivalent)/month • 1 month free trial",
                    badge: "BEST VALUE",
                    savingsPercent: savingsPercentage,
                    isSelected: selectedPackage?.identifier == yearly.identifier,
                    onTap: {
                        HapticManager.shared.medium()
                        selectedPackage = yearly
                    }
                )
            }
            
            // Monthly
            if let monthly = monthlyPackage {
                PlanCard(
                    title: "Monthly",
                    price: monthly.storeProduct.localizedPriceString,
                    period: "/month",
                    subtitle: nil,
                    badge: nil,
                    savingsPercent: nil,
                    isSelected: selectedPackage?.identifier == monthly.identifier,
                    onTap: {
                        HapticManager.shared.soft()
                        selectedPackage = monthly
                    }
                )
            }
        }
    }
    
    // MARK: - CTA Button
    
    private var ctaButton: some View {
        Button(action: {
            HapticManager.shared.heavy()
            purchaseSelectedProduct()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.82, blue: 0.45),
                            Color(red: 0.92, green: 0.72, blue: 0.35)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                
                // Shine
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [.clear, Color.white.opacity(0.3), .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .offset(x: shineOffset)
                    .mask(RoundedRectangle(cornerRadius: 16))
                
                HStack(spacing: 10) {
                    if isPurchasing {
                        SwiftUI.ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .bold))
                        
                        Text(selectedPackage?.storeProduct.productIdentifier.contains("yearly") == true
                             ? "Try Free for 1 Month"
                             : "Start Premium")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .foregroundColor(.black)
            }
            .frame(height: 56)
        }
        .disabled(selectedPackage == nil || isPurchasing)
        .opacity((selectedPackage == nil || isPurchasing) ? 0.7 : 1.0)
        .shadow(color: AppTheme.accent.opacity(0.4), radius: 20, y: 10)
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task { await subscriptionManager.restorePurchases()
                    if subscriptionManager.isPremium { onSubscribed() }
                }
            }) {
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Text("Payment charged to Apple ID. Auto-renews unless cancelled 24hrs before period ends.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.35))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Link("Terms", destination: URL(string: "https://scrolldeeds.lovable.app/terms")!)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("•").foregroundColor(.white.opacity(0.3))
                
                Link("Privacy", destination: URL(string: "https://scrolldeeds.lovable.app/privacy")!)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    // MARK: - Purchase
    
    private func purchaseSelectedProduct() {
        guard let package = selectedPackage else { return }
        isPurchasing = true
        
        let productId = package.storeProduct.productIdentifier
        let isYearly = productId.contains("yearly")
        
        // Track purchase attempt
        AnalyticsManager.shared.trackPurchaseAttempted(productId: productId, isYearly: isYearly)
        
        Task {
            do {
                try await subscriptionManager.purchase(package)
                // Track success
                AnalyticsManager.shared.trackPurchaseCompleted(productId: productId, isYearly: isYearly)
                
                // Show thank you page instead of directly going to app
                await MainActor.run {
                    showThankYou = true
                }
            } catch {
                if case SubscriptionError.userCancelled = error {
                    // User cancelled - track as failed
                    AnalyticsManager.shared.trackPurchaseFailed(productId: productId, error: "user_cancelled")
                } else {
                    // Track error
                    AnalyticsManager.shared.trackPurchaseFailed(productId: productId, error: error.localizedDescription)
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            isPurchasing = false
        }
    }
}

// MARK: - Supporting Views

struct BenefitItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 38, height: 38)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.primary)
        }
        .padding(.vertical, 4)
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let subtitle: String?
    let badge: String?
    let savingsPercent: Int?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Badge
                if let badge = badge {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accentLight],
                        startPoint: .leading, endPoint: .trailing
                    ))
                }
                
                // Content
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 6) {
                            Text(price)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(period)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        // Selection indicator
                        ZStack {
                            Circle()
                                .fill(isSelected ? AppTheme.primary : Color.clear)
                                .frame(width: 26, height: 26)
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 26, height: 26)
                            }
                        }
                        
                        // Savings badge
                        if let percent = savingsPercent {
                            Text("SAVE \(percent)%")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(AppTheme.accent)
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(isSelected ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isSelected ? AppTheme.primary : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SoftPaywallView(onSubscribed: {}, onSkip: {})
}

