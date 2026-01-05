//
//  HardPaywallView.swift
//  scrolldeeds
//
//  Hard Paywall Strategy - No Skip, No Exit, Must Subscribe
//

import SwiftUI
import RevenueCat

struct HardPaywallView: View {
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var pulseAnimation = false
    @State private var shineOffset: CGFloat = -200
    @State private var showDownsell = false
    @State private var exitAttempts = 0
    
    let onSubscribed: () -> Void
    
    // Price anchoring - calculate savings
    private var monthlyPrice: Decimal {
        if let monthly = subscriptionManager.offerings?.current?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier.contains("monthly")
        }) {
            return monthly.storeProduct.price as Decimal
        }
        return 4.99
    }
    
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
    
    private var yearlyMonthlyEquivalent: Decimal {
        guard let yearly = yearlyPackage else { return 3.75 }
        return (yearly.storeProduct.price as Decimal) / 12
    }
    
    private var savingsPercentage: Int {
        guard let yearly = yearlyPackage else { return 25 }
        let monthlyTotal = monthlyPrice * 12
        let yearlyPrice = yearly.storeProduct.price as Decimal
        guard monthlyTotal > 0 else { return 25 }
        let savings = ((monthlyTotal - yearlyPrice) / monthlyTotal) * 100
        let percentage = Int(truncating: savings as NSNumber)
        return (percentage > 0 && percentage < 100) ? percentage : 25
    }
    
    var body: some View {
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
            
            // Radial glow
            RadialGradient(
                colors: [
                    AppTheme.primary.opacity(0.12),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height * 0.5
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // NO CLOSE BUTTON - This is intentional for hard paywall
                    
                    Spacer().frame(height: 60)
                    
                    // Hero Section with Crown - NO animation on text
                    heroSection
                    
                    // Personalized Result Card - NO animation on text
                    personalizedResultCard
                        .padding(.top, 28)
                    
                    // Social Proof
                    socialProofBar
                        .padding(.top, 24)
                    
                    // Features List
                    featuresList
                        .padding(.top, 24)
                    
                    // Pricing Section
                    if subscriptionManager.isLoading {
                        SwiftUI.ProgressView()
                            .tint(AppTheme.accent)
                            .padding(.vertical, 40)
                    } else {
                        pricingSection
                            .padding(.top, 28)
                    }
                    
                    // CTA Button - "Try for $0 now"
                    ctaButton
                        .padding(.top, 24)
                    
                    // Trust Badges
                    trustBadges
                        .padding(.top, 20)
                    
                    // Terms & Restore
                    termsSection
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
            
            // Downsell Popup
            if showDownsell {
                downsellPopup
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(100)
            }
            
            // Error Alert
            if showError {
                CustomAlertView(
                    title: "Something went wrong",
                    message: errorMessage,
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    isPresented: $showError,
                    primaryAction: { showError = false },
                    primaryActionTitle: "Try Again"
                )
            }
        }
        .onAppear {
            // Track hard paywall shown
            AnalyticsManager.shared.trackHardPaywallShown()
            
            Task {
                await subscriptionManager.loadOfferings()
                // Pre-select yearly (best value)
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
        }
        // Intercept back gesture / swipe down
        .interactiveDismissDisabled(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    // If user tries to swipe down to dismiss
                    if value.translation.height > 100 {
                        handleExitAttempt()
                    }
                }
        )
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Crown icon with subtle glow (simplified)
            ZStack {
                // Single subtle glow ring
                Circle()
                    .stroke(AppTheme.accent.opacity(0.15), lineWidth: 2)
                    .frame(width: 110, height: 110)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
            }
            
            // Title - NO animation
            VStack(spacing: 8) {
                Text("Your Personal Plan")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.accent)
                    .tracking(1.5)
                    .textCase(.uppercase)
                
                Text("Is Ready")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(.white)
            }
            
            // Subtitle
            Text("Based on your answers, we've created\na personalized program just for you")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Personalized Result Card
    
    private var personalizedResultCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.accent)
                
                Text("YOUR PREDICTED RESULTS")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.accent)
                    .tracking(1)
            }
            
            VStack(spacing: 12) {
                ResultRow(icon: "clock.arrow.circlepath", text: "Save 2+ hours daily", highlight: true)
                ResultRow(icon: "brain.head.profile", text: "Break phone addiction in 21 days", highlight: false)
                ResultRow(icon: "heart.fill", text: "Feel closer to Allah ﷻ", highlight: true)
                ResultRow(icon: "chart.line.uptrend.xyaxis", text: "Build lasting spiritual habits", highlight: false)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Social Proof Bar
    
    private var socialProofBar: some View {
        HStack(spacing: 0) {
            SocialItem(number: "10K+", label: "Muslims")
            
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 36)
            
            SocialItem(number: "4.9", label: "Rating", icon: "star.fill")
            
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 36)
            
            SocialItem(number: "95%", label: "Success")
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }
    
    // MARK: - Features List
    
    private var featuresList: some View {
        VStack(spacing: 12) {
            FeatureItem(icon: "lock.open.fill", text: "Unlock apps with dhikr", isPrimary: true)
            FeatureItem(icon: "bell.badge.fill", text: "Smart accountability reminders", isPrimary: false)
            FeatureItem(icon: "chart.bar.fill", text: "Track your spiritual growth", isPrimary: false)
            FeatureItem(icon: "infinity", text: "Unlimited dhikr sessions", isPrimary: false)
        }
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            // Yearly Plan - RECOMMENDED (pre-selected)
            if let yearly = yearlyPackage {
                YearlyPlanButton(
                    package: yearly,
                    monthlyEquivalent: formatPrice(yearlyMonthlyEquivalent),
                    savingsPercent: savingsPercentage,
                    isSelected: selectedPackage?.identifier == yearly.identifier,
                    onTap: {
                        HapticManager.shared.medium()
                        selectedPackage = yearly
                    }
                )
            }
            
            // Monthly Plan
            if let monthly = monthlyPackage {
                MonthlyPlanButton(
                    package: monthly,
                    isSelected: selectedPackage?.identifier == monthly.identifier,
                    onTap: {
                        HapticManager.shared.soft()
                        selectedPackage = monthly
                    }
                )
            }
            
            // Price anchoring text
            if let yearly = yearlyPackage {
                HStack(spacing: 4) {
                    Text("💰")
                    Text("Pay \(yearly.storeProduct.localizedPriceString) once, use for a full year")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
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
                // Gold gradient background
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.82, blue: 0.45),
                                Color(red: 0.92, green: 0.72, blue: 0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Shine effect
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shineOffset)
                    .mask(RoundedRectangle(cornerRadius: 18))
                
                // Button content
                HStack(spacing: 12) {
                    if isPurchasing {
                        SwiftUI.ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .bold))
                        
                        VStack(spacing: 2) {
                            Text(selectedPackage?.storeProduct.productIdentifier.contains("yearly") == true
                                 ? "Try for $0 now"
                                 : "Start Premium Now")
                                .font(.system(size: 20, weight: .black))
                            
                            if selectedPackage?.storeProduct.productIdentifier.contains("yearly") == true {
                                Text("1 month free trial")
                                    .font(.system(size: 12, weight: .semibold))
                                    .opacity(0.8)
                            }
                        }
                    }
                }
                .foregroundColor(.black)
            }
            .frame(height: 64)
        }
        .disabled(selectedPackage == nil || isPurchasing)
        .opacity((selectedPackage == nil || isPurchasing) ? 0.7 : 1.0)
        .shadow(color: AppTheme.accent.opacity(0.5), radius: 24, y: 12)
    }
    
    // MARK: - Trust Badges
    
    private var trustBadges: some View {
        HStack(spacing: 24) {
            TrustItem(icon: "lock.shield.fill", text: "Secure")
            TrustItem(icon: "arrow.clockwise", text: "Cancel Anytime")
            TrustItem(icon: "checkmark.seal.fill", text: "No Ads")
        }
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                HapticManager.shared.soft()
                Task {
                    await subscriptionManager.restorePurchases()
                    if subscriptionManager.isPremium {
                        onSubscribed()
                    }
                }
            }) {
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            VStack(spacing: 8) {
                Text("Payment will be charged to your Apple ID account. Subscription auto-renews unless cancelled 24 hours before the end of the current period.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                
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
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Downsell Popup
    
    private var downsellPopup: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on background tap
                }
            
            // Popup Card
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("⏰")
                        .font(.system(size: 48))
                    
                    Text("WAIT!")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                    
                    Text("Special One-Time Offer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.accent)
                }
                
                // Offer Details
                VStack(spacing: 12) {
                    HStack {
                        Text("$69.99")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .strikethrough(true, color: .red)
                        
                        Text("→")
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("$29.99")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(AppTheme.accent)
                        
                        Text("/year")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Text("57% OFF - Only available now!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )
                
                // Urgency Text
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("This offer expires when you close this screen")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Accept Offer Button
                Button(action: {
                    HapticManager.shared.heavy()
                    // Purchase yearly at discounted rate (same product, psychological framing)
                    if let yearly = yearlyPackage {
                        selectedPackage = yearly
                        showDownsell = false
                        purchaseSelectedProduct()
                    }
                }) {
                    Text("GET THIS DEAL")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accentLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                
                // No Thanks Button
                Button(action: {
                    withAnimation(.spring()) {
                        showDownsell = false
                    }
                    // After declining downsell, user is stuck - they must subscribe or force close app
                }) {
                    Text("No thanks, I don't want to save money")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.16, blue: 0.14),
                                Color(red: 0.08, green: 0.12, blue: 0.10)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleExitAttempt() {
        exitAttempts += 1
        
        if exitAttempts == 1 {
            // First exit attempt - show downsell
            HapticManager.shared.warning()
            withAnimation(.spring()) {
                showDownsell = true
            }
        }
        // After first attempt, user is stuck - they must subscribe or force close app
    }
    
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
                onSubscribed()
            } catch {
                if case SubscriptionError.userCancelled = error {
                    // User cancelled - track and show downsell
                    AnalyticsManager.shared.trackPurchaseFailed(productId: productId, error: "user_cancelled")
                    handleExitAttempt()
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
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: price as NSNumber) ?? "$\(price)"
    }
}

// MARK: - Supporting Views

struct ResultRow: View {
    let icon: String
    let text: String
    let highlight: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(highlight ? AppTheme.primary.opacity(0.15) : Color.white.opacity(0.08))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(highlight ? AppTheme.primary : .white.opacity(0.8))
            }
            
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.primary)
        }
    }
}

struct SocialItem: View {
    let number: String
    let label: String
    var icon: String? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.accent)
                }
                Text(number)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    let isPrimary: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isPrimary ? AppTheme.primary.opacity(0.15) : Color.white.opacity(0.06))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isPrimary ? AppTheme.primary : .white.opacity(0.7))
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.primary)
        }
        .padding(.vertical, 4)
    }
}

struct TrustItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.primary.opacity(0.8))
            
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct YearlyPlanButton: View {
    let package: Package
    let monthlyEquivalent: String
    let savingsPercent: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Best Value Banner
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("BEST VALUE • 1 MONTH FREE TRIAL")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accentLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Content
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yearly")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text(package.storeProduct.localizedPriceString)
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(.white)
                            
                            Text("/year")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Text("Just \(monthlyEquivalent)/month")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        // Selection indicator
                        ZStack {
                            Circle()
                                .fill(isSelected ? AppTheme.primary : Color.clear)
                                .frame(width: 28, height: 28)
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
                                    .frame(width: 28, height: 28)
                            }
                        }
                        
                        // Savings badge
                        Text("SAVE \(savingsPercent)%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.accent)
                            .cornerRadius(6)
                    }
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
                        lineWidth: isSelected ? 2.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: isSelected ? AppTheme.primary.opacity(0.35) : Color.clear, radius: 20, y: 10)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MonthlyPlanButton: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 6) {
                        Text(package.storeProduct.localizedPriceString)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("/month")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
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
                    .fill(Color.white.opacity(0.04))
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

#Preview {
    HardPaywallView(onSubscribed: {})
}

