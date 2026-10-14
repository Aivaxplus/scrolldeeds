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
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var userDataManager = UserDataManager.shared
    @ObservedObject private var localStorage = LocalStorageManager.shared
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var pulseAnimation = false
    @State private var shineOffset: CGFloat = -200
    @State private var selectedPricingOption: PricingOption = .yearly
    @State private var isInitialized = false
    @State private var initializationAttempted = false
    
    enum PricingOption {
        case yearly
        case monthly
    }
    
    // Flow states: loading → planReady → reminder → pricing
    enum PaywallStep {
        case loading
        case planReady
        case reminder
        case pricing
    }
    
    @State private var currentStep: PaywallStep = .loading
    @State private var showDownsell: Bool = false // Show weekly downsell sheet
    @State private var showThankYou: Bool = false // Show thank you page after purchase
    @State private var showPostAppSelection: Bool = false // After thank you: pick apps to lock
    @State private var showPostGuideMuslims: Bool = false // After apps: guide other Muslims + review
    @State private var showPostDifficulty: Bool = false // After review: pick unlock difficulty
    
    // Loading animation states
    @State private var loadingProgress: CGFloat = 0
    @State private var loadingStep = 0
    @State private var showCheckmark1 = false
    @State private var showCheckmark2 = false
    @State private var showCheckmark3 = false
    @State private var loadingPulse = false
    
    // Safe loading spinner states (timer-based, no repeatForever)
    @State private var safeLoadingRotation: Double = 0
    @State private var safeLoadingOpacity: Double = 0
    @State private var safeSpinnerTimer: Timer? = nil
    
    // Staggered content appear (premium feel)
    @State private var contentAppeared = false
    
    let onSubscribed: () -> Void

    /// Local 3-day app trial still running (persisted). Used for pricing “continue with trial” and to avoid calling `startFreeTrial` again on the reminder step.
    private var hasActiveLocalTrial: Bool {
        guard let expiry = subscriptionManager.trialExpiryDate else { return false }
        return Date() <= expiry && !subscriptionManager.isPremium
    }

    /// Yearly and monthly: same paid CTA. No free trial.
    private var pricingPrimaryCTALabel: String {
        NSLocalizedString("paywall.cta.unlock_plan", comment: "Start my good deeds")
    }

    private var personalizedDisplayName: String {
        let raw = userDataManager.userName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let raw, !raw.isEmpty { return raw }
        return ""
    }

    private var personalizedHours: Int {
        let hours = localStorage.onboardingScrollHours
        return hours > 0 ? hours : 3
    }

    private var personalizedUnlockMinutes: Int {
        userDataManager.effectiveUnlockMinutesAfterDeed()
    }

    private var planReadyTitle: String {
        if personalizedDisplayName.isEmpty {
            return NSLocalizedString("paywall.personal_plan.title", comment: "Your Personal Plan")
        }
        return String(format: NSLocalizedString("paywall.personal_plan.title_named", comment: ""), personalizedDisplayName)
    }

    private var planReadySubtitle: String {
        String(
            format: NSLocalizedString("paywall.personal_plan.subtitle_personal", comment: ""),
            personalizedHours,
            personalizedUnlockMinutes
        )
    }

    private var personalizedSaveHoursText: String {
        let reclaim = max(1, personalizedHours / 2)
        return String(format: NSLocalizedString("paywall.result.save_hours_personal", comment: ""), reclaim)
    }

    private var personalizedUnlockText: String {
        String(format: NSLocalizedString("paywall.result.unlock_minutes_personal", comment: ""), personalizedUnlockMinutes)
    }

    private var loadingStep1Text: String {
        String(format: NSLocalizedString("paywall.loading.step1_personal", comment: ""), personalizedHours)
    }

    private var loadingStep2Text: String {
        String(format: NSLocalizedString("paywall.loading.step2_personal", comment: ""), personalizedUnlockMinutes)
    }

    private var loadingStep3Text: String {
        if personalizedDisplayName.isEmpty {
            return NSLocalizedString("paywall.loading.step3", comment: "Generating personalized plan")
        }
        return String(format: NSLocalizedString("paywall.loading.step3_personal", comment: ""), personalizedDisplayName)
    }

    /// Short trust line directly above the primary pay CTA (yearly vs monthly).
    private var pricingCTAAboveDisclaimer: String {
        if selectedPricingOption == .yearly {
            return NSLocalizedString("paywall.pricing.cta_above.yearly", comment: "No Payment Due Now")
        }
        return NSLocalizedString("paywall.pricing.cta_above.monthly", comment: "No commitment - Cancel anytime")
    }

    private var paywallOffering: Offering? {
        subscriptionManager.resolvedPaywallOffering()
    }
    
    // Price anchoring - fallbacks: €39.99/year, €5.99/month, €1.99/week
    private var monthlyPrice: Decimal {
        guard let current = paywallOffering else {
            return 5.99
        }
        guard !current.availablePackages.isEmpty else {
            return 5.99
        }
        if let monthly = current.availablePackages.first(where: {
            $0.storeProduct.productIdentifier.contains("monthly")
        }) {
            return monthly.storeProduct.price as Decimal
        }
        return 5.99
    }
    
    private var yearlyPackage: Package? {
        guard let current = paywallOffering else {
            return nil
        }
        guard !current.availablePackages.isEmpty else {
            return nil
        }
        return current.availablePackages.first(where: {
            $0.storeProduct.productIdentifier.contains("yearly")
        })
    }
    
    private var monthlyPackage: Package? {
        guard let current = paywallOffering else {
            return nil
        }
        guard !current.availablePackages.isEmpty else {
            return nil
        }
        return current.availablePackages.first(where: {
            $0.storeProduct.productIdentifier.contains("monthly")
        })
    }
    
    private var weeklyPackage: Package? {
        // Referral pricing only applies to yearly/monthly; weekly stays on standard `current` offering.
        let weeklyOffering = ReferralManager.shared.hasActiveReferral
            ? subscriptionManager.standardPaywallOffering()
            : paywallOffering
        guard let current = weeklyOffering else {
            return nil
        }
        
        let package = current.availablePackages.first(where: {
            let productId = $0.storeProduct.productIdentifier.lowercased()
            let packageId = $0.identifier.lowercased()
            return productId.contains("weekly") || 
                   productId == "com.scrolldeeds.app.premium.weekly" || 
                   productId == "com.scrolldeeds.premium.weekly" ||
                   packageId == "$rc_weekly" ||
                   packageId.contains("weekly")
        })
        
        // Debug logging
        if let package = package {
            debugPrint("✅ Weekly package found!")
            debugPrint("   Package ID: \(package.identifier)")
            debugPrint("   Product ID: \(package.storeProduct.productIdentifier)")
        } else {
            debugPrint("⚠️ Weekly package not found. Available packages:")
            current.availablePackages.forEach { pkg in
                debugPrint("  - Package ID: \(pkg.identifier), Product ID: \(pkg.storeProduct.productIdentifier)")
            }
        }
        
        return package
    }
    
    private var yearlyMonthlyEquivalent: Decimal {
        guard let yearly = yearlyPackage else { return Decimal(39.99) / 12 }
        let price = yearly.storeProduct.price as Decimal
        guard price > 0 else { return Decimal(39.99) / 12 }
        let monthly = price / 12
        return monthly > 0 ? monthly : Decimal(39.99) / 12
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
    
    /// "Try for €0,00" / "Try for $0.00" etc. using the user's locale currency.
    private var tryForZeroButtonLabel: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        let zeroString = formatter.string(from: 0 as NSNumber) ?? "0.00"
        return String(format: NSLocalizedString("paywall.try_for", comment: "Try for %@"), zeroString)
    }
    
    @ViewBuilder
    var body: some View {
        Group {
            // Post-purchase: Thank You → app selection → guide Muslims → difficulty → dashboard
            if showPostDifficulty {
                PostSubscribeDifficultyView(onContinue: {
                    onSubscribed()
                })
                .transition(.opacity)
            } else if showPostGuideMuslims {
                PostSubscribeGuideMuslimsView(onContinue: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showPostGuideMuslims = false
                        showPostDifficulty = true
                    }
                })
                .transition(.opacity)
            } else if showPostAppSelection {
                ForceAppSelectionView(
                    shieldManager: ShieldManager.shared,
                    continueButtonTitle: NSLocalizedString("questionnaire.continue", comment: "Continue"),
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showPostAppSelection = false
                            showPostGuideMuslims = true
                        }
                    }
                )
                .transition(.opacity)
            } else if showThankYou {
                ThankYouView(onContinue: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showThankYou = false
                        showPostAppSelection = true
                    }
                })
                .transition(.opacity)
            } else {
                // Show loading first, then cross-fade into paywall content
                if !isInitialized {
                    safeLoadingView
                        .transition(.opacity)
                } else {
                    paywallContent
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isInitialized)
        .animation(.easeInOut(duration: 0.35), value: showThankYou)
        .animation(.easeInOut(duration: 0.35), value: showPostAppSelection)
        .animation(.easeInOut(duration: 0.35), value: showPostGuideMuslims)
        .animation(.easeInOut(duration: 0.35), value: showPostDifficulty)
        .onAppear {
            PostHogManager.shared.screen(AnalyticsScreen.paywall)
            PostHogManager.shared.trackPaywallViewed(context: "hard_paywall")
            AnalyticsManager.shared.trackHardPaywallShown()
            safeOnAppear()
        }
    }
    
    // Initial loading view – matches paywall background, no crash-prone animations
    private var safeLoadingView: some View {
        ZStack {
            // Identical background so the transition from questionnaire is seamless
            staticBackground
            staticGlow

            VStack(alignment: .center, spacing: 24) {
                // Simple gold arc spinner (no repeatForever – driven by onAppear)
                ZStack(alignment: .center) {
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.12), lineWidth: 4)
                        .frame(width: 36, height: 36)
                    Circle()
                        .trim(from: 0, to: 0.28)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primary],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(safeLoadingRotation), anchor: .center)
                }
                .frame(width: 44, height: 44)

                Text(NSLocalizedString("paywall.loading.title", comment: "Creating Your Plan"))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .opacity(safeLoadingOpacity)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            // Fade in the label
            withAnimation(.easeIn(duration: 0.5)) {
                safeLoadingOpacity = 1.0
            }
            // Spin the arc with a simple timer-based rotation (no repeatForever)
            startSafeSpinner()
        }
        .onDisappear {
            safeSpinnerTimer?.invalidate()
            safeSpinnerTimer = nil
        }
    }

    private func startSafeSpinner() {
        safeSpinnerTimer?.invalidate()
        safeSpinnerTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            DispatchQueue.main.async {
                safeLoadingRotation += 4          // ~240°/s
            }
        }
    }
    
    // 100% SAFE onAppear handler
    private func safeOnAppear() {
        // Prevent multiple calls
        guard !initializationAttempted else { return }
        initializationAttempted = true
        
        // Always ensure main thread
        if Thread.isMainThread {
            performInitialization()
        } else {
            DispatchQueue.main.async {
                self.performInitialization()
            }
        }
    }
    
    // Smooth initialization – cross-fades from safeLoadingView into paywallContent
    private func performInitialization() {
        // Cross-fade into the real content
        withAnimation(.easeInOut(duration: 0.35)) {
            isInitialized = true
        }
        
        // Delay paywall init slightly to ensure the view is stable
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.initializePaywall()
        }
    }
    
    // 100% SAFE initialization with full error handling
    private func initializePaywall() {
        // Ensure main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.initializePaywall()
            }
            return
        }
        
        // Track hard paywall shown - safe
        AnalyticsManager.shared.trackHardPaywallShown()
        
        // Load offerings FIRST before starting animations - 100% SAFE
        Task { @MainActor in
            await self.subscriptionManager.loadOfferings()
            
            // Wait a tiny bit to ensure offerings are fully processed
            try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
            
            // Pre-select yearly (best value) after offerings are loaded - SAFE
            if let yearly = yearlyPackage {
                selectedPackage = yearly
                debugPrint("✅ Yearly package selected: \(yearly.storeProduct.productIdentifier)")
            } else if let monthly = monthlyPackage {
                selectedPackage = monthly
                selectedPricingOption = .monthly
                debugPrint("✅ Monthly package selected: \(monthly.storeProduct.productIdentifier)")
            } else {
                debugPrint("⚠️ No packages available")
                errorMessage = "Unable to load subscription options. Please check your internet connection and try again."
                showError = true
                return
            }
            
            // Start loading animation AFTER offerings are loaded - SAFE
            startPlanGeneration()
        }
        
        // Start safe visual animations (only affect visual elements, not layout)
        pulseAnimation = true
        
        // Button shine effect - SAFE (only animates overlay, not button layout)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shineOffset = 400
            }
        }
    }
    
    /// Load RevenueCat offerings and start paywall flow if packages are available. Called on init and on "Try Again".
    private func loadOfferingsAndStartIfReady() async {
        await subscriptionManager.loadOfferings()
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s for RevenueCat/StoreKit to process
        if let yearly = yearlyPackage {
            await MainActor.run {
                selectedPackage = yearly
                debugPrint("✅ Yearly package selected: \(yearly.storeProduct.productIdentifier)")
                startPlanGeneration()
            }
            return
        }
        if let monthly = monthlyPackage {
            await MainActor.run {
                selectedPackage = monthly
                selectedPricingOption = .monthly
                debugPrint("✅ Monthly package selected: \(monthly.storeProduct.productIdentifier)")
                startPlanGeneration()
            }
            return
        }
        debugPrint("⚠️ No packages available")
        await MainActor.run {
            errorMessage = NSLocalizedString("paywall.error.no_packages", comment: "Unable to load subscription options. Please check your internet connection and try again.")
            showError = true
        }
    }
    
    /// Retry loading offerings when user taps "Try Again" on the error alert.
    private func retryLoadOfferings() {
        showError = false
        Task { @MainActor in
            await loadOfferingsAndStartIfReady()
        }
    }
    
    private var paywallContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark gradient background - COMPLETELY STATIC, no animations ever
                staticBackground
                
                // Radial glow - COMPLETELY STATIC, no animations ever
                staticGlow
                
                // Content - SAFE ANIMATIONS (only opacity transitions, no layout)
                Group {
                    switch currentStep {
                    case .loading:
                        // Step 1: Loading Animation
                        planGenerationLoadingView(geometry: geometry)
                        
                    case .planReady:
                        // Step 2: Your Personal Plan is Ready
                        planReadyView(geometry: geometry)
                        
                    case .reminder:
                        // Step 3: Reminder Selection
                        reminderSelectionView(geometry: geometry)
                        
                    case .pricing:
                        // Step 4: Pricing (Opal Style)
                        // Only show pricing if packages are loaded
                        if selectedPackage != nil || yearlyPackage != nil || monthlyPackage != nil {
                            pricingView(geometry: geometry)
                        } else {
                            // Show loading if packages not ready
                            planGenerationLoadingView(geometry: geometry)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Subtiele overgangsanimatie tussen de stappen (fade + lichte scale)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .animation(.easeInOut(duration: 0.4), value: currentStep)
                
                // Error Alert
                if showError {
                    CustomAlertView(
                        title: LocalizedKey.Error.somethingWentWrong.localized,
                        message: errorMessage,
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        isPresented: $showError,
                        primaryAction: { retryLoadOfferings() },
                        primaryActionTitle: LocalizedKey.Error.tryAgain.localized
                    )
                }
                
                // Downsell Sheet - SAFE TRANSITION
                if showDownsell {
                    downsellSheetView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full coverage
            .ignoresSafeArea(.all, edges: .all) // Cover ALL edges to prevent black flickering
            .interactiveDismissDisabled(true)
        }
    }
    
    // ┌─────────────────────────────────────────────────┐
    // │         PAYWALL DESIGN SYSTEM TOKENS            │
    // │  One source of truth for ALL 3 paywall screens  │
    // └─────────────────────────────────────────────────┘
    
    // -- Spacing scale (4pt grid) --
    private enum PW {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        
        // Horizontal page margin
        static let hMargin: CGFloat = 24
        
        // Button
        static let btnHeight:  CGFloat = 56
        static let btnRadius:  CGFloat = 16
        static let btnFont:    CGFloat = 17
        static let btnBottom:  CGFloat = 48   // distance from safe-area bottom
        
        // Card
        static let cardRadius: CGFloat = 18
        static let cardPad:    CGFloat = 20
        
        // Fonts
        static let titleSize:      CGFloat = 26
        static let subtitleSize:    CGFloat = 15
        static let labelSize:       CGFloat = 14
        static let captionSize:     CGFloat = 13
        static let tagSize:         CGFloat = 12
    }
    
    // -- Gold CTA gradient (reused on every screen) --
    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [
                AppTheme.primaryLight,
                AppTheme.primary,
                AppTheme.primaryDark
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // -- Shared CTA button builder (with shine animation) --
    @ViewBuilder
    private func paywallCTA(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: PW.btnRadius)
                    .fill(goldGradient)
                
                // Subtle top highlight
                RoundedRectangle(cornerRadius: PW.btnRadius)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.clear],
                            startPoint: .top, endPoint: .center
                        )
                    )
                
                // Moving shine
                RoundedRectangle(cornerRadius: PW.btnRadius)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0), Color.white.opacity(0.35), Color.white.opacity(0)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .offset(x: shineOffset)
                    .mask(RoundedRectangle(cornerRadius: PW.btnRadius))
                
                Text(label)
                    .font(.system(size: PW.btnFont, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: PW.btnHeight)
        }
        .shadow(color: AppTheme.primary.opacity(0.35), radius: 16, y: 6)
        .padding(.horizontal, PW.hMargin)
    }
    
    // -- Shared card background (reused on results card + option cards) --
    private var glassCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PW.cardRadius)
                .fill(AppTheme.card)
            RoundedRectangle(cornerRadius: PW.cardRadius)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primary.opacity(0.08), AppTheme.primary.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: PW.cardRadius)
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.border.opacity(0.55), AppTheme.primary.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(0.045), radius: 14, y: 7)
    }
    
    // Responsive helpers (kept minimal — only used in pricingView ScrollView)
    private func isSmallDevice(_ geometry: GeometryProxy) -> Bool {
        geometry.size.height < 700
    }
    private func responsiveSpacing(_ base: CGFloat, geometry: GeometryProxy) -> CGFloat {
        let scale = geometry.size.height / 852
        return base * max(0.9, min(1.1, scale))
    }
    private func responsiveFontSize(_ base: CGFloat, geometry: GeometryProxy) -> CGFloat {
        let scale = geometry.size.height / 852
        return base * max(0.9, min(1.1, scale))
    }
    private func isLargeDevice(_ geometry: GeometryProxy) -> Bool {
        geometry.size.height > 900
    }
    
    // MARK: - Static Background Components (No Animations)
    
    // Static background - never animates, covers ALL edges
    private var staticBackground: some View {
        SDPageBackground()
        .ignoresSafeArea(.all, edges: .all) // Cover ALL edges including top and bottom
        .allowsHitTesting(false) // Don't interfere with touches
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full coverage
    }
    
    // Static glow - never animates, covers ALL edges
    private var staticGlow: some View {
        Group {
            let screenHeight = UIScreen.main.bounds.height
            let safeHeight = screenHeight > 0 ? screenHeight * 0.5 : 400
            RadialGradient(
                colors: [
                    AppTheme.primary.opacity(0.06),
                    AppTheme.primary.opacity(0.04),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: safeHeight
            )
        }
        .ignoresSafeArea(.all, edges: .all) // Cover ALL edges including top and bottom
        .allowsHitTesting(false) // Don't interfere with touches
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full coverage
    }
    
    // MARK: - Step 2: Plan Ready View
    
    /// Title, card, and pills — scrolls if taller than the middle slot; otherwise vertical slack is split evenly above/below via `planReadyView` spacers.
    @ViewBuilder
    private func planReadyMiddleSection(compact: Bool, titlePx: CGFloat, subtitlePx: CGFloat) -> some View {
        VStack(spacing: compact ? PW.md : PW.lg) {
            VStack(spacing: compact ? 8 : 10) {
                VStack(spacing: 6) {
                    Text(planReadyTitle)
                        .font(.system(size: titlePx, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(NSLocalizedString("paywall.personal_plan.ready", comment: "Is Ready"))
                        .font(.system(size: titlePx, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                        .lineLimit(2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primaryLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.horizontal, PW.hMargin)
                
                Text(planReadySubtitle)
                    .font(.system(size: subtitlePx, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .minimumScaleFactor(0.9)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, PW.hMargin)
            }
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : 14)
            .animation(.easeOut(duration: 0.45).delay(0.08), value: contentAppeared)
            // Extra air before “YOUR PREDICTED RESULTS” (on top of outer `VStack` spacing).
            .padding(.bottom, compact ? PW.md : PW.lg)
            
            VStack(spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                        Text(NSLocalizedString("paywall.predicted_results", comment: "YOUR PREDICTED RESULTS"))
                            .font(.system(size: PW.tagSize, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                            .tracking(0.6)
                            .multilineTextAlignment(.center)
                    }
                    Spacer(minLength: 0)
                }
                
                VStack(spacing: compact ? 10 : 12) {
                    planReadyBenefitRow(icon: "clock.arrow.circlepath", text: personalizedSaveHoursText)
                    planReadyBenefitRow(icon: "lock.open.fill", text: personalizedUnlockText)
                    planReadyBenefitRow(icon: "heart.fill", text: NSLocalizedString("paywall.result.closer_allah", comment: ""))
                    planReadyBenefitRow(icon: "chart.line.uptrend.xyaxis", text: NSLocalizedString("paywall.result.spiritual_habits", comment: ""))
                }
                .padding(.top, PW.md)
            }
            .padding(PW.cardPad)
            .background(planReadyCardBackground)
            .shadow(color: Color.black.opacity(0.2), radius: 18, y: 10)
            .padding(.horizontal, PW.hMargin)
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : 18)
            .animation(.easeOut(duration: 0.5).delay(0.22), value: contentAppeared)
            
            HStack(spacing: 0) {
                socialProofPill(icon: "person.2.fill", text: NSLocalizedString("paywall.social.muslims_count", comment: "10K+"))
                Spacer(minLength: 8)
                socialProofPill(icon: "star.fill", text: NSLocalizedString("paywall.rating", comment: "4.9"))
                Spacer(minLength: 8)
                socialProofPill(icon: "checkmark.shield.fill", text: NSLocalizedString("paywall.social.success_rate", comment: "95%"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, compact ? 10 : 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.cardSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
            .padding(.horizontal, PW.hMargin)
            .opacity(contentAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.38), value: contentAppeared)
        }
        .padding(.horizontal, PW.sm)
    }
    
    private func planReadyView(geometry: GeometryProxy) -> some View {
        let compact = isSmallDevice(geometry)
        let large = isLargeDevice(geometry)
        // Extra top breathing room so the seal sits slightly lower (not cramped under status bar / notch).
        let heroTopPad = responsiveSpacing(compact ? 50 : 62, geometry: geometry) + (large ? 20 : 0)
        let heroGlow: CGFloat = compact ? 168 : 200
        let heroRing: CGFloat = compact ? 92 : 104
        let heroIcon: CGFloat = compact ? 40 : 48
        let titlePx = min(30, responsiveFontSize(compact ? 25 : 27, geometry: geometry))
        let subtitlePx = responsiveFontSize(PW.subtitleSize, geometry: geometry)
        // Minimal gap under seal → first headline (icon still positioned by `heroTopPad` only).
        let heroBottomPad: CGFloat = 0
        let heroColumn = heroTopPad + heroGlow + heroBottomPad
        // Same vertical chrome as `reminderSelectionView`: paywallCTA height + `.padding(.bottom, PW.btnBottom)`.
        let bottomBarHeight = PW.btnHeight + PW.btnBottom
        let scrollSlotHeight = max(140, geometry.size.height - heroColumn - bottomBarHeight)
        let middleMinHeight = scrollSlotHeight
        /// Extra air between social pills row and gold CTA — larger than PW.xxl so it never visually “sticks”.
        let stackToButtonGap: CGFloat = compact ? PW.xxxl : (PW.xxxl + PW.md)
        
        return VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.06))
                    .frame(width: heroGlow, height: heroGlow)
                    .blur(radius: compact ? 34 : 40)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.42, blue: 0.28),
                                Color(red: 0.18, green: 0.52, blue: 0.36)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: heroRing, height: heroRing)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.primary.opacity(0.95), AppTheme.primary.opacity(0.45)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: AppTheme.primary.opacity(0.35), radius: 16, y: 8)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: heroIcon, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: AppTheme.primaryDark.opacity(0.22), radius: 4, y: 2)
            }
            .opacity(contentAppeared ? 1 : 0)
            .scaleEffect(contentAppeared ? 1 : 0.92)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: contentAppeared)
            .padding(.top, heroTopPad)
            .padding(.bottom, heroBottomPad)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Equal flex above & below → title + card + pills centered in the band between icon and button.
                    Spacer(minLength: 0)
                    planReadyMiddleSection(compact: compact, titlePx: titlePx, subtitlePx: subtitlePx)
                        .padding(.bottom, stackToButtonGap)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: middleMinHeight)
            }
            .frame(height: scrollSlotHeight)
            .frame(maxWidth: .infinity)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        // Pin CTA exactly like reminder: same `paywallCTA` + `.padding(.bottom, PW.btnBottom)` from the bottom edge.
        .overlay(alignment: .bottom) {
            paywallCTA(label: NSLocalizedString("paywall.plan_ready.cta", comment: "See my plan")) {
                HapticManager.shared.medium()
                contentAppeared = false
                // CRO: reminder step can be hidden (not deleted) via OnboardingFunnelConfig.
                if OnboardingFunnelConfig.hidePaywallReminderStep {
                    preparePricingEntryFromPlanReady()
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentStep = .pricing
                    }
                } else {
                    // Always show the reminder step after "plan ready".
                    // `hasActiveLocalTrial` must NOT skip it: a persisted trial from a previous session
                    // would hide this screen on repeat onboarding (UserDefaults trialExpiryDate).
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentStep = .reminder
                    }
                }
            }
            .opacity(contentAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.48), value: contentAppeared)
            .padding(.bottom, PW.btnBottom)
        }
        .transition(.opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                contentAppeared = true
            }
        }
    }
    
    /// Slightly richer glass card for “plan ready” (matches paywall tokens).
    private var planReadyCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PW.cardRadius)
                .fill(AppTheme.card)
            RoundedRectangle(cornerRadius: PW.cardRadius)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primary.opacity(0.06), AppTheme.primary.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: PW.cardRadius)
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.border, AppTheme.primary.opacity(0.25), AppTheme.border],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(0.05), radius: 14, y: 7)
    }
    
    @ViewBuilder
    private func planReadyBenefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primary.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: 40)
                .opacity(0.9)
            
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
            }
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.primary)
                .opacity(0.95)
        }
        .padding(.vertical, 6)
    }
    
    // -- Social proof pill (compact) --
    private func socialProofPill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(icon.hasPrefix("star") ? AppTheme.starYellow : AppTheme.primary)
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AppTheme.cardSecondary)
                .overlay(
                    Capsule().stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
    
    /// When the reminder step is hidden: start local trial (same as former reminder CTA) before pricing.
    private func preparePricingEntryFromPlanReady() {
        if subscriptionManager.canStartTrial {
            subscriptionManager.startFreeTrial(durationDays: 3)
        }
        if let expiry = subscriptionManager.trialExpiryDate {
            NotificationManager.shared.scheduleTrialExpiryNotification(expiresAt: expiry)
        }
    }
    
    // MARK: - Step 3: Reminder Selection View
    
    @State private var reminderAppeared = false
    @State private var selectedReminderOption: Int = 0 // 0 = 6h, 1 = 12h (voor weergave; permission-only flow)
    
    /// Matches `TrialReminderView`: show time relative to trial end (predict +3 days if trial not started yet).
    private var predictedTrialEndForReminderUI: Date {
        subscriptionManager.trialExpiryDate
            ?? Calendar.current.date(byAdding: .day, value: 3, to: Date())
            ?? Date()
    }
    
    private func reminderTimeString(hoursBefore: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: languageManager.currentLanguage)
        let date = predictedTrialEndForReminderUI.addingTimeInterval(Double(-hoursBefore) * 3600)
        return formatter.string(from: date)
    }
    
    private func scheduleTrialReminderAfterStartingLocalTrial(hoursBefore: Int) {
        guard let end = subscriptionManager.trialExpiryDate else { return }
        let reminderDate = end.addingTimeInterval(Double(-hoursBefore) * 3600)
        UserDefaults.standard.set(reminderDate, forKey: "trial_reminder_scheduled_date")
        UserDefaults.standard.set(hoursBefore, forKey: "trial_reminder_hours_before")
        NotificationManager.shared.scheduleTrialEndingReminder(on: reminderDate, hoursBefore: hoursBefore)
    }
    
    private func reminderSelectionView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                Text(NSLocalizedString("paywall.notifications.title", comment: "When should we remind you that you've achieved your results?"))
                    .font(.system(size: PW.titleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .lineLimit(4)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, PW.hMargin)
                    .opacity(reminderAppeared ? 1 : 0)
                    .offset(y: 20 + (reminderAppeared ? 0 : 12))
                    .animation(.easeOut(duration: 0.45).delay(0.1), value: reminderAppeared)
                
                Spacer().frame(height: PW.xxl)
                
                // Bell icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(colors: [AppTheme.primary.opacity(0.18), Color.clear], center: .center, startRadius: 0, endRadius: 150)
                        )
                        .frame(width: 280, height: 280)
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.75, green: 0.70, blue: 0.55), Color(red: 0.55, green: 0.50, blue: 0.40)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 180, height: 180)
                            .shadow(color: Color.black.opacity(0.4), radius: 22, y: 12)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 90, weight: .regular))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.85, green: 0.80, blue: 0.65), Color(red: 0.65, green: 0.60, blue: 0.50)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.90, green: 0.45, blue: 0.35), Color(red: 0.80, green: 0.35, blue: 0.30)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 42, height: 42)
                            .offset(x: 58, y: -52)
                            .shadow(color: Color(red: 0.90, green: 0.45, blue: 0.35).opacity(0.5), radius: 10, y: 4)
                    }
                }
                .scaleEffect(reminderAppeared ? 1.0 : 0.85)
                .opacity(reminderAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.2), value: reminderAppeared)
                
                Spacer().frame(height: PW.xxl)
                
                // Option cards (vorige versie: twee keuzes voor visuele structuur)
                VStack(spacing: PW.lg) {
                    VStack(spacing: PW.md) {
                        ReminderOptionButton(
                            title: NSLocalizedString("trial.reminder.6hours", comment: "6 hours before"),
                            subtitle: reminderTimeString(hoursBefore: 6),
                            isSelected: selectedReminderOption == 0,
                            onTap: {
                                HapticManager.shared.soft()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedReminderOption = 0 }
                            }
                        )
                        ReminderOptionButton(
                            title: NSLocalizedString("trial.reminder.12hours", comment: "12 hours before"),
                            subtitle: reminderTimeString(hoursBefore: 12),
                            isSelected: selectedReminderOption == 1,
                            onTap: {
                                HapticManager.shared.soft()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedReminderOption = 1 }
                            }
                        )
                    }
                    .padding(.horizontal, PW.hMargin)
                    
                    Text(NSLocalizedString("paywall.notifications.subtitle", comment: "Turn on notifications so we can keep you accountable and help you stay on track."))
                        .font(.system(size: PW.captionSize, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, PW.xxl)
                }
                .opacity(reminderAppeared ? 1 : 0)
                .offset(y: reminderAppeared ? 0 : 16)
                .animation(.easeOut(duration: 0.45).delay(0.35), value: reminderAppeared)
            }
            
            Spacer()
            
            paywallCTA(label: NSLocalizedString("paywall.notifications.continue_free", comment: "Continue for FREE")) {
                HapticManager.shared.heavy()
                reminderAppeared = false
                let hoursBefore = selectedReminderOption == 0 ? 6 : 12
                // Grant the trial only if it was never used before. An expired trial must NOT be
                // re-granted here, otherwise users could keep bypassing the paywall forever.
                if subscriptionManager.canStartTrial {
                    subscriptionManager.startFreeTrial(durationDays: 3)
                }
                NotificationManager.shared.requestPermission { granted in
                    if granted {
                        scheduleTrialReminderAfterStartingLocalTrial(hoursBefore: hoursBefore)
                    }
                    if let expiry = subscriptionManager.trialExpiryDate {
                        NotificationManager.shared.scheduleTrialExpiryNotification(expiresAt: expiry)
                    }
                    if granted && !subscriptionManager.hasPremiumAccess {
                        UserDefaults.standard.set(false, forKey: "reengagement_scheduled")
                        NotificationManager.shared.scheduleReengagementNotifications(includeImmediateKickoff: false)
                    }
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.4)) { currentStep = .pricing }
                    }
                }
            }
            .opacity(reminderAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.45), value: reminderAppeared)
            .padding(.bottom, PW.btnBottom)
        }
        // Same geometry box as `planReadyView` so the gold CTA lands on the same vertical position.
        .frame(width: geometry.size.width, height: geometry.size.height)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                reminderAppeared = true
            }
        }
    }
    
    @State private var pricingAppeared = false
    
    // MARK: - Step 4: Pricing View (Opal Style)
    
    private func pricingView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // ── Fixed Header (outside ScrollView for reliable taps) ──
            HStack {
                Button(action: {
                    HapticManager.shared.soft()
                    Task { await restoreAndReport() }
                }) {
                    Text(NSLocalizedString("paywall.restore", comment: "Restore"))
                        .font(.system(size: PW.subtitleSize, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
            .padding(.horizontal, PW.hMargin)
            .padding(.top, PW.xxxl)
            .zIndex(9999)
            .padding(.bottom, PW.md)
            
            // ── Scrollable top section (titellijn + iPhone mockup met custom image) ──
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer(minLength: PW.hMargin)
                        PaywallPhoneMockupView(
                            isYearlyTrialHeadline: selectedPricingOption == .yearly,
                            ctaDisclaimer: pricingCTAAboveDisclaimer
                        )
                        Spacer(minLength: PW.hMargin)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, PW.sm)
                    .opacity(pricingAppeared ? 1 : 0)
                    .offset(y: pricingAppeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: pricingAppeared)
                }
            }
            
            // ── Bottom pricing card (pinned) ──
            VStack(spacing: PW.lg) {
                // Pricing option cards
                pricingOptionsSection
                    .padding(.horizontal, PW.hMargin)
                
                // CTA button (same shared builder — identical to screen 1 & 2)
                Button(action: {
                    HapticManager.shared.heavy()
                    purchaseSelectedProduct()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: PW.btnRadius)
                            .fill(goldGradient)
                        RoundedRectangle(cornerRadius: PW.btnRadius)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0), Color.white.opacity(0.4), Color.white.opacity(0)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .offset(x: shineOffset)
                            .mask(RoundedRectangle(cornerRadius: PW.btnRadius))
                        HStack(spacing: 8) {
                            if isPurchasing {
                                SwiftUI.ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text(pricingPrimaryCTALabel)
                                    .font(.system(size: PW.btnFont, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                        }
                    }
                    .frame(height: PW.btnHeight)
                }
                .disabled(isPurchasing || selectedPackage == nil)
                .opacity(isPurchasing ? 0.7 : 1)
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 12, y: 4)
                .padding(.horizontal, PW.hMargin)
                
                // Combined disclaimer + Terms/Privacy (one text, Guideline 3.1.2)
                trialDisclaimerWithTermsFooter
                    .padding(.horizontal, PW.hMargin)
                    .padding(.top, 6)
            }
            .padding(.top, PW.xl)
            .padding(.bottom, PW.btnBottom)
            .frame(maxWidth: .infinity)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28)
                    .fill(AppTheme.card)
                    .overlay(
                        UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 18, y: -6)
            )
            .ignoresSafeArea(.container, edges: .bottom)
            .opacity(pricingAppeared ? 1 : 0)
            .offset(y: pricingAppeared ? 0 : 30)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: pricingAppeared)
        }
        .transition(.opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pricingAppeared = true
            }
        }
    }
    
    // MARK: - Plan Generation Loading View
    
    private func planGenerationLoadingView(geometry: GeometryProxy) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()
            
            // Hero: fixed square + explicit centering (avoids GeometryReader/ZStack leading bias & scale overflow)
            HStack(alignment: .center, spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .center) {
                    // Outer pulsing ring - SAFE ANIMATION (only visual, no layout)
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 3)
                        .frame(width: 160, height: 160)
                        .scaleEffect(loadingPulse ? 1.15 : 1.0)
                        .opacity(loadingPulse ? 0.3 : 0.6)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: loadingPulse)
                    
                    // Middle ring - SAFE ANIMATION (only visual, no layout)
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.3), lineWidth: 2)
                        .frame(width: 130, height: 130)
                        .scaleEffect(loadingPulse ? 1.1 : 1.0)
                        .opacity(loadingPulse ? 0.3 : 0.5)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: loadingPulse)
                    
                    // Inner gradient circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primary.opacity(0.2), AppTheme.primary.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    // Rotating arc (anchor at center of frame)
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(loadingPulse ? 360 : 0), anchor: .center)
                        .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: loadingPulse)
                    
                    // Center icon
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .frame(width: 200, height: 200)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .onAppear {
                loadingPulse = true
            }
            
            Spacer().frame(height: 40)
            
            // Title - FIXED FONT SIZE
            Text(NSLocalizedString("paywall.loading.title", comment: "Creating Your Plan"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            Spacer().frame(height: 12)
            
            // Subtitle - FIXED FONT SIZE
            Text(NSLocalizedString("paywall.loading.subtitle", comment: "Analyzing your answers..."))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            Spacer().frame(height: 48)
            
            // Progress steps - FIXED SPACING
            VStack(spacing: 20) {
                loadingStepRow(
                    icon: "person.fill.questionmark",
                    text: loadingStep1Text,
                    isComplete: showCheckmark1,
                    isActive: loadingStep >= 0
                )
                
                loadingStepRow(
                    icon: "brain.head.profile",
                    text: loadingStep2Text,
                    isComplete: showCheckmark2,
                    isActive: loadingStep >= 1
                )
                
                loadingStepRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: loadingStep3Text,
                    isComplete: showCheckmark3,
                    isActive: loadingStep >= 2
                )
            }
            .padding(.horizontal, 32)
            
            Spacer().frame(height: 48)
            
            // Progress bar - FIXED SPACING
            VStack(spacing: 12) {
                GeometryReader { progressGeometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(AppTheme.textMuted.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress fill - FIX: use progressGeometry instead of geometry
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: progressGeometry.size.width * loadingProgress, height: 8)
                            .animation(.easeOut(duration: 0.4), value: loadingProgress) // Smooth progress animation
                    }
                }
                .frame(height: 8)
                
                Text("\(Int(loadingProgress * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 48)
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fixed size to prevent movement
        .contentShape(Rectangle()) // Prevent layout shifts
    }
    
    private func loadingStepRow(icon: String, text: String, isComplete: Bool, isActive: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isComplete ? AppTheme.success.opacity(0.2) : (isActive ? AppTheme.primary.opacity(0.15) : AppTheme.textMuted.opacity(0.1)))
                    .frame(width: 44, height: 44)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.success)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isActive ? AppTheme.primary : AppTheme.textMuted.opacity(0.5))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isComplete)
            
            Text(text)
                .font(.system(size: 16, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? AppTheme.textPrimary : AppTheme.textMuted)
            
            Spacer()
            
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.success)
                    .scaleEffect(isComplete ? 1.0 : 0.5)
                    .opacity(isComplete ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isComplete)
            }
        }
    }
    
    private func startPlanGeneration() {
        // Reset states
        loadingProgress = 0
        loadingStep = 0
        showCheckmark1 = false
        showCheckmark2 = false
        showCheckmark3 = false
        
        // CRO: short loading (~2.5s) vs legacy theater (~9.2s). Legacy path kept intact.
        if OnboardingFunnelConfig.shortenPaywallLoading {
            startPlanGenerationShort()
        } else {
            startPlanGenerationLegacy()
        }
    }
    
    /// Short CRO loading — still shows the 3 checklist beats, compressed timing.
    private func startPlanGenerationShort() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.25)) { loadingProgress = 0.2 }
            HapticManager.shared.light()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showCheckmark1 = true
                loadingProgress = 0.4
                loadingStep = 1
            }
            HapticManager.shared.success()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showCheckmark2 = true
                loadingProgress = 0.7
                loadingStep = 2
            }
            HapticManager.shared.success()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showCheckmark3 = true
                loadingProgress = 1.0
            }
            HapticManager.shared.success()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            HapticManager.shared.heavy()
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .planReady
            }
        }
    }
    
    /// Legacy ~9.2s plan-generation theater (hidden when shortenPaywallLoading is true).
    private func startPlanGenerationLegacy() {
        // Step 1: Analyzing habits (~3 seconds) - SAFE ANIMATIONS (only visual)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                loadingProgress = 0.08
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                loadingProgress = 0.18
            }
            HapticManager.shared.light()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                loadingProgress = 0.28
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showCheckmark1 = true
                loadingProgress = 0.33
                loadingStep = 1
            }
            HapticManager.shared.success()
        }
        
        // Step 2: Calculating strategy (~3 seconds) - SAFE ANIMATIONS
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                loadingProgress = 0.45
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                loadingProgress = 0.55
            }
            HapticManager.shared.light()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                loadingProgress = 0.62
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showCheckmark2 = true
                loadingProgress = 0.66
                loadingStep = 2
            }
            HapticManager.shared.success()
        }
        
        // Step 3: Generating plan (~3 seconds) - SAFE ANIMATIONS
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                loadingProgress = 0.78
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                loadingProgress = 0.88
            }
            HapticManager.shared.light()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                loadingProgress = 0.95
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showCheckmark3 = true
                loadingProgress = 1.0
            }
            HapticManager.shared.success()
        }
        
        // Complete - show paywall - SAFE TRANSITION (opacity only, no layout)
        DispatchQueue.main.asyncAfter(deadline: .now() + 9.2) {
            HapticManager.shared.heavy()
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .planReady
            }
        }
    }
    
    // MARK: - Paywall Header
    
    private var paywallHeader: some View {
        HStack {
            // Restore button
            Button(action: {
                HapticManager.shared.soft()
                Task { await restoreAndReport() }
            }) {
                Text(NSLocalizedString("paywall.restore", comment: "Restore"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .zIndex(1000)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Pricing Options Section
    
    private var pricingOptionsSection: some View {
        VStack(spacing: 14) {
            // Yearly
            if let yearly = yearlyPackage {
                PricingOptionCard(
                    title: NSLocalizedString("paywall.pricing.trial_yearly_title", comment: "Free"),
                    subtitle: String(format: NSLocalizedString("paywall.pricing.trial_yearly_subtitle", comment: "then %@/year (%@/mo)"), yearly.storeProduct.localizedPriceString, formatPrice(yearlyMonthlyEquivalent)),
                    badge: NSLocalizedString("paywall.badge.most_popular", comment: "3 DAYS FREE"),
                    isSelected: selectedPricingOption == .yearly,
                    onTap: {
                        HapticManager.shared.medium()
                        selectedPricingOption = .yearly
                        selectedPackage = yearly
                    }
                )
            }
            
            // Monthly
            if let monthly = monthlyPackage {
                PricingOptionCard(
                    title: NSLocalizedString("paywall.pricing.monthly_trial", comment: "Monthly"),
                    subtitle: monthly.storeProduct.localizedPriceString + NSLocalizedString("paywall.pricing.per_month", comment: "/ month"),
                    isSelected: selectedPricingOption == .monthly,
                    onTap: {
                        HapticManager.shared.medium()
                        selectedPricingOption = .monthly
                        selectedPackage = monthly
                    }
                )
            }
            
            // Show loading state if no packages available
            if yearlyPackage == nil && monthlyPackage == nil {
                HStack {
                    SwiftUI.ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                    Text("Loading subscription options...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.vertical, 20)
            }
        }
    }
    
    // MARK: - Redeem Trial Button
    
    private var redeemTrialButton: some View {
        Button(action: {
            HapticManager.shared.heavy()
            purchaseSelectedProduct()
        }) {
            HStack(spacing: 8) {
                if isPurchasing {
                    SwiftUI.ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text(pricingPrimaryCTALabel)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // Golden gradient background - ScrollDeeds style
                    LinearGradient(
                        colors: [
                            AppTheme.primaryLight,
                            AppTheme.primary,
                            AppTheme.primaryDark
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Subtle shine overlay
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Shine animation
                    Rectangle()
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
                        .frame(width: 80)
                        .offset(x: shineOffset)
                        .blur(radius: 5)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .disabled(isPurchasing || selectedPackage == nil)
        .opacity(isPurchasing ? 0.7 : 1)
        .shadow(color: AppTheme.primary.opacity(0.5), radius: 20, y: 10)
        .shadow(color: AppTheme.primary.opacity(0.3), radius: 35, y: 20)
    }
    
    // Combined disclaimer + Terms/Privacy under CTA (one text, Guideline 3.1.2)
    @ViewBuilder
    private var trialDisclaimerWithTermsFooter: some View {
        if let attributed = trialDisclaimerWithTermsAttributedString {
            Text(attributed)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var trialDisclaimerWithTermsAttributedString: AttributedString? {
        let disclaimer: String
        if selectedPricingOption == .yearly, let yearly = yearlyPackage {
            disclaimer = String(format: NSLocalizedString("paywall.disclaimer.footer_yearly_trial", comment: ""),
                               yearly.storeProduct.localizedPriceString,
                               formatPrice(yearlyMonthlyEquivalent))
        } else if let monthly = monthlyPackage {
            disclaimer = String(format: NSLocalizedString("paywall.disclaimer.footer_monthly", comment: ""),
                               monthly.storeProduct.localizedPriceString)
        } else { return nil }
        let suffix = NSLocalizedString("paywall.disclaimer.agree_suffix", comment: "")
        let and = NSLocalizedString("common.and", comment: "and")
        let terms = NSLocalizedString("paywall.terms_eula", comment: "Terms of Use (EULA)")
        let privacy = NSLocalizedString("paywall.privacy", comment: "Privacy Policy")
        guard let termsURL = URL(string: "https://getnafsi.lovable.app/terms"),
              let privacyURL = URL(string: "https://getnafsi.lovable.app/privacy") else {
            return AttributedString(disclaimer + suffix + terms + " \(and) " + privacy + ".")
        }
        var s = AttributedString(disclaimer + suffix)
        var termsAttr = AttributedString(terms)
        termsAttr.link = termsURL
        s.append(termsAttr)
        s.append(AttributedString(" \(and) "))
        var privacyAttr = AttributedString(privacy)
        privacyAttr.link = privacyURL
        s.append(privacyAttr)
        s.append(AttributedString("."))
        return s
    }
    
    // Format zero price for "Redeem 3 days for %@" (user/product currency)
    private var formattedZeroPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearlyPackage?.storeProduct.priceFormatter?.locale ?? Locale.current
        return formatter.string(from: 0 as NSNumber) ?? "$0.00"
    }
    
    // MARK: - Social Proof Bar
    
    private var socialProofBar: some View {
        HStack(spacing: 0) {
            SocialItem(number: NSLocalizedString("paywall.social.muslims_count", comment: "10K+"), label: NSLocalizedString("common.muslims", comment: "Muslims"))
            
            Rectangle()
                .fill(AppTheme.border)
                .frame(width: 1, height: 36)
            
            SocialItem(number: NSLocalizedString("paywall.rating", comment: "4.9"), label: NSLocalizedString("paywall.rating_label", comment: "Rating"), icon: "star.fill")
            
            Rectangle()
                .fill(AppTheme.border)
                .frame(width: 1, height: 36)
            
            SocialItem(number: NSLocalizedString("paywall.social.success_rate", comment: "95%"), label: NSLocalizedString("paywall.social.success", comment: "Success"))
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardSecondary)
        )
    }
    
    // MARK: - Features List
    
    private var featuresList: some View {
        VStack(spacing: 12) {
            FeatureItem(icon: "lock.open.fill", text: NSLocalizedString("paywall.feature.unlock_dhikr", comment: "Unlock apps with dhikr"), isPrimary: true)
            FeatureItem(icon: "bell.badge.fill", text: NSLocalizedString("paywall.feature.reminders", comment: "Smart accountability reminders"), isPrimary: false)
            FeatureItem(icon: "chart.bar.fill", text: NSLocalizedString("paywall.feature.track_growth", comment: "Track your spiritual growth"), isPrimary: false)
            FeatureItem(icon: "infinity", text: NSLocalizedString("paywall.feature.unlimited", comment: "Unlimited dhikr sessions"), isPrimary: false)
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
                    Text(String(format: NSLocalizedString("paywall.price_anchoring", comment: "Pay %@ once, use for a full year"), yearly.storeProduct.localizedPriceString))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
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
            HStack(spacing: 12) {
                if isPurchasing {
                    SwiftUI.ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                    Text(NSLocalizedString("paywall.cta.start_premium", comment: "Start Premium Now"))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(selectedPackage == nil || isPurchasing)
    }
    
    // MARK: - Trust Badges
    
    private var trustBadges: some View {
        HStack(spacing: 24) {
            TrustItem(icon: "lock.shield.fill", text: NSLocalizedString("paywall.trust.secure", comment: "Secure"))
            TrustItem(icon: "arrow.clockwise", text: NSLocalizedString("paywall.trust.cancel_anytime", comment: "Cancel Anytime"))
            TrustItem(icon: "checkmark.seal.fill", text: NSLocalizedString("paywall.trust.no_ads", comment: "No Ads"))
        }
    }
    
    // MARK: - Downsell Sheet View (Opal Style)
    
    private var downsellSheetView: some View {
        VStack(spacing: 0) {
            // Semi-transparent overlay for top area
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        showDownsell = false
                    }
                }
            
            // Bottom sheet content
            VStack(spacing: 0) {

                // Drag indicator
                Capsule()
                    .fill(AppTheme.border)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                // Header: icon + title
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }

                    Text(NSLocalizedString("paywall.downsell.title", comment: "Not ready for a year?"))
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(NSLocalizedString("paywall.downsell.subtitle_prefix", comment: "We get it. Try a") + " " +
                         NSLocalizedString("paywall.downsell.weekly", comment: "weekly") + " " +
                         NSLocalizedString("paywall.downsell.subtitle_suffix", comment: "plan instead."))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 22)

                // Weekly plan card
                if let weekly = weeklyPackage {
                    HStack(spacing: 14) {
                        // Left: plan info
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(NSLocalizedString("paywall.downsell.weekly_plan", comment: "Weekly"))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text(NSLocalizedString("paywall.plan.flexible", comment: "Most Flexible"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.primary)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(AppTheme.primary.opacity(0.14))
                                    .clipShape(Capsule())
                            }
                            Text(NSLocalizedString("paywall.plan.cancel_anytime", comment: "Cancel anytime, no commitment"))
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                        }

                        Spacer()

                        // Right: price
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(weekly.storeProduct.localizedPriceString)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                            Text(NSLocalizedString("paywall.downsell.per_week", comment: "/ week"))
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                        }

                        // Checkmark
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 26, height: 26)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primary.opacity(0.12), AppTheme.primary.opacity(0.06)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.primary.opacity(0.5), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)
                }

                // CTA Button
                Button(action: {
                    HapticManager.shared.heavy()
                    if weeklyPackage != nil {
                        purchaseWeeklyProduct()
                    } else {
                        debugPrint("❌ Weekly package is nil, cannot purchase")
                        errorMessage = "Weekly package not available. Please check your internet connection and try again."
                        showError = true
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [
                                    AppTheme.primaryLight,
                                    AppTheme.primary,
                                    AppTheme.primaryDark
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [.clear, Color.white.opacity(0.35), .clear],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .offset(x: shineOffset)
                            .mask(RoundedRectangle(cornerRadius: 16))

                        if isPurchasing {
                            SwiftUI.ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(NSLocalizedString("paywall.downsell.cta", comment: "Start your journey"))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 52)
                }
                .disabled(isPurchasing)
                .opacity((isPurchasing || weeklyPackage == nil) ? 0.7 : 1)
                .shadow(color: AppTheme.primary.opacity(0.38), radius: 16, y: 7)
                .padding(.horizontal, 22)
                .padding(.bottom, 14)

                // No thanks
                Button(action: {
                    HapticManager.shared.soft()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        showDownsell = false
                    }
                }) {
                    Text(NSLocalizedString("paywall.downsell.no_thanks", comment: "No thanks"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.42)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 28,
                    bottomLeadingRadius: 28, // Natuurlijke hoeken
                    bottomTrailingRadius: 28,
                    topTrailingRadius: 28
                )
                .fill(AppTheme.card)
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28,
                        bottomLeadingRadius: 28,
                        bottomTrailingRadius: 28,
                        topTrailingRadius: 28
                    )
                    .stroke(AppTheme.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 24, y: -6)
            )
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleExitAttempt() {
        // Show downsell sheet (weekly offer pop-up) immediately on main thread
        DispatchQueue.main.async { [self] in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                showDownsell = true
            }
        }
        // Reload offerings in background so weekly package is available when sheet opens
        Task {
            await subscriptionManager.loadOfferings()
            debugPrint("📦 Offerings reloaded for downsell. Weekly package: \(weeklyPackage != nil ? "Found" : "Not found")")
        }
    }
    
    private func restoreAndReport() async {
        await subscriptionManager.restorePurchases()
        await MainActor.run {
            if subscriptionManager.hasPremiumAccess {
                onSubscribed()
            } else {
                errorMessage = NSLocalizedString("paywall.restore.none", comment: "")
                showError = true
            }
        }
    }

    private func purchaseWeeklyProduct() {
        guard let package = weeklyPackage else { return }
        
        isPurchasing = true
        
        let productId = package.storeProduct.productIdentifier
        
        // Track purchase attempt
        AnalyticsManager.shared.trackPurchaseAttempted(productId: productId, isYearly: false)
        
        Task {
            do {
                try await subscriptionManager.purchase(package)
                // Track success
                AnalyticsManager.shared.trackPurchaseCompleted(productId: productId, isYearly: false)
                await MainActor.run {
                    if subscriptionManager.hasPremiumAccess {
                        showThankYou = true
                    } else {
                        errorMessage = NSLocalizedString("paywall.purchase.no_access", comment: "")
                        showError = true
                    }
                }
            } catch {
                if case SubscriptionError.userCancelled = error {
                    // User cancelled
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
    
    private func purchaseSelectedProduct() {
        guard let package = selectedPackage else {
            debugPrint("❌ Cannot purchase: selectedPackage is nil")
            errorMessage = "Please select a subscription plan first."
            showError = true
            return
        }
        
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
                await MainActor.run {
                    if subscriptionManager.hasPremiumAccess {
                        showThankYou = true
                    } else {
                        errorMessage = NSLocalizedString("paywall.purchase.no_access", comment: "")
                        showError = true
                    }
                }
            } catch {
                if case SubscriptionError.userCancelled = error {
                    // User cancelled Apple Pay - show weekly downsell
                    AnalyticsManager.shared.trackPurchaseFailed(productId: productId, error: "user_cancelled")
                    await MainActor.run {
                        // Show weekly downsell when user cancels payment
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showDownsell = true
                        }
                    }
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
    
    private func formatPrice(_ price: Decimal, locale: Locale? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale ?? yearlyPackage?.storeProduct.priceFormatter?.locale ?? Locale.current
        return formatter.string(from: price as NSNumber) ?? "\(price)"
    }
}

// MARK: - Supporting Views

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
                        .foregroundColor(icon.hasPrefix("star") ? AppTheme.starYellow : AppTheme.primary)
                }
                Text(number)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(AppTheme.textPrimary)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
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
                    .fill(isPrimary ? AppTheme.primary.opacity(0.15) : AppTheme.textMuted.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isPrimary ? AppTheme.primary : AppTheme.textSecondary)
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textPrimary.opacity(0.9))
            
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
                .foregroundColor(AppTheme.textMuted)
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
                    Text(NSLocalizedString("paywall.yearly.banner", comment: "BEST VALUE • 3-DAY FREE TRIAL"))
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Content
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString("paywall.yearly.title", comment: "Yearly"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        HStack(spacing: 8) {
                            Text(package.storeProduct.localizedPriceString)
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text(NSLocalizedString("paywall.per_year", comment: "/year"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        
                        Text(String(format: NSLocalizedString("paywall.yearly.equivalent", comment: "Just %@/month"), monthlyEquivalent))
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
                                    .strokeBorder(AppTheme.textMuted.opacity(0.6), lineWidth: 2)
                                    .frame(width: 28, height: 28)
                            }
                        }
                        
                        // Trial badge (matches PricingOptionCard)
                        Text(NSLocalizedString("paywall.badge.most_popular", comment: "3 DAYS FREE"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.paywallTrialBadgeBackground)
                            .cornerRadius(6)
                    }
                }
                .padding(18)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isSelected
                            ? LinearGradient(colors: [AppTheme.primary, AppTheme.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [AppTheme.border], startPoint: .top, endPoint: .bottom),
                        lineWidth: isSelected ? 2.5 : 1
                    )		
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: isSelected ? AppTheme.primary.opacity(0.25) : Color.black.opacity(0.05), radius: 20, y: 10)
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
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("paywall.monthly.title", comment: "Monthly"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack(spacing: 6) {
                        Text(package.storeProduct.localizedPriceString)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(NSLocalizedString("paywall.per_month", comment: "/month"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
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
                            .strokeBorder(AppTheme.textMuted.opacity(0.5), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.textMuted.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isSelected ? AppTheme.primary : AppTheme.textMuted.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Pricing Option Card (Design System)

struct PricingOptionCard: View {
    let title: String
    let subtitle: String
    var badge: String? = nil
    let isSelected: Bool
    let onTap: () -> Void
    
    private let radius: CGFloat = 18
    private let checkSize: CGFloat = 26
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.primary : Color.clear)
                        .frame(width: checkSize, height: checkSize)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .strokeBorder(AppTheme.textMuted.opacity(0.5), lineWidth: 2)
                            .frame(width: checkSize, height: checkSize)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(AppTheme.card)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        LinearGradient(
                            colors: isSelected ? [AppTheme.primary, AppTheme.primaryLight] : [AppTheme.border, AppTheme.border],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .overlay(alignment: .topLeading) {
                if let badge = badge, !badge.isEmpty {
                    Text(badge)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(AppTheme.paywallTrialBadgeBackground))
                        .offset(x: 4, y: -14)
                }
            }
            .padding(.top, badge != nil && !(badge ?? "").isEmpty ? 10 : 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Reminder Option Button (Design System)

struct ReminderOptionButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private let radius: CGFloat = 18
    private let checkSize: CGFloat = 26
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.textMuted)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.primary : Color.clear)
                        .frame(width: checkSize, height: checkSize)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .strokeBorder(AppTheme.textMuted.opacity(0.5), lineWidth: 2)
                            .frame(width: checkSize, height: checkSize)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(AppTheme.card)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        LinearGradient(
                            colors: isSelected ? [AppTheme.primary.opacity(0.6), AppTheme.primary.opacity(0.3)] : [AppTheme.border, AppTheme.border],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HardPaywallView(onSubscribed: {})
}

