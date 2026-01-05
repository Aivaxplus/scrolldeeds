//
//  PaywallView.swift
//  scrolldeeds
//
//  Conversion-optimized paywall with psychological triggers
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var appearAnimation = false
    @State private var pulseAnimation = false
    @State private var shineOffset: CGFloat = -200
    
    // Conversion optimization: Show yearly as massive savings
    private var monthlyPrice: String {
        if let monthly = subscriptionManager.offerings?.current?.availablePackages.first(where: { 
            $0.storeProduct.productIdentifier.contains("monthly") 
        }) {
            return monthly.storeProduct.localizedPriceString
        }
        return "€4.99"
    }
    
    private var yearlyPackage: Package? {
        subscriptionManager.offerings?.current?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier.contains("yearly")
        })
    }
    
    private var savingsPercentage: Int {
        // Calculate actual savings: monthly * 12 vs yearly
        guard let yearly = yearlyPackage,
              let monthlyPkg = subscriptionManager.offerings?.current?.availablePackages.first(where: {
                  $0.storeProduct.productIdentifier.contains("monthly")
              }) else { return 25 } // Default: 25% savings
        
        let monthlyTotal = monthlyPkg.storeProduct.price as Decimal * 12
        let yearlyPrice = yearly.storeProduct.price as Decimal
        
        // Avoid division by zero
        guard monthlyTotal > 0 else { return 25 }
        
        let savings = ((monthlyTotal - yearlyPrice) / monthlyTotal) * 100
        let percentage = Int(truncating: savings as NSNumber)
        
        // Return calculated value if reasonable, otherwise fallback to 25%
        // (Handles edge cases where prices aren't loaded correctly)
        return (percentage > 0 && percentage < 100) ? percentage : 25
    }
    
    var body: some View {
        ZStack {
            // Rich gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.10, blue: 0.08),
                    Color(red: 0.10, green: 0.16, blue: 0.12),
                    Color(red: 0.08, green: 0.14, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle pattern overlay
            GeometryReader { geo in
                ZStack {
                    // Radial glow behind content
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppTheme.primary.opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.6
                            )
                        )
                        .frame(width: geo.size.width, height: geo.size.width)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.3)
                }
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticManager.shared.soft()
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Hero Section
                    VStack(spacing: 16) {
                        // Premium crown icon with glow
                        ZStack {
                            // Glow rings
                            ForEach(0..<3) { i in
                                Circle()
                                    .stroke(
                                        AppTheme.accent.opacity(0.15 - Double(i) * 0.04),
                                        lineWidth: 2
                                    )
                                    .frame(width: CGFloat(90 + i * 25), height: CGFloat(90 + i * 25))
                                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.2),
                                        value: pulseAnimation
                                    )
                            }
                            
                            // Icon background
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.accent.opacity(0.25),
                                            AppTheme.primary.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppTheme.accent, AppTheme.accentLight],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .padding(.top, 8)
                        
                        // Title with emotional hook
                        VStack(spacing: 8) {
                            Text("Transform Your")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Screen Time")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppTheme.accent, AppTheme.accentLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        
                        // Subtitle with spiritual connection
                        Text("Replace mindless scrolling with mindful dhikr.\nEvery unlock brings you closer to Allah ﷻ")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 28)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    
                    // Social Proof Bar
                    HStack(spacing: 16) {
                        SocialProofItem(icon: "person.2.fill", text: "1,000+ Muslims")
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 1, height: 24)
                        
                        SocialProofItem(icon: "star.fill", text: "4.9 Rating")
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 1, height: 24)
                        
                        SocialProofItem(icon: "heart.fill", text: "Loved")
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    
                    // Benefits List - Compact & Powerful
                    VStack(spacing: 12) {
                        BenefitRow(icon: "lock.open.fill", text: "Unlock apps with dhikr", highlight: true)
                        BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track your spiritual progress", highlight: false)
                        BenefitRow(icon: "bell.badge.fill", text: "Smart reminders for consistency", highlight: false)
                        BenefitRow(icon: "infinity", text: "Unlimited dhikr sessions", highlight: false)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    
                    // Pricing Section
                    if subscriptionManager.isLoading {
                        SwiftUI.ProgressView()
                            .tint(AppTheme.accent)
                            .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 16) {
                            // Monthly first
                            if let monthly = subscriptionManager.offerings?.current?.availablePackages.first(where: {
                                $0.storeProduct.productIdentifier.contains("monthly")
                            }) {
                                MonthlyPlanCard(
                                    package: monthly,
                                    isSelected: selectedPackage?.identifier == monthly.identifier,
                                    onTap: {
                                        HapticManager.shared.soft()
                                        selectedPackage = monthly
                                    }
                                )
                            }
                            
                            // Yearly - BEST VALUE (Pre-selected)
                            if let yearly = yearlyPackage {
                                YearlyPlanCard(
                                    package: yearly,
                                    monthlyEquivalent: monthlyPrice,
                                    savingsPercent: savingsPercentage,
                                    isSelected: selectedPackage?.identifier == yearly.identifier,
                                    onTap: {
                                        HapticManager.shared.medium()
                                        selectedPackage = yearly
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                    }
                    
                    // CTA Button with shine effect
                    Button(action: {
                        HapticManager.shared.heavy()
                        purchaseSelectedProduct()
                    }) {
                        ZStack {
                            // Button background
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.78, blue: 0.40),
                                            Color(red: 0.88, green: 0.68, blue: 0.32)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // Shine effect
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shineOffset)
                                .mask(RoundedRectangle(cornerRadius: 16))
                            
                            // Button content
                            HStack(spacing: 10) {
                                if isPurchasing {
                                    SwiftUI.ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .bold))
                                    
                                    Text(selectedPackage?.storeProduct.productIdentifier.contains("yearly") == true 
                                         ? "Start 1 Month Free Trial" 
                                         : "Start Premium Now")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .foregroundColor(.black)
                        }
                        .frame(height: 56)
                    }
                    .disabled(selectedPackage == nil || isPurchasing)
                    .opacity((selectedPackage == nil || isPurchasing) ? 0.7 : 1.0)
                    .padding(.horizontal, 24)
                    .shadow(color: AppTheme.accent.opacity(0.4), radius: 20, y: 10)
                    
                    // Trust badges
                    HStack(spacing: 20) {
                        TrustBadge(icon: "lock.shield.fill", text: "Secure")
                        TrustBadge(icon: "arrow.clockwise", text: "Cancel Anytime")
                        TrustBadge(icon: "checkmark.seal.fill", text: "No Ads")
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Restore & Terms
                    VStack(spacing: 16) {
                        Button(action: {
                            HapticManager.shared.soft()
                            Task {
                                await subscriptionManager.restorePurchases()
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        // Subscription info
                        VStack(spacing: 8) {
                            Text("Payment will be charged to your Apple ID account. Subscription auto-renews unless cancelled 24 hours before the end of the current period.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.35))
                                .multilineTextAlignment(.center)
                            
                            // Terms and Privacy links (REQUIRED by Apple)
                            HStack(spacing: 4) {
                                Text("By subscribing, you agree to our")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.35))
                                
                                Button(action: {
                                    if let url = URL(string: "https://scrolldeeds.lovable.app/terms") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("Terms")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .underline()
                                }
                                
                                Text("and")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.35))
                                
                                Button(action: {
                                    if let url = URL(string: "https://scrolldeeds.lovable.app/privacy") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("Privacy Policy")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .underline()
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .overlay {
            if showError {
                CustomAlertView(
                    title: "Purchase Failed",
                    message: subscriptionManager.errorMessage ?? "An error occurred. Please try again.",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    isPresented: $showError,
                    primaryAction: { showError = false },
                    primaryActionTitle: "OK"
                )
            }
        }
        .onAppear {
            // Load offerings
            Task {
                await subscriptionManager.loadOfferings()
                
                // Pre-select yearly (best value) by default
                if let yearly = yearlyPackage {
                    selectedPackage = yearly
                } else if let first = subscriptionManager.offerings?.current?.availablePackages.first {
                    selectedPackage = first
                }
            }
            
            // Start animations
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
            
            // Pulse animation
            pulseAnimation = true
            
            // Shine animation
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false).delay(1)) {
                shineOffset = 400
            }
        }
    }
    
    private func purchaseSelectedProduct() {
        guard let package = selectedPackage else { return }
        
        isPurchasing = true
        
        Task {
            do {
                try await subscriptionManager.purchase(package)
                dismiss()
            } catch {
                if case SubscriptionError.userCancelled = error {
                    // User cancelled - don't show error
                } else {
                    showError = true
                }
            }
            
            isPurchasing = false
        }
    }
}

// MARK: - Social Proof Item

struct SocialProofItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.accent)
            
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let text: String
    let highlight: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(highlight ? AppTheme.primary.opacity(0.2) : Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(highlight ? AppTheme.primary : .white.opacity(0.8))
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

// MARK: - Yearly Plan Card (BEST VALUE)

struct YearlyPlanCard: View {
    let package: Package
    let monthlyEquivalent: String
    let savingsPercent: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    private var monthlyPrice: String {
        let price = package.storeProduct.price as Decimal
        let monthly = price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = package.storeProduct.priceFormatter?.locale ?? Locale.current
        return formatter.string(from: monthly as NSNumber) ?? ""
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Best Value Banner
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("BEST VALUE • 1 MONTH FREE")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accentLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Card Content
                VStack(spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Yearly")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Price breakdown
                            HStack(spacing: 8) {
                                Text(package.storeProduct.localizedPriceString)
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundColor(.white)
                                
                                Text("/year")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            // Monthly equivalent
                            Text("Just \(monthlyPrice)/month")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.primary)
                        }
                        
                        Spacer()
                        
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
                                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
                                    .frame(width: 26, height: 26)
                            }
                        }
                    }
                    
                    // Savings highlight
                    HStack {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 12, weight: .semibold))
                        
                        Text("Save \(savingsPercent)% vs monthly")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppTheme.accent.opacity(0.15))
                    )
                }
                .padding(18)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.14, green: 0.20, blue: 0.16),
                                Color(red: 0.10, green: 0.16, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isSelected 
                            ? LinearGradient(colors: [AppTheme.accent, AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.15)], startPoint: .top, endPoint: .bottom),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: isSelected ? AppTheme.primary.opacity(0.3) : Color.clear, radius: 16, y: 8)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Monthly Plan Card

struct MonthlyPlanCard: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack(spacing: 6) {
                        Text(package.storeProduct.localizedPriceString)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("/month")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.primary : Color.clear)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? AppTheme.primary : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Trust Badge

struct TrustBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.primary.opacity(0.8))
            
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

#Preview {
    PaywallView()
}
