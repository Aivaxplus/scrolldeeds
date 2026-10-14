//
//  ConversionPaywallView.swift
//  scrolldeeds
//
//  Just Pray–framed conversion funnel in ScrollDeeds style:
//  promise + signature → sales scroll → A/B pricing (classic yearly/monthly sheet
//  with a 3-day free trial, or compact “program is ready” yearly/weekly with no trial).
//

import SwiftUI
import UIKit
import RevenueCat

struct ConversionPaywallView: View {
    /// Same screen, two audiences. `postTrial` is for people whose access already ran out:
    /// they signed the pledge once and used the free days, so the promise page, the free-days
    /// badge and the weekly downsell all drop away.
    enum Variant {
        case onboarding
        case postTrial

        var initialStep: Step { self == .onboarding ? .loading : .sales }
        var offersFreeDays: Bool { self == .onboarding }
        var offersWeekly: Bool { self == .onboarding }
        var isDismissible: Bool { self == .postTrial }
    }

    let variant: Variant
    /// Forces an A/B arm. Used by debug previews so Settings can open every combination
    /// without changing the user's real assignment.
    let experimentOverride: PaywallExperimentArm?
    let onClose: (() -> Void)?
    let onSubscribed: () -> Void

    init(
        variant: Variant = .onboarding,
        experimentOverride: PaywallExperimentArm? = nil,
        onClose: (() -> Void)? = nil,
        onSubscribed: @escaping () -> Void
    ) {
        self.variant = variant
        self.experimentOverride = experimentOverride
        self.onClose = onClose
        self.onSubscribed = onSubscribed
        _step = State(initialValue: variant.initialStep)
    }

    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var userDataManager = UserDataManager.shared
    @ObservedObject private var localStorage = LocalStorageManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var paywallExperiment = PaywallExperiment.shared
    @ObservedObject private var referralManager = ReferralManager.shared

    enum Step: Equatable {
        case loading
        case ease(Int)
        case promise
        case sales
        case pricing
    }

    enum PricingOption {
        case yearly
        case weekly
        case monthly
    }

    @State private var step: Step = .promise
    @State private var selectedPricing: PricingOption = .yearly
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDownsell = false
    @State private var showThankYou = false
    @State private var showPostAppSelection = false
    @State private var showPostGuideMuslims = false
    @State private var showPostDifficulty = false
    @State private var isRedeemExpanded = false
    @State private var redeemDraft = ""
    @State private var isApplyingRedeem = false
    @State private var offeringsLoaded = false

    // Signature
    @State private var strokes: [[CGPoint]] = []
    @State private var currentStroke: [CGPoint] = []
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var holdCompleted = false
    @State private var holdWorkItem: DispatchWorkItem?
    @State private var hapticTimer: Timer?
    @State private var holdArrowBounce = false
    @State private var holdBreath = false

    // Sales / pricing animation
    @State private var salesAppeared = false
    @State private var showSalesStickyCTA = false
    /// Soft dissolve before promise → pricing handoff.
    @State private var promiseExiting = false

    private let holdDuration: TimeInterval = 2.4
    /// How far the user must scroll before the sticky CTA pops in.
    private let salesStickyCTARevealOffset: CGFloat = 60

    // MARK: - Personalization

    private var displayName: String {
        let raw = userDataManager.userName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let raw, !raw.isEmpty { return raw }
        return NSLocalizedString("commitment.fallback_name", comment: "there")
    }

    private var hasRealName: Bool {
        let raw = userDataManager.userName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.map { !$0.isEmpty } ?? false
    }

    private var personalizedHours: Int {
        let hours = localStorage.onboardingScrollHours
        return hours > 0 ? hours : 3
    }

    private var unlockMinutes: Int {
        userDataManager.effectiveUnlockMinutesAfterDeed()
    }

    private var hasTrialUsage: Bool {
        userDataManager.totalSessions > 0
    }

    private var trialDeedCount: Int {
        max(0, userDataManager.totalSessions)
    }

    private var trialUnlockMinutes: Int {
        max(0, userDataManager.totalMinutes)
    }

    private var trialUnlockLabel: String {
        let minutes = trialUnlockMinutes
        if minutes >= 120 {
            return String(
                format: NSLocalizedString("conv_paywall.post_trial.hours", comment: "%d hours"),
                minutes / 60
            )
        }
        if minutes >= 60 {
            return NSLocalizedString("conv_paywall.post_trial.hour", comment: "1 hour")
        }
        return String(
            format: NSLocalizedString("conv_paywall.post_trial.minutes", comment: "%d min"),
            minutes
        )
    }

    private var hasSignature: Bool {
        strokes.contains { $0.count > 2 } || currentStroke.count > 2
    }

    private var transformationDateString: String {
        let date = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage)
        // MMMM = full month name. MMMMM is the narrow single letter ("N") — avoid that.
        formatter.setLocalizedDateFormatFromTemplate("ddMMMMyyyy")
        return formatter.string(from: date)
    }

    // MARK: - Experiment overlay (onboarding only)

    /// Post-trial stays on the classic yearly/monthly sheet. Onboarding follows the A/B arm.
    private var experimentArm: PaywallExperimentArm {
        if let experimentOverride { return experimentOverride }
        return variant == .onboarding ? paywallExperiment.arm : .classic
    }

    private var appliesExperimentPlans: Bool {
        variant == .onboarding || experimentOverride != nil
    }

    /// “Your 3 free days ended” is only true after the local trial actually expired.
    /// A lapsed subscription, or someone who never had those days, keeps the normal sales copy.
    private var showsEndedTrial: Bool {
        variant == .postTrial && subscriptionManager.hasTrialExpired
    }

    /// Classic “How we keep ScrollDeeds alive” sheet: 3-day trial, unless a referral discount is active.
    private var offersFreeDays: Bool {
        variant.offersFreeDays && experimentArm == .classic && !referralManager.hasActiveReferral
    }

    private var usesProgramReadyPaywall: Bool {
        appliesExperimentPlans && experimentArm == .programReady
    }

    private var offersWeekly: Bool { usesProgramReadyPaywall }

    private var offersMonthly: Bool {
        // Post-trial: yearly only (no-trial referral SKU). Monthly stays off the sheet.
        if variant == .postTrial { return false }
        if appliesExperimentPlans { return experimentArm == .classic }
        return true
    }

    /// Yearly price footnote: /month on classic + post-trial, /week on program-ready.
    private var yearlyDetailUsesMonth: Bool { !offersWeekly }

    /// Classic sheet: yearly + monthly, weekly as the payment-cancel downsell.
    /// Program-ready: yearly + weekly, monthly as the payment-cancel downsell.
    private var downsellsMonthly: Bool { offersWeekly }

    private var downsellsWeekly: Bool { offersMonthly }

    private var hasDownsellPlan: Bool { downsellPackage != nil }

    // MARK: - Packages

    /// Onboarding with free days → standard (trial) offering.
    /// Post-trial / referral → `referral_15` (yearly/monthly **without** intro offer).
    private var paywallOffering: Offering? {
        if variant == .postTrial {
            return subscriptionManager.referralPaywallOffering()
        }
        if referralManager.hasActiveReferral {
            return subscriptionManager.resolvedPaywallOffering()
        }
        if offersFreeDays {
            return subscriptionManager.standardPaywallOffering()
        }
        return subscriptionManager.referralPaywallOffering()
    }

    private var yearlyPackage: Package? {
        if variant == .postTrial {
            return packagePreferringNoTrial(kind: .yearly)
        }
        return firstYearly(in: paywallOffering)
            ?? firstYearly(in: subscriptionManager.standardPaywallOffering())
            ?? packageAcrossAllOfferings(kind: .yearly)
    }

    private var monthlyPackage: Package? {
        guard offersMonthly else { return nil }
        if variant == .postTrial {
            return packagePreferringNoTrial(kind: .monthly)
        }
        if offersFreeDays {
            // Trial paywall still shows a non-trial monthly as the alternate plan.
            return firstMonthly(in: subscriptionManager.referralPaywallOffering())
                ?? firstMonthly(in: paywallOffering)
                ?? packageAcrossAllOfferings(kind: .monthly)
        }
        return firstMonthly(in: paywallOffering)
            ?? packageAcrossAllOfferings(kind: .monthly)
    }

    private var weeklyPackage: Package? {
        guard offersWeekly else { return nil }
        return firstWeekly(in: subscriptionManager.standardPaywallOffering())
            ?? firstWeekly(in: paywallOffering)
            ?? packageAcrossAllOfferings(kind: .weekly)
    }

    /// Monthly without a trial — from `referral_15`, used as the trial-paywall downsell.
    private var downsellMonthlyPackage: Package? {
        firstMonthly(in: subscriptionManager.referralPaywallOffering())
            ?? firstMonthly(in: subscriptionManager.standardPaywallOffering())
            ?? packageAcrossAllOfferings(kind: .monthly)
    }

    /// Weekly from the default offering — used as the no-trial-paywall downsell.
    private var downsellWeeklyPackage: Package? {
        firstWeekly(in: subscriptionManager.standardPaywallOffering())
            ?? packageAcrossAllOfferings(kind: .weekly)
    }

    private enum PackageKind { case yearly, monthly, weekly }

    /// After the free trial, buy the referral/no-intro products so Apple does not
    /// try to attach another 3-day intro the user already used.
    private func packagePreferringNoTrial(kind: PackageKind) -> Package? {
        let referral = subscriptionManager.referralPaywallOffering()
        if let exact = firstMatching(kind: kind, in: referral, preferReferralProduct: true) {
            return exact
        }
        if let anyReferral = firstMatching(kind: kind, in: referral, preferReferralProduct: false) {
            return anyReferral
        }
        if let referralNamed = packageAcrossAllOfferings(kind: kind, preferReferralProduct: true) {
            return referralNamed
        }
        if let noIntro = packageAcrossAllOfferings(kind: kind, requireNoIntroOffer: true) {
            return noIntro
        }
        return packageAcrossAllOfferings(kind: kind)
            ?? firstMatching(kind: kind, in: subscriptionManager.standardPaywallOffering(), preferReferralProduct: false)
    }

    private func packageAcrossAllOfferings(
        kind: PackageKind,
        preferReferralProduct: Bool = false,
        requireNoIntroOffer: Bool = false
    ) -> Package? {
        guard let all = subscriptionManager.offerings?.all else { return nil }
        // Prefer the dedicated referral offering first when we want no-trial SKUs.
        let ordered = all.values.sorted { lhs, rhs in
            let lScore = lhs.identifier == "referral_15" || lhs.identifier.contains("referral") ? 0 : 1
            let rScore = rhs.identifier == "referral_15" || rhs.identifier.contains("referral") ? 0 : 1
            return lScore < rScore
        }
        for offering in ordered {
            if let pkg = firstMatching(
                kind: kind,
                in: offering,
                preferReferralProduct: preferReferralProduct,
                requireNoIntroOffer: requireNoIntroOffer
            ) {
                return pkg
            }
        }
        return nil
    }

    private func firstMatching(
        kind: PackageKind,
        in offering: Offering?,
        preferReferralProduct: Bool,
        requireNoIntroOffer: Bool = false
    ) -> Package? {
        guard let offering else { return nil }
        let matches = offering.availablePackages.filter { pkg in
            guard matchesKind(pkg, kind: kind) else { return false }
            if requireNoIntroOffer, pkg.storeProduct.introductoryDiscount != nil { return false }
            if preferReferralProduct {
                let id = pkg.storeProduct.productIdentifier.lowercased()
                let packageId = pkg.identifier.lowercased()
                return id.contains("referral") || packageId.contains("referral")
            }
            return true
        }
        return matches.first
    }

    private func matchesKind(_ pkg: Package, kind: PackageKind) -> Bool {
        switch kind {
        case .yearly: return isYearlyPackage(pkg)
        case .monthly: return isMonthlyPackage(pkg)
        case .weekly: return isWeeklyPackage(pkg)
        }
    }

    private func isYearlyPackage(_ pkg: Package) -> Bool {
        if pkg.packageType == .annual { return true }
        let id = pkg.storeProduct.productIdentifier.lowercased()
        let packageId = pkg.identifier.lowercased()
        return id.contains("yearly") || id.contains("annual")
            || packageId.contains("yearly") || packageId == "$rc_annual"
    }

    private func isMonthlyPackage(_ pkg: Package) -> Bool {
        if pkg.packageType == .monthly { return true }
        let id = pkg.storeProduct.productIdentifier.lowercased()
        let packageId = pkg.identifier.lowercased()
        return id.contains("monthly") || packageId.contains("monthly") || packageId == "$rc_monthly"
    }

    private func isWeeklyPackage(_ pkg: Package) -> Bool {
        if pkg.packageType == .weekly { return true }
        let id = pkg.storeProduct.productIdentifier.lowercased()
        let packageId = pkg.identifier.lowercased()
        return id.contains("weekly") || packageId.contains("weekly") || packageId == "$rc_weekly"
    }

    private func firstYearly(in offering: Offering?) -> Package? {
        firstMatching(kind: .yearly, in: offering, preferReferralProduct: false)
    }

    private func firstMonthly(in offering: Offering?) -> Package? {
        firstMatching(kind: .monthly, in: offering, preferReferralProduct: false)
    }

    private func firstWeekly(in offering: Offering?) -> Package? {
        firstMatching(kind: .weekly, in: offering, preferReferralProduct: false)
    }

    private var yearlyWeeklyEquivalent: Decimal {
        guard let yearly = yearlyPackage else { return Decimal(39.99) / 52 }
        return (yearly.storeProduct.price as Decimal) / 52
    }

    private var yearlyMonthlyEquivalent: Decimal {
        guard let yearly = yearlyPackage else { return Decimal(39.99) / 12 }
        return (yearly.storeProduct.price as Decimal) / 12
    }

    private var pricingCTALabel: String {
        switch selectedPricing {
        case .yearly:
            if offersFreeDays {
                return NSLocalizedString("conv_paywall.cta.bismillah_trial", comment: "Bismillah — Start 3 days free")
            }
            return NSLocalizedString("conv_paywall.cta.bismillah_yearly", comment: "Bismillah — Continue your journey")
        case .weekly:
            return NSLocalizedString("conv_paywall.cta.bismillah_weekly", comment: "Bismillah — Begin weekly")
        case .monthly:
            return NSLocalizedString("conv_paywall.cta.bismillah_monthly", comment: "Bismillah — Begin monthly")
        }
    }

    private var pricingAboveCTA: String {
        if offersFreeDays && selectedPricing == .yearly {
            return NSLocalizedString("paywall.pricing.cta_above.yearly", comment: "No Payment Due Now")
        }
        return NSLocalizedString("paywall.pricing.cta_above.monthly", comment: "No commitment - Cancel anytime")
    }

    // MARK: - Body

    var body: some View {
        Group {
            if showPostDifficulty {
                PostSubscribeDifficultyView(onContinue: { onSubscribed() })
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
                ZStack {
                    SDPageBackground()

                    RadialGradient(
                        colors: [
                            AppTheme.primary.opacity(0.10),
                            AppTheme.accent.opacity(0.04),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 0,
                        endRadius: 420
                    )
                    .ignoresSafeArea()

                    Group {
                        switch step {
                        case .loading:
                            PaywallPlanLoadingView {
                                withAnimation(.easeInOut(duration: 0.45)) {
                                    step = .promise
                                }
                            }
                            .transition(.opacity)
                        case .ease(let index):
                            easePage(index)
                                .transition(.opacity)
                        case .promise:
                            promiseStep
                                .transition(.asymmetric(
                                    insertion: .opacity,
                                    removal: .opacity
                                        .combined(with: .scale(scale: 1.04))
                                        .combined(with: .offset(y: -36))
                                ))
                        case .sales, .pricing:
                            salesStep
                                .transition(.asymmetric(
                                    insertion: .opacity
                                        .combined(with: .scale(scale: 0.96))
                                        .combined(with: .offset(y: 40)),
                                    removal: .opacity.combined(with: .offset(y: -12))
                                ))
                                .disabled(step == .pricing)
                        }
                    }
                    .animation(.easeInOut(duration: 0.4), value: step)

                    if step == .pricing {
                        Group {
                            if usesProgramReadyPaywall {
                                programReadyPaywall
                            } else {
                                pricingStep
                            }
                        }
                        .transition(
                            .asymmetric(
                                insertion: .opacity
                                    .combined(with: .offset(y: 56))
                                    .combined(with: .scale(scale: 0.985, anchor: .bottom)),
                                removal: .opacity.combined(with: .offset(y: 40))
                            )
                        )
                        .zIndex(3)
                    }

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
                        .zIndex(5)
                    }

                    if showDownsell {
                        downsellSheet
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .zIndex(4)
                    }

                    if isRedeemExpanded {
                        redeemCodePopup
                            .zIndex(6)
                    }
                }
                .interactiveDismissDisabled(true)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showThankYou)
        .animation(.easeInOut(duration: 0.35), value: showPostAppSelection)
        .animation(.easeInOut(duration: 0.35), value: showPostGuideMuslims)
        .animation(.easeInOut(duration: 0.35), value: showPostDifficulty)
        .onAppear {
            if experimentOverride == nil, variant == .onboarding {
                PaywallExperiment.shared.resolve()
            }
            if experimentOverride == nil {
                PostHogManager.shared.screen(
                    variant == .postTrial ? AnalyticsScreen.paywallPostTrial : AnalyticsScreen.paywall
                )
                PostHogManager.shared.trackPaywallViewed(
                    context: variant == .postTrial ? "post_trial" : "onboarding",
                    offeringIdentifier: paywallOffering?.identifier
                )
                AnalyticsManager.shared.trackHardPaywallShown()
            }
            loadOfferings()
        }
        .onDisappear {
            cancelHold()
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isRedeemExpanded)
    }

    private var redeemCodePopup: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .onTapGesture {
                    HapticManager.shared.soft()
                    isRedeemExpanded = false
                }

            RedeemCodeSheet(
                draft: $redeemDraft,
                isApplying: isApplyingRedeem,
                error: referralManager.validationError,
                onApply: applyRedeemCode,
                onClose: {
                    isRedeemExpanded = false
                }
            )
            .padding(.horizontal, 22)
            .padding(.top, 56)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    // MARK: - Ease-in pages (page 3 opens Apple Pay; cancel continues)

    private func easePage(_ index: Int) -> some View {
        let page3Trial = offersFreeDays
        func page3(_ suffix: String) -> String {
            let base = page3Trial ? "paywall.ease.page3" : "paywall.ease.page3.no_trial"
            return NSLocalizedString("\(base).\(suffix)", comment: "")
        }
        let titles = [
            NSLocalizedString("paywall.ease.page1.title", comment: ""),
            easePage2Title,
            page3("title")
        ]
        let kickers = [
            NSLocalizedString("paywall.ease.page1.kicker", comment: ""),
            NSLocalizedString("paywall.ease.page2.kicker", comment: ""),
            page3("kicker")
        ]
        let outcomeSets: [[PaywallEaseBenefit]] = [
            [
                PaywallEaseBenefit(
                    icon: "checkmark.circle.fill",
                    title: NSLocalizedString("paywall.ease.p1.lock.title", comment: ""),
                    body: NSLocalizedString("paywall.ease.p1.lock.body", comment: "")
                ),
                PaywallEaseBenefit(
                    icon: "checkmark.circle.fill",
                    title: NSLocalizedString("paywall.ease.p1.deed.title", comment: ""),
                    body: NSLocalizedString("paywall.ease.p1.deed.body", comment: "")
                ),
                 PaywallEaseBenefit(
                    icon: "checkmark.circle.fill",
                    title: NSLocalizedString("paywall.ease.p1.unlock.title", comment: ""),
                    body: NSLocalizedString("paywall.ease.p1.unlock.body", comment: "")
                )
            ],
            [
                PaywallEaseBenefit(
                    icon: "checkmark.circle.fill",
                    title: NSLocalizedString("paywall.ease.p2.lock.title", comment: ""),
                    body: NSLocalizedString("paywall.ease.p2.lock.body", comment: "")
                ),
                PaywallEaseBenefit(
                    icon: "checkmark.circle.fill",
                    title: NSLocalizedString("paywall.ease.p2.fajr.title", comment: ""),
                    body: NSLocalizedString("paywall.ease.p2.fajr.body", comment: "")
                ),
                PaywallEaseBenefit(
                    icon: "checkmark.circle.fill",
                    title: NSLocalizedString("paywall.ease.p2.dhikr.title", comment: ""),
                    body: NSLocalizedString("paywall.ease.p2.dhikr.body", comment: "")
                )
            ],
            [
                PaywallEaseBenefit(
                    icon: "checkmark.circle.fill",
                    title: page3("o1.title"),
                    body: page3("o1.body")
                ),
                PaywallEaseBenefit(
                    icon: "checkmark.circle.fill",
                    title: page3("o2.title"),
                    body: page3("o2.body")
                ),
                PaywallEaseBenefit(
                    icon: "checkmark.circle.fill",
                    title: page3("o3.title"),
                    body: page3("o3.body")
                )
            ]
        ]
        let images = ["PaywallEase1", "PaywallEase2", "PaywallEase3"]
        let safe = min(max(index, 0), 2)
        let trialYearly = safe == 2 ? easeTrialYearlyPackage : nil
        let yearlyPrice = trialYearly?.storeProduct.localizedPriceString ?? ""
        let monthlyEquivalent = trialYearly.map { ($0.storeProduct.price as Decimal) / 12 }
        let monthlyPrice = monthlyEquivalent.map { formatPrice($0) } ?? ""
        return PaywallEasePageView(
            kicker: kickers[safe],
            title: titles[safe],
            imageName: images[safe],
            outcomes: outcomeSets[safe],
            priceMonthly: safe == 2 && !monthlyPrice.isEmpty
                ? String(format: page3("price_monthly"), monthlyPrice)
                : nil,
            priceYearly: safe == 2 && !yearlyPrice.isEmpty
                ? String(format: page3("price_yearly"), yearlyPrice)
                : nil,
            trialNote: safe == 2 && page3Trial
                ? NSLocalizedString("paywall.ease.page3.trial", comment: "")
                : nil,
            ctaTitle: safe == 2
                ? page3("cta")
                : NSLocalizedString("paywall.ease.continue", comment: "Continue"),
            isPurchasing: safe == 2 && isPurchasing,
            onContinue: {
                if safe < 2 {
                    withAnimation(.easeInOut(duration: 0.38)) {
                        step = .ease(safe + 1)
                    }
                } else {
                    startYearlyTrialFromEase()
                }
            }
        )
    }

    private func advancePastEasePages() {
        withAnimation(.easeInOut(duration: 0.4)) {
            step = .sales
        }
    }

    /// Same yearly the paywall after these pages will sell: trial SKU, or the no-trial SKU.
    private var easeTrialYearlyPackage: Package? {
        if offersFreeDays {
            return firstYearly(in: subscriptionManager.standardPaywallOffering()) ?? yearlyPackage
        }
        return yearlyPackage
    }

    private func startYearlyTrialFromEase() {
        selectedPricing = .yearly
        if let yearly = easeTrialYearlyPackage {
            selectedPackage = yearly
            purchaseSelectedProduct(showDownsellOnCancel: false, onCancel: advancePastEasePages)
            return
        }
        isPurchasing = true
        Task { @MainActor in
            await subscriptionManager.loadOfferings()
            if let yearly = easeTrialYearlyPackage {
                selectedPackage = yearly
                purchaseSelectedProduct(showDownsellOnCancel: false, onCancel: advancePastEasePages)
            } else {
                isPurchasing = false
                advancePastEasePages()
            }
        }
    }

    private var easePage2Title: String {
        if hasRealName {
            return String(format: NSLocalizedString("paywall.ease.page2.title_named", comment: ""), displayName)
        }
        return NSLocalizedString("paywall.ease.page2.title", comment: "")
    }

    // MARK: - Step 1: Promise

    private var promiseStep: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer(minLength: 0)
                        PaywallNafsiPose(pose: "NafsiPoseOffer", height: 104)
                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, 12)

                    VStack(alignment: .leading, spacing: 14) {
                        Text(NSLocalizedString("conv_paywall.quote.source", comment: "The Prophet ﷺ said:"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primary)

                        highlightedQuote
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(NSLocalizedString("conv_paywall.quote.citation", comment: "Sahih Muslim (1907)"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(AppTheme.primary.opacity(0.08))
                    )

                    Spacer().frame(height: 28)

                    pledgeText
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer().frame(height: 22)

                    signaturePad(readOnly: false)
                        .frame(height: 168)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 28)
            }

            holdToLockButton
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
        .opacity(promiseExiting ? 0 : 1)
        .scaleEffect(promiseExiting ? 1.03 : 1, anchor: .center)
        .offset(y: promiseExiting ? -28 : 0)
        .allowsHitTesting(!promiseExiting)
        .onChange(of: hasSignature) { signed in
            if !signed { cancelHold() }
        }
    }

    private var highlightedQuote: Text {
        let full = NSLocalizedString(
            "conv_paywall.quote.body",
            comment: "Take account of yourselves before you are taken to account."
        )
        let highlight = NSLocalizedString("conv_paywall.quote.highlight", comment: "account")
        return highlightedText(full, highlight: highlight, base: AppTheme.textPrimary, accent: AppTheme.primary)
    }

    private var pledgeText: Text {
        let name = hasRealName ? displayName : NSLocalizedString("commitment.fallback_name", comment: "there")
        let template = NSLocalizedString(
            "conv_paywall.pledge",
            comment: "I, %@, promise to do everything in my power to turn scrolling into good deeds for Allah."
        )
        let full = String(format: template, name)
        let nameToken = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let sacred = [
            NSLocalizedString("conv_paywall.pledge.highlight", comment: "Allah"),
            NSLocalizedString("conv_paywall.pledge.highlight2", comment: "")
        ]
        var text = Text("")
        let parts = splitHighlighting(
            full,
            tokens: sacred,
            firstOccurrenceToken: nameToken.count >= 2 ? nameToken : nil
        )
        for part in parts {
            if part.isHighlight {
                text = text + Text(part.value).foregroundColor(AppTheme.primary).fontWeight(.bold)
            } else {
                text = text + Text(part.value).foregroundColor(AppTheme.textPrimary)
            }
        }
        return text
    }

    private func signaturePad(readOnly: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.border.opacity(0.8), lineWidth: 1)
                )

            if !hasSignature && !readOnly {
                VStack(spacing: 10) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                    Text(NSLocalizedString("conv_paywall.signature.hint", comment: "Draw your signature"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                }
            }

            Canvas { context, _ in
                for stroke in strokes {
                    drawStroke(stroke, in: &context)
                }
                if !currentStroke.isEmpty {
                    drawStroke(currentStroke, in: &context)
                }
            }
            .allowsHitTesting(!readOnly)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !readOnly else { return }
                        currentStroke.append(value.location)
                    }
                    .onEnded { _ in
                        guard !readOnly else { return }
                        if currentStroke.count > 1 {
                            strokes.append(currentStroke)
                        }
                        currentStroke = []
                    }
            )

            if hasSignature && !readOnly {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            HapticManager.shared.soft()
                            strokes = []
                            currentStroke = []
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(10)
                                .background(Circle().fill(AppTheme.muted.opacity(0.9)))
                        }
                        .padding(12)
                    }
                }
            }
        }
    }

    private func drawStroke(_ points: [CGPoint], in context: inout GraphicsContext) {
        guard points.count > 1 else { return }
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        context.stroke(
            path,
            with: .color(AppTheme.textPrimary),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }

    private var holdToLockButton: some View {
        VStack(spacing: 8) {
            if hasSignature || isHolding || holdCompleted {
                signedHoldControl
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.86).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            } else {
                Text(NSLocalizedString("conv_paywall.hold.sign_first", comment: "Sign your name first"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.48, dampingFraction: 0.82), value: hasSignature)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                holdArrowBounce = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                holdBreath = true
            }
        }
    }

    private var signedHoldControl: some View {
        let enabled = hasSignature && !holdCompleted
        return VStack(spacing: 6) {
            Image(systemName: "arrow.down")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.primary)
                .offset(y: holdArrowBounce ? 5 : 0)
                .opacity(isHolding ? 0.35 : 1)

            Text(NSLocalizedString("conv_paywall.hold.instruction", comment: "Press and hold"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primary)
            Text(NSLocalizedString("conv_paywall.hold.instruction.sub", comment: "to lock in your promise"))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)

            fingerprintHoldButton
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(
            NSLocalizedString("conv_paywall.hold.instruction", comment: "Press and hold")
            + " "
            + NSLocalizedString("conv_paywall.hold.instruction.sub", comment: "to lock in your promise")
        )
        .allowsHitTesting(enabled)
    }

    private var fingerprintHoldButton: some View {
        let size: CGFloat = 84
        let ring = size + 18
        return ZStack {
            // Progress only while holding — no idle track/kader behind the button.
            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(
                    AppTheme.primary,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: ring, height: ring)
                .rotationEffect(.degrees(-90))
                .opacity(holdProgress > 0 ? 1 : 0)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: AppTheme.primary.opacity(isHolding ? 0.45 : 0.22), radius: isHolding ? 14 : 8, y: 4)
                .scaleEffect((holdBreath ? 1.04 : 1.0) * (isHolding ? 0.94 : 1.0))

            Image(systemName: "touchid")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.white)
                .accessibilityHidden(true)
        }
        .frame(width: size + 36, height: size + 36)
        .contentShape(Circle())
        .onLongPressGesture(
            minimumDuration: holdDuration,
            pressing: { pressing in
                guard hasSignature, !holdCompleted else { return }
                if pressing {
                    if !isHolding { startHold() }
                } else if isHolding && !holdCompleted {
                    cancelHold()
                }
            },
            perform: {}
        )
    }

    private func startHold() {
        guard hasSignature, !holdCompleted, !isHolding else { return }
        isHolding = true
        holdProgress = 0
        HapticManager.shared.light()

        withAnimation(.linear(duration: holdDuration)) {
            holdProgress = 1
        }

        var count = 0
        hapticTimer?.invalidate()
        func tick() {
            guard isHolding, !holdCompleted else { return }
            count += 1
            let intensity = min(1.0, 0.45 + Double(count) * 0.04)
            let style: UIImpactFeedbackGenerator.FeedbackStyle = intensity < 0.7 ? .light : .medium
            let gen = UIImpactFeedbackGenerator(style: style)
            gen.impactOccurred(intensity: CGFloat(intensity))
            hapticTimer = Timer.scheduledTimer(withTimeInterval: max(0.06, 0.28 - Double(count) * 0.02), repeats: false) { _ in
                DispatchQueue.main.async { tick() }
            }
            if let hapticTimer {
                RunLoop.main.add(hapticTimer, forMode: .common)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { tick() }

        holdWorkItem?.cancel()
        let work = DispatchWorkItem {
            guard isHolding, !holdCompleted else { return }
            completeHold()
        }
        holdWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration, execute: work)
    }

    private func cancelHold() {
        isHolding = false
        holdWorkItem?.cancel()
        holdWorkItem = nil
        hapticTimer?.invalidate()
        hapticTimer = nil
        withAnimation(.easeOut(duration: 0.25)) {
            holdProgress = 0
        }
    }

    private func completeHold() {
        guard !holdCompleted else { return }
        holdCompleted = true
        isHolding = false
        holdWorkItem?.cancel()
        hapticTimer?.invalidate()
        hapticTimer = nil
        HapticManager.shared.success()
        withAnimation(.easeOut(duration: 0.2)) { holdProgress = 1 }

        // 1) Soft dissolve of the commitment page
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.easeInOut(duration: 0.48)) {
                promiseExiting = true
            }
            HapticManager.shared.soft()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                withAnimation(.spring(response: 0.82, dampingFraction: 0.86)) {
                    step = .ease(0)
                }
                HapticManager.shared.medium()
            }
        }
    }

    private func resetPromiseForSignature() {
        holdWorkItem?.cancel()
        hapticTimer?.invalidate()
        hapticTimer = nil
        strokes = []
        currentStroke = []
        holdProgress = 0
        isHolding = false
        holdCompleted = false
        promiseExiting = false
    }

    // MARK: - Sales palette (ScrollDeeds — distinct bands, not Unrot lime/blue)

    private var salesBandMint: Color { AppTheme.primary.opacity(0.10) }
    private var salesBandWarm: Color { AppTheme.accent.opacity(0.10) }
    private var salesBandForest: Color { AppTheme.primaryDark.opacity(0.92) }

    private var cardTintSage: Color { AppTheme.primary.opacity(0.12) }
    private var cardTintSand: Color { AppTheme.accent.opacity(0.14) }
    private var cardTintRose: Color { Color(red: 0.78, green: 0.42, blue: 0.40).opacity(0.14) }
    private var cardTintSky: Color { Color(red: 0.30, green: 0.52, blue: 0.62).opacity(0.14) }

    // MARK: - Step 2: Sales

    private var salesStep: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top anchor — more reliable than GeometryReader on the full content stack.
                    Color.clear
                        .frame(height: 0)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: SalesScrollOffsetKey.self,
                                    value: -geo.frame(in: .named("salesScroll")).minY
                                )
                            }
                        )

                    salesHeroSection
                    salesSideBuddy(pose: "NafsiPoseStand", side: .trailing)
                        .background(AppTheme.background)
                    salesHowItWorksSection
                    salesSideBuddy(pose: "NafsiPoseSit", side: .leading)
                        .background(salesBandMint)
                    salesFeaturesSection
                    salesSideBuddy(pose: "NafsiPoseOffer", side: .trailing)
                        .background(AppTheme.background)
                    salesSocialSection
                    salesCloseSection
                    salesFAQSection
                    Color.clear.frame(height: showSalesStickyCTA ? 110 : 36)
                }
                .opacity(salesAppeared ? 1 : 0)
                .offset(y: salesAppeared ? 0 : 14)
            }
            .coordinateSpace(name: "salesScroll")
            .modifier(
                SalesStickyCTAScrollTracker(threshold: salesStickyCTARevealOffset) { shouldShow in
                    updateSalesStickyCTA(shouldShow)
                }
            )

            stickyCTA
                .offset(y: showSalesStickyCTA ? 0 : 110)
                .opacity(showSalesStickyCTA ? 1 : 0)
                .scaleEffect(showSalesStickyCTA ? 1 : 0.97, anchor: .bottom)
                .allowsHitTesting(showSalesStickyCTA)
                .accessibilityHidden(!showSalesStickyCTA)
        }
        .overlay(alignment: .topTrailing) {
            // Onboarding is a mandatory gate; reached from the dashboard it must have a way back.
            if onClose != nil {
                PaywallCloseButton(
                    iconColor: UIColor(AppTheme.textMuted),
                    backgroundColor: UIColor(AppTheme.card),
                    action: { onClose?() }
                )
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .padding(.top, 8)
                .padding(.trailing, 18)
            }
        }
        .onAppear {
            showSalesStickyCTA = false
            withAnimation(.easeOut(duration: 0.45)) { salesAppeared = true }
        }
    }

    private func updateSalesStickyCTA(_ shouldShow: Bool) {
        guard shouldShow != showSalesStickyCTA else { return }
        withAnimation(.spring(response: 0.62, dampingFraction: 0.92)) {
            showSalesStickyCTA = shouldShow
        }
        if shouldShow {
            HapticManager.shared.soft()
        }
    }

    /// One clear hook — room to breathe, single visual.
    private var salesHeroSection: some View {
        let mockupVerticalGap: CGFloat = 32

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                highlightedHeadline(
                    showsEndedTrial
                        ? NSLocalizedString("conv_paywall.post_trial.hero.title", comment: "Your 3 free days just ended.")
                        : NSLocalizedString("conv_paywall.hero.title", comment: "Lock your apps until you do a good deed."),
                    highlight: showsEndedTrial
                        ? NSLocalizedString("conv_paywall.post_trial.hero.title.highlight", comment: "3 free days")
                        : NSLocalizedString("conv_paywall.hero.title.highlight", comment: "Lock")
                )
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

                heroSubtitleWithHighlightedHours
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            salesHeroDemoMockup
                .padding(.top, mockupVerticalGap)
                .padding(.bottom, mockupVerticalGap)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(AppTheme.background)
    }

    /// Subtitle with “X hours” / “X uur” in brand green.
    private var heroSubtitleWithHighlightedHours: Text {
        if showsEndedTrial {
            return postTrialHeroSubtitle
        }
        let hoursPhrase = String(
            format: NSLocalizedString("conv_paywall.hero.hours", comment: "%d hours"),
            personalizedHours
        )
        let full = String(
            format: NSLocalizedString(
                "conv_paywall.hero.subtitle",
                comment: "Your phone steals about %d hours a day. We pause it until you earn access with a good deed."
            ),
            personalizedHours
        )
        return highlightedText(
            full,
            highlight: hoursPhrase,
            base: AppTheme.textSecondary,
            accent: AppTheme.primary
        )
    }

    private var postTrialHeroSubtitle: Text {
        if hasTrialUsage {
            let deedsPhrase = String(
                format: NSLocalizedString("conv_paywall.post_trial.hero.deeds", comment: "%d good deeds"),
                trialDeedCount
            )
            let full = String(
                format: NSLocalizedString(
                    "conv_paywall.post_trial.hero.subtitle_used",
                    comment: "In those 3 days you completed %d good deeds. Don’t give that back to the scroll."
                ),
                trialDeedCount
            )
            return highlightedText(
                full,
                highlight: deedsPhrase,
                base: AppTheme.textSecondary,
                accent: AppTheme.primary
            )
        }
        let trialPhrase = NSLocalizedString(
            "conv_paywall.post_trial.hero.title.highlight",
            comment: "3 free days"
        )
        let full = NSLocalizedString(
            "conv_paywall.post_trial.hero.subtitle_fresh",
            comment: "Those 3 free days were meant to show you more good deeds and fewer empty hours of scrolling. Keep the loop."
        )
        return highlightedText(
            full,
            highlight: trialPhrase,
            base: AppTheme.textSecondary,
            accent: AppTheme.primary
        )
    }

    /// Small companion in the scroll flow (sides), not an overlay — appears as you read down.
    private enum SalesBuddySide {
        case leading, trailing
    }

    private func salesSideBuddy(pose: String, side: SalesBuddySide) -> some View {
        HStack(spacing: 0) {
            if side == .leading {
                PaywallNafsiPose(pose: pose, height: 52)
                    .padding(.leading, 10)
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                PaywallNafsiPose(pose: pose, height: 52)
                    .padding(.trailing, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Same looping Get Started demo, scaled down for the sales hero.
    private var salesHeroDemoMockup: some View {
        let scale: CGFloat = 0.58
        return iPhoneMockupView { OnboardingDemoVideoView() }
            .scaleEffect(scale)
            .frame(width: 280 * scale, height: 568 * scale)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(NSLocalizedString("onboarding.demo_placeholder", comment: "How it works"))
    }

    /// 3 big numbered path cards — no dense icon list.
    private var salesHowItWorksSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("conv_paywall.how.eyebrow", comment: "HOW IT WORKS"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.primary)

                highlightedHeadline(
                    NSLocalizedString("conv_paywall.ecosystem.title", comment: "Our system in 3 steps"),
                    highlight: NSLocalizedString("conv_paywall.ecosystem.title.highlight", comment: "3 steps")
                )
                .font(.system(size: 24, weight: .bold, design: .rounded))

                Text(NSLocalizedString(
                    "conv_paywall.ecosystem.subtitle",
                    comment: "Lock apps. Do a good deed. Buy a heart."
                ))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 14) {
                pathCard(
                    step: "1",
                    icon: "shield.fill",
                    tint: cardTintSage,
                    accent: AppTheme.primary,
                    title: NSLocalizedString("conv_paywall.mech.lock.title", comment: "Lock your distracting apps"),
                    body: NSLocalizedString("conv_paywall.mech.lock.body", comment: "Pick what to block. They stay locked.")
                )
                pathCard(
                    step: "2",
                    icon: "hands.sparkles.fill",
                    tint: cardTintSand,
                    accent: AppTheme.accent,
                    title: NSLocalizedString("conv_paywall.mech.deed.title", comment: "Do a good deed"),
                    body: NSLocalizedString("conv_paywall.mech.deed.body", comment: "Finish dhikr or a short deed task.")
                )
                pathCard(
                    step: "3",
                    icon: "timer",
                    tint: cardTintSky,
                    accent: Color(red: 0.28, green: 0.50, blue: 0.58),
                    title: NSLocalizedString("conv_paywall.mech.time.title", comment: "Unlock your apps for 30 minutes"),
                    body: NSLocalizedString("conv_paywall.mech.time.body", comment: "Then your apps lock again.")
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(salesBandMint)
    }

    private func pathCard(
        step: String,
        icon: String,
        tint: Color,
        accent: Color,
        title: String,
        body: String
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint)
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: NSLocalizedString("conv_paywall.how.step", comment: "Step %@"), step))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)
                    .fixedSize(horizontal: false, vertical: true)
                Text(body)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
        )
    }

    /// Feature grid — 2 columns, tinted cards, no wall of text.
    private var salesFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            highlightedText(
                NSLocalizedString("conv_paywall.features.header", comment: "Everything you need to\\nbecome a powerful Muslim"),
                highlight: NSLocalizedString("conv_paywall.features.header.highlight", comment: "powerful Muslim"),
                base: AppTheme.textPrimary,
                accent: AppTheme.primary
            )
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                featureTile(
                    icon: "lock.shield.fill",
                    tint: cardTintSage,
                    accent: AppTheme.primary,
                    title: NSLocalizedString("conv_paywall.feature.lock.title", comment: "App locking"),
                    body: NSLocalizedString("conv_paywall.feature.lock.body", comment: "Block doomscroll apps until you complete a good deed.")
                )
                featureTile(
                    icon: "moon.stars.fill",
                    tint: cardTintSky,
                    accent: Color(red: 0.28, green: 0.50, blue: 0.58),
                    title: NSLocalizedString("conv_paywall.feature.dhikr.title", comment: "Dhikr & deeds"),
                    body: NSLocalizedString("conv_paywall.feature.dhikr.body", comment: "Turn every unlock into worship and progress.")
                )
                featureTile(
                    icon: "flame.fill",
                    tint: cardTintSand,
                    accent: AppTheme.accent,
                    title: NSLocalizedString("conv_paywall.feature.streaks.title", comment: "Streaks"),
                    body: NSLocalizedString("conv_paywall.feature.streaks.body", comment: "Day by day, grow your streak and keep it alive.")
                )
                featureTile(
                    icon: "bell.badge.fill",
                    tint: cardTintRose,
                    accent: Color(red: 0.72, green: 0.38, blue: 0.36),
                    title: NSLocalizedString("conv_paywall.feature.reminders.title", comment: "Accountability reminders"),
                    body: NSLocalizedString("conv_paywall.feature.reminders.body", comment: "Gentle nudges so you don’t slip back into endless scrolling.")
                )
                featureTile(
                    icon: "chart.line.uptrend.xyaxis",
                    tint: cardTintSage,
                    accent: AppTheme.primaryDark,
                    title: NSLocalizedString("conv_paywall.feature.progress.title", comment: "Spiritual progress"),
                    body: NSLocalizedString("conv_paywall.feature.progress.body", comment: "See your sessions, streaks, and reclaiming of time.")
                )
                featureTile(
                    icon: "heart.fill",
                    tint: cardTintRose,
                    accent: Color(red: 0.72, green: 0.38, blue: 0.36),
                    title: NSLocalizedString("conv_paywall.feature.heart.title", comment: "Heart health"),
                    body: NSLocalizedString("conv_paywall.feature.heart.body", comment: "Feel your heart get lighter as deeds replace doomscrolling.")
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.background)
    }

    private func featureTile(
        icon: String,
        tint: Color,
        accent: Color,
        title: String,
        body: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(accent)
            }
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
            Text(body)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(4)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.border.opacity(0.7), lineWidth: 1)
                )
        )
        // Equal width from the grid + same aspect → all 6 tiles match, tighter around copy.
        .aspectRatio(1.02, contentMode: .fit)
    }

    /// Social proof on a distinct forest band — white cards pop.
    private var salesSocialSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("conv_paywall.social.title", comment: "Stories from Muslims like you"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(AppTheme.starYellow)
                        .font(.system(size: 14))
                }
                Text(NSLocalizedString("paywall.rating", comment: "4.9"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text(NSLocalizedString("conv_paywall.social.based_on", comment: "Based on reviews from Muslims reclaiming their time"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.78))

            VStack(spacing: 14) {
                stackedReviewCard(
                    title: NSLocalizedString("conv_paywall.review1.title", comment: "Perfect"),
                    body: NSLocalizedString(
                        "conv_paywall.review1.body",
                        comment: "I recently upgraded to premium version and it’s been a gamechanger."
                    ),
                    author: "Sidi9111",
                    flag: "🇧🇪"
                )
                stackedReviewCard(
                    title: NSLocalizedString("conv_paywall.review2.title", comment: "I love this idea"),
                    body: NSLocalizedString(
                        "conv_paywall.review2.body",
                        comment: "When I heard the ad about this I immediately got so hooked."
                    ),
                    author: "Yasir Amer22",
                    flag: "🇺🇸"
                )
                stackedReviewCard(
                    title: NSLocalizedString("conv_paywall.review3.title", comment: "Mr"),
                    body: NSLocalizedString(
                        "conv_paywall.review3.body",
                        comment: "A good reminder"
                    ),
                    author: "Abdulrahman20",
                    flag: "🇬🇧"
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(salesBandForest)
    }

    private func stackedReviewCard(title: String, body: String, author: String, flag: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.starYellow)
                }
            }
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            Text(body)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Text(flag)
                    .font(.system(size: 14))
                Text(author)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
        )
    }

    private var salesCloseSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if showsEndedTrial {
                Text(hasRealName
                    ? String(
                        format: NSLocalizedString(
                            "conv_paywall.post_trial.close.title_named",
                            comment: "%@, don’t go back to the old hours."
                        ),
                        displayName
                    )
                    : NSLocalizedString(
                        "conv_paywall.post_trial.close.title",
                        comment: "Don’t go back to the old hours."
                    )
                )
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            } else if hasRealName {
                Text(String(
                    format: NSLocalizedString("conv_paywall.close.title_named", comment: "%@, it’s finally time to turn scrolling into deeds."),
                    displayName
                ))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(NSLocalizedString("conv_paywall.close.title", comment: "It’s finally time to turn scrolling into deeds."))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(NSLocalizedString(
                showsEndedTrial
                    ? "conv_paywall.post_trial.close.subtitle"
                    : "conv_paywall.close.subtitle",
                comment: showsEndedTrial
                    ? "The 3 days already showed you the loop works. Continue now — or tonight looks like before the trial."
                    : "Insha’Allah if you stick to your commitment, your life will feel transformed by"
            ))
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppTheme.textSecondary)

            if !showsEndedTrial {
                Text(transformationDateString)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(AppTheme.primary))
            }

            if hasSignature {
                signaturePad(readOnly: true)
                    .frame(height: 168)
                    .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(salesBandWarm)
    }

    private var salesFAQSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(NSLocalizedString("conv_paywall.faq.header", comment: "Most common questions"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)

            VStack(spacing: 12) {
                faqCard(
                    q: NSLocalizedString("conv_paywall.faq.q1", comment: "Does this actually work?"),
                    a: NSLocalizedString("conv_paywall.faq.a1", comment: "Yes. Real iOS locking forces the pause — then a good deed unlocks your apps. That loop is what rewires the habit, insha’Allah.")
                )
                faqCard(
                    q: NSLocalizedString("conv_paywall.faq.q2", comment: "Why was ScrollDeeds created?"),
                    a: NSLocalizedString("conv_paywall.faq.a2", comment: "Because doomscrolling steals worship, focus, and peace. We built one focused system: lock apps until you do a good deed.")
                )
                faqCard(
                    q: NSLocalizedString("conv_paywall.faq.q3", comment: "Will the app keep improving?"),
                    a: NSLocalizedString("conv_paywall.faq.a3", comment: "Yes. We ship updates regularly and stay obsessed with helping Muslims build lasting habits.")
                )
                faqCard(
                    q: NSLocalizedString("conv_paywall.faq.q4", comment: "Who created ScrollDeeds?"),
                    a: NSLocalizedString("conv_paywall.faq.a4", comment: "Assalamu alaikum — I’m Sabri, the founder. I built ScrollDeeds for myself first, then for every Muslim fighting the same battle.")
                )
                faqCard(
                    q: NSLocalizedString("conv_paywall.faq.q5", comment: "How is ScrollDeeds different?"),
                    a: NSLocalizedString("conv_paywall.faq.a5", comment: "We don’t just track screen time. We convert distraction into deeds — with real iOS app shielding and spiritual unlocks.")
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.background)
    }

    private func faqCard(q: String, a: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(q)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primary)
            Text(a)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.border.opacity(0.9), lineWidth: 1)
                )
        )
    }

    private var stickyCTA: some View {
        VStack(spacing: 0) {
            // Soft fade into the bar so it doesn’t “pop” as a hard edge.
            LinearGradient(
                colors: [
                    AppTheme.background.opacity(0),
                    AppTheme.card.opacity(0.55),
                    AppTheme.card
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            .allowsHitTesting(false)

            Button {
                HapticManager.shared.heavy()
                ensurePackageSelected()
                if yearlyPackage == nil && monthlyPackage == nil && weeklyPackage == nil {
                    loadOfferings()
                }
                withAnimation(.spring(response: 0.58, dampingFraction: 0.90)) {
                    step = .pricing
                }
            } label: {
                Text(NSLocalizedString("conv_paywall.sticky_cta", comment: "Bismillah, Take the Step"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 18)
        }
        .background(
            AppTheme.card
                .shadow(color: .black.opacity(0.10), radius: 22, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Step 3: Pricing

    private var yearlySavePercent: Int {
        if let yearly = yearlyPackage?.storeProduct.price as Decimal?,
           let weekly = weeklyPackage?.storeProduct.price as Decimal? {
            let yearCost = NSDecimalNumber(decimal: yearly).doubleValue
            let weeklyYear = NSDecimalNumber(decimal: weekly).doubleValue * 52
            guard weeklyYear > 0 else { return 0 }
            return max(0, Int(((1 - yearCost / weeklyYear) * 100).rounded()))
        }
        return 0
    }

    private var programReadyPaywall: some View {
        ProgramReadyPaywallView(
            yearlyPrice: String(
                format: NSLocalizedString("conv_paywall.program.per_year", comment: "%@/year"),
                yearlyPackage?.storeProduct.localizedPriceString ?? ""
            ),
            yearlyPerWeek: String(
                format: NSLocalizedString("conv_paywall.program.per_week", comment: "%@/wk"),
                formatPrice(yearlyWeeklyEquivalent)
            ),
            weeklyPrice: String(
                format: NSLocalizedString("conv_paywall.program.per_week", comment: "%@/wk"),
                weeklyPackage?.storeProduct.localizedPriceString ?? ""
            ),
            savePercent: yearlySavePercent,
            selectedIsYearly: selectedPricing == .yearly,
            isPurchasing: isPurchasing,
            onSelectYearly: {
                if let yearly = yearlyPackage {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        selectedPricing = .yearly
                        selectedPackage = yearly
                    }
                    HapticManager.shared.soft()
                }
            },
            onSelectWeekly: {
                if let weekly = weeklyPackage {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        selectedPricing = .weekly
                        selectedPackage = weekly
                    }
                    HapticManager.shared.soft()
                }
            },
            onContinue: {
                HapticManager.shared.heavy()
                ensurePackageSelected()
                purchaseSelectedProduct()
            },
            onClose: { dismissPricingToSales() },
            onRestore: {
                Task { await restoreAndReport() }
            },
            onOpenTerms: {
                if let url = URL(string: "https://getnafsi.lovable.app/terms") {
                    UIApplication.shared.open(url)
                }
            },
            onOpenPrivacy: {
                if let url = URL(string: "https://getnafsi.lovable.app/privacy") {
                    UIApplication.shared.open(url)
                }
            },
            redeemFooter: makeInlineRedeem(showsRestore: false)
        )
        .onAppear { ensurePackageSelected() }
    }

    private var pricingStep: some View {
        GeometryReader { geo in
            // Short phones (SE, 13 mini, regular 6.1") cannot fit the roomy header
            // and both plans above the pinned purchase button.
            let compact = geo.size.height < 860
            let sheetHeight = min(geo.size.height * 0.94, geo.size.height - 12)

            ZStack(alignment: .bottom) {
                Color.black.opacity(0.38)
                    .ignoresSafeArea()
                    .onTapGesture {
                        HapticManager.shared.soft()
                        dismissPricingToSales()
                    }

                VStack(spacing: 0) {
                    ZStack {
                        Capsule()
                            .fill(AppTheme.border.opacity(0.9))
                            .frame(width: 40, height: 5)
                        HStack {
                            Spacer()
                            PaywallCloseButton(
                                iconColor: UIColor(AppTheme.textMuted),
                                backgroundColor: UIColor(AppTheme.card),
                                action: { dismissPricingToSales() }
                            )
                            .frame(width: 28, height: 28)
                        }
                    }
                    .padding(.top, compact ? 8 : 12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, compact ? 6 : 10)

                    if compact {
                        // Hug the content. A flexible spacer left a hole under the plans.
                        pricingHeaderBand(compact: true)
                        pricingPlansBand(compact: true)
                        pricingCTABand(compact: true)
                    } else {
                        // Both plans stay above the button. Only the intro scrolls, and only
                        // when the sheet is too short to show everything at once.
                        ViewThatFits(in: .vertical) {
                            VStack(spacing: 0) {
                                pricingHeaderBand(compact: false)
                                pricingPlansBand(compact: false)
                                Spacer(minLength: 0)
                                pricingCTABand(compact: false)
                            }

                            VStack(spacing: 0) {
                                ScrollView(showsIndicators: false) {
                                    pricingHeaderBand(compact: false)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                                pricingPlansBand(compact: false)
                                pricingCTABand(compact: false)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: geo.size.width, height: compact ? nil as CGFloat? : sheetHeight, alignment: .top)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 28,
                        style: .continuous
                    )
                    .fill(AppTheme.background)
                    .shadow(color: .black.opacity(0.18), radius: 28, y: -8)
                    .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            ensurePackageSelected()
            if yearlyPackage == nil && monthlyPackage == nil && weeklyPackage == nil {
                loadOfferings()
            }
        }
        .onChange(of: subscriptionManager.offerings?.all.count) { _ in
            ensurePackageSelected()
        }
    }

    /// Same canvas language as sales — one surface, no competing color bands.
    private func pricingHeaderBand(compact: Bool) -> some View {
        Group {
            if showsEndedTrial {
                postTrialPricingHeader(compact: compact)
            } else {
                onboardingPricingHeader(compact: compact)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, compact ? 14 : 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func onboardingPricingHeader(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 14) {
            Text(NSLocalizedString("conv_paywall.team.eyebrow", comment: "TAKE CONTROL OF YOUR NAFS"))
                .font(.system(size: compact ? 12 : 13, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundColor(AppTheme.primary)

            Text(NSLocalizedString("conv_paywall.team.header", comment: "Lock the phone. Rise for Fajr. Rule your nafs."))
                .font(.system(size: compact ? 18 : 22, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(pricingBody(teamMessage, compact: compact))
                .font(.system(size: compact ? 12.5 : 13.5, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(compact ? 3 : 4)
                .fixedSize(horizontal: false, vertical: true)

            pricingChipRow(postTrial: false, compact: compact)
        }
    }

    private func postTrialPricingHeader(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 14) {
            Text(NSLocalizedString("conv_paywall.post_trial.eyebrow", comment: "YOUR 3 DAYS ARE OVER"))
                .font(.system(size: compact ? 12 : 13, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundColor(AppTheme.primary)

            highlightedHeadline(
                NSLocalizedString(
                    "conv_paywall.post_trial.header",
                    comment: "Don’t lose what those days started."
                ),
                highlight: NSLocalizedString(
                    "conv_paywall.post_trial.header.highlight",
                    comment: "Don’t lose"
                )
            )
            .font(.system(size: compact ? 18 : 22, weight: .bold, design: .rounded))
            .fixedSize(horizontal: false, vertical: true)

            Text(pricingBody(postTrialPricingMessage, compact: compact))
                .font(.system(size: compact ? 12.5 : 13.5, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(compact ? 3 : 4)
                .fixedSize(horizontal: false, vertical: true)

            pricingChipRow(postTrial: true, compact: compact)
        }
    }

    /// On a short phone the second paragraph pushes the second plan under the button.
    private func pricingBody(_ full: String, compact: Bool) -> String {
        guard compact, let split = full.range(of: "\n\n") else { return full }
        return String(full[..<split.lowerBound])
    }

    private func pricingChipRow(postTrial: Bool, compact: Bool) -> some View {
        HStack(spacing: 0) {
            if postTrial {
                pricingTrustChip(icon: "hands.sparkles.fill", text: postTrialDeedChip)
                pricingTrustDivider
                pricingTrustChip(icon: "hourglass", text: postTrialTimeChip)
                pricingTrustDivider
                pricingTrustChip(icon: "flame.fill", text: postTrialStreakChip)
            } else {
                pricingTrustChip(
                    icon: "heart.fill",
                    text: NSLocalizedString("conv_paywall.team.chip_infra", comment: "Nafs")
                )
                pricingTrustDivider
                pricingTrustChip(
                    icon: "sunrise.fill",
                    text: NSLocalizedString("conv_paywall.team.chip_apple", comment: "Fajr")
                )
                pricingTrustDivider
                pricingTrustChip(
                    icon: "hands.sparkles.fill",
                    text: NSLocalizedString("conv_paywall.team.chip_build", comment: "Dhikr")
                )
            }
        }
        .padding(.vertical, compact ? 8 : 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.border.opacity(0.7), lineWidth: 1)
                )
        )
        .padding(.top, compact ? 2 : 4)
    }

    private var postTrialDeedChip: String {
        if hasTrialUsage {
            return String(
                format: NSLocalizedString("conv_paywall.post_trial.chip_deeds", comment: "%d deeds"),
                trialDeedCount
            )
        }
        return NSLocalizedString("conv_paywall.post_trial.chip_more_deeds", comment: "More deeds")
    }

    private var postTrialTimeChip: String {
        if hasTrialUsage, trialUnlockMinutes > 0 {
            return String(
                format: NSLocalizedString("conv_paywall.post_trial.chip_time", comment: "%@ unlocked"),
                trialUnlockLabel
            )
        }
        return NSLocalizedString("conv_paywall.post_trial.chip_less_scroll", comment: "Less scrolling")
    }

    private var postTrialStreakChip: String {
        if userDataManager.currentStreak > 0 {
            return String(
                format: NSLocalizedString("conv_paywall.post_trial.chip_streak", comment: "%d-day streak"),
                userDataManager.currentStreak
            )
        }
        return NSLocalizedString("conv_paywall.post_trial.chip_keep", comment: "Keep going")
    }

    private var postTrialPricingMessage: String {
        if hasTrialUsage {
            if hasRealName {
                return String(
                    format: NSLocalizedString(
                        "conv_paywall.post_trial.body_used_named",
                        comment: "%@, in those 3 free days you completed %d good deeds. You already felt the shift — more deeds, fewer empty hours of scrolling.\n\nKeeping that lock alive isn’t free — Apple fees, servers, Screen Time. Continue now, before the old habit comes back."
                    ),
                    displayName,
                    trialDeedCount
                )
            }
            return String(
                format: NSLocalizedString(
                    "conv_paywall.post_trial.body_used",
                    comment: "In those 3 free days you completed %d good deeds. You already felt the shift — more deeds, fewer empty hours of scrolling.\n\nKeeping that lock alive isn’t free — Apple fees, servers, Screen Time. Continue now, before the old habit comes back."
                ),
                trialDeedCount
            )
        }
        if hasRealName {
            return String(
                format: NSLocalizedString(
                    "conv_paywall.post_trial.body_fresh_named",
                    comment: "%@, those 3 free days were meant to show you a different loop: more good deeds, fewer hours lost to scrolling.\n\nThe system that creates that pause isn’t free to run. Don’t go back to promising you’ll stop tomorrow."
                ),
                displayName
            )
        }
        return NSLocalizedString(
            "conv_paywall.post_trial.body_fresh",
            comment: "Those 3 free days were meant to show you a different loop: more good deeds, fewer hours lost to scrolling.\n\nThe system that creates that pause isn’t free to run. Don’t go back to promising you’ll stop tomorrow."
        )
    }

    private var pricingTrustDivider: some View {
        Rectangle()
            .fill(AppTheme.border.opacity(0.7))
            .frame(width: 1, height: 28)
    }

    private func pricingTrustChip(icon: String, text: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.primary)
            Text(text)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var teamMessage: String {
        if hasRealName {
            return String(
                format: NSLocalizedString(
                    "conv_paywall.team.body_named",
                    comment: "%@, Nafsi locks your apps until a good deed, and wakes you for Fajr until you photograph the object you chose. That is how you take control of your nafs — not later, now."
                ),
                displayName
            )
        }
        return NSLocalizedString(
            "conv_paywall.team.body",
            comment: "Nafsi locks your apps until a good deed, and wakes you for Fajr until you photograph the object you chose. That is how you take control of your nafs — not later, now."
        )
    }

    private func pricingPlansBand(compact: Bool) -> some View {
        pricingCards(compact: compact)
            .padding(.horizontal, 22)
            .padding(.top, compact ? 16 : 18)
            // Match the gap under the Nafs / Fajr card (header bottom 14 + this top 16).
            .padding(.bottom, compact ? 30 : 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pricingCards(compact: Bool) -> some View {
        VStack(spacing: 12) {
            if let yearly = yearlyPackage {
                pricingCard(
                    title: NSLocalizedString("paywall.yearly.title", comment: "Yearly"),
                    priceLine: yearly.storeProduct.localizedPriceString,
                    detail: String(
                        format: NSLocalizedString(
                            "conv_paywall.pricing.yearly_detail",
                            comment: "≈ %@/%@"
                        ),
                        formatPrice(yearlyDetailUsesMonth ? yearlyMonthlyEquivalent : yearlyWeeklyEquivalent),
                        yearlyDetailUsesMonth
                            ? NSLocalizedString("conv_paywall.month", comment: "month")
                            : NSLocalizedString("conv_paywall.week", comment: "week")
                    ),
                    badge: yearlyPlanBadge,
                    selected: selectedPricing == .yearly,
                    compact: compact
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        selectedPricing = .yearly
                        selectedPackage = yearly
                    }
                    HapticManager.shared.soft()
                }
            }

            if let monthly = monthlyPackage {
                pricingCard(
                    title: NSLocalizedString("paywall.monthly.title", comment: "Monthly"),
                    priceLine: monthly.storeProduct.localizedPriceString,
                    detail: NSLocalizedString("conv_paywall.pricing.monthly_detail", comment: "Billed every month"),
                    badge: nil,
                    selected: selectedPricing == .monthly,
                    compact: compact
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        selectedPricing = .monthly
                        selectedPackage = monthly
                    }
                    HapticManager.shared.soft()
                }
            }

            if let weekly = weeklyPackage {
                pricingCard(
                    title: NSLocalizedString("paywall.weekly.title", comment: "Weekly"),
                    priceLine: weekly.storeProduct.localizedPriceString,
                    detail: NSLocalizedString("conv_paywall.pricing.weekly_detail", comment: "Billed every week"),
                    badge: nil,
                    selected: selectedPricing == .weekly,
                    compact: compact
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        selectedPricing = .weekly
                        selectedPackage = weekly
                    }
                    HapticManager.shared.soft()
                }
            }

            if yearlyPackage == nil && monthlyPackage == nil && weeklyPackage == nil {
                pricingPlansEmptyState
            }
        }
    }

    private var pricingPlansEmptyState: some View {
        VStack(spacing: 14) {
            if !offeringsLoaded || subscriptionManager.isLoading {
                SwiftUI.ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppTheme.primary)
                Text(NSLocalizedString("paywall.loading.plans", comment: "Loading plans…"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            } else {
                Text(NSLocalizedString(
                    "paywall.error.no_packages",
                    comment: "Unable to load subscription options. Please check your internet connection and try again."
                ))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.soft()
                    loadOfferings()
                } label: {
                    Text(LocalizedKey.Error.tryAgain.localized)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.border.opacity(0.7), lineWidth: 1)
                )
        )
    }

    private var appliedReferralCode: String? {
        guard referralManager.hasActiveReferral else { return nil }
        let code = localStorage.referralCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return code.isEmpty ? nil : code.uppercased()
    }

    private func makeInlineRedeem(showsRestore: Bool) -> PaywallInlineRedeem {
        PaywallInlineRedeem(
            isPresented: $isRedeemExpanded,
            draft: $redeemDraft,
            appliedCode: appliedReferralCode,
            isApplying: isApplyingRedeem,
            error: referralManager.validationError,
            onApply: applyRedeemCode,
            onRestore: {
                Task { await restoreAndReport() }
            },
            showsRestore: showsRestore
        )
    }

    private func applyRedeemCode() {
        let sanitized = redeemDraft
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard !sanitized.isEmpty, !isApplyingRedeem else { return }

        isApplyingRedeem = true
        Task { @MainActor in
            let valid = await referralManager.validateCode(sanitized)
            isApplyingRedeem = false
            guard valid else { return }

            isRedeemExpanded = false
            HapticManager.shared.success()

            if referralManager.hasInfluencerAccess {
                finishSuccessfulPurchase()
                return
            }

            localStorage.referralCode = sanitized
            await subscriptionManager.loadOfferings()
            ensurePackageSelected()
        }
    }

    private var yearlyPlanBadge: String? {
        if offersFreeDays {
            return NSLocalizedString("paywall.badge.most_popular", comment: "3 DAYS FREE")
        }
        let percent = referralManager.discountPercent
        guard referralManager.hasActiveReferral, percent > 0 else { return nil }
        return String(format: NSLocalizedString("paywall.save_percent", comment: "SAVE %d%%"), percent)
    }

    private func pricingCard(
        title: String,
        priceLine: String,
        detail: String,
        badge: String?,
        selected: Bool,
        compact: Bool = false,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: compact ? 15 : 16, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)

                        if let badge, !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(AppTheme.paywallTrialBadgeBackground)
                                )
                        }
                    }

                    Text(priceLine)
                        .font(.system(size: compact ? 20 : 22, weight: .bold, design: .rounded))
                        .foregroundColor(selected ? AppTheme.primary : AppTheme.textPrimary)

                    Text(detail)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .stroke(selected ? AppTheme.primary : AppTheme.border, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if selected {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, compact ? 10 : 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? AppTheme.primary.opacity(0.08) : AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                selected ? AppTheme.primary : AppTheme.border.opacity(0.75),
                                lineWidth: selected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func pricingCTABand(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 10) {
            Text(pricingAboveCTA)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
                .frame(maxWidth: .infinity)

            // Own pulse state — animation never touches disclaimer / “No Payment Due Now”.
            PricingPulsingCTAButton(
                title: pricingCTALabel,
                isPurchasing: isPurchasing,
                isEnabled: selectedPackage != nil
            ) {
                HapticManager.shared.heavy()
                purchaseSelectedProduct()
            }

            pricingSubscriptionDisclaimer

            makeInlineRedeem(showsRestore: true)
        }
        .padding(.horizontal, 22)
        .padding(.top, compact ? 20 : 12)
        .padding(.bottom, compact ? 20 : 28)
        .frame(maxWidth: .infinity)
        .background(
            AppTheme.card
                .shadow(color: .black.opacity(0.06), radius: 16, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    /// Required subscription disclosures for App Review (Guideline 3.1.2).
    @ViewBuilder
    private var pricingSubscriptionDisclaimer: some View {
        if let attributed = pricingDisclaimerAttributedString {
            Text(attributed)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pricingDisclaimerAttributedString: AttributedString? {
        let disclaimer: String
        if selectedPricing == .yearly, let yearly = yearlyPackage {
            let key = offersFreeDays
                ? "paywall.disclaimer.footer_yearly_trial"
                : "paywall.disclaimer.footer_yearly"
            disclaimer = String(
                format: NSLocalizedString(key, comment: ""),
                yearly.storeProduct.localizedPriceString,
                formatPrice(yearlyMonthlyEquivalent)
            )
        } else if selectedPricing == .monthly, let monthly = monthlyPackage {
            disclaimer = String(
                format: NSLocalizedString("paywall.disclaimer.footer_monthly", comment: ""),
                monthly.storeProduct.localizedPriceString
            )
        } else if let weekly = weeklyPackage {
            disclaimer = String(
                format: NSLocalizedString("paywall.disclaimer.footer_weekly", comment: ""),
                weekly.storeProduct.localizedPriceString
            )
        } else {
            return nil
        }

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
        termsAttr.underlineStyle = .single
        s.append(termsAttr)
        s.append(AttributedString(" \(and) "))
        var privacyAttr = AttributedString(privacy)
        privacyAttr.link = privacyURL
        privacyAttr.underlineStyle = .single
        s.append(privacyAttr)
        s.append(AttributedString("."))
        return s
    }

    private func footerLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Downsell

    private var downsellSheet: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        showDownsell = false
                    }
                }

            VStack(spacing: 0) {
                Capsule()
                    .fill(AppTheme.border)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

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

                    Text(NSLocalizedString(
                        downsellsMonthly
                            ? "paywall.downsell.subtitle.monthly"
                            : "paywall.downsell.subtitle.weekly",
                        comment: ""
                    ))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 22)

                if let secondary = downsellPackage {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString(
                                downsellsMonthly ? "paywall.downsell.monthly_plan" : "paywall.downsell.weekly_plan",
                                comment: ""
                            ))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text(NSLocalizedString("paywall.plan.cancel_anytime", comment: "Cancel anytime, no commitment"))
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(secondary.storeProduct.localizedPriceString)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Text(NSLocalizedString(
                                downsellsMonthly ? "paywall.downsell.per_month" : "paywall.downsell.per_week",
                                comment: ""
                            ))
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.primary.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.primary.opacity(0.45), lineWidth: 1.5)
                            )
                    )
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)
                }

                Button {
                    HapticManager.shared.heavy()
                    purchaseSecondaryProduct()
                } label: {
                    Text(NSLocalizedString(
                        downsellsMonthly
                            ? "paywall.downsell.cta.monthly"
                            : "paywall.downsell.cta.weekly",
                        comment: ""
                    ))
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 22)
                .padding(.bottom, 10)

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        showDownsell = false
                    }
                } label: {
                    Text(NSLocalizedString("paywall.downsell.no_thanks", comment: "No thanks"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(.bottom, 28)
            }
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28)
                    .fill(AppTheme.card)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    // MARK: - Purchase / offerings

    /// Post-trial buyers already finished onboarding (apps + difficulty). Sending them
    /// through Thank You → apps → difficulty again traps them in a loop when the
    /// dashboard re-opens the upgrade paywall. First-time buyers still get the funnel.
    private func restoreAndReport() async {
        await subscriptionManager.restorePurchases()
        await MainActor.run {
            if subscriptionManager.hasPremiumAccess {
                finishSuccessfulPurchase()
            } else {
                errorMessage = NSLocalizedString("paywall.restore.none", comment: "")
                showError = true
            }
        }
    }

    private func finishSuccessfulPurchase() {
        if variant == .postTrial {
            onSubscribed()
            return
        }
        withAnimation(.easeInOut(duration: 0.35)) {
            showThankYou = true
        }
    }

    private func loadOfferings() {
        Task { @MainActor in
            offeringsLoaded = false
            await subscriptionManager.loadOfferings()
            ensurePackageSelected()
            offeringsLoaded = true
            debugPrint(
                """
                💳 Paywall packages [\(variant == .postTrial ? "postTrial" : "onboarding")] \
                offering=\(paywallOffering?.identifier ?? "nil") \
                yearly=\(yearlyPackage?.storeProduct.productIdentifier ?? "nil") \
                monthly=\(monthlyPackage?.storeProduct.productIdentifier ?? "nil") \
                weekly=\(weeklyPackage?.storeProduct.productIdentifier ?? "nil")
                """
            )
            // Don't block the promise/sales screens — StoreKit can attach a beat later.
            if step == .pricing,
               yearlyPackage == nil && weeklyPackage == nil && monthlyPackage == nil {
                errorMessage = NSLocalizedString(
                    "paywall.error.no_packages",
                    comment: "Unable to load subscription options. Please check your internet connection and try again."
                )
                showError = true
            }
        }
    }

    private func retryLoadOfferings() {
        showError = false
        loadOfferings()
    }

    private func ensurePackageSelected() {
        if selectedPricing == .yearly, let yearly = yearlyPackage {
            selectedPackage = yearly
        } else if selectedPricing == .monthly, let monthly = monthlyPackage {
            selectedPackage = monthly
        } else if let weekly = weeklyPackage {
            selectedPricing = .weekly
            selectedPackage = weekly
        } else if let monthly = monthlyPackage {
            selectedPricing = .monthly
            selectedPackage = monthly
        } else if let yearly = yearlyPackage {
            selectedPricing = .yearly
            selectedPackage = yearly
        }
    }

    private func purchaseSelectedProduct(showDownsellOnCancel: Bool = true, onCancel: (() -> Void)? = nil) {
        guard let package = selectedPackage else {
            errorMessage = "Please select a subscription plan first."
            showError = true
            return
        }
        isPurchasing = true
        let productId = package.storeProduct.productIdentifier
        let isYearly = productId.lowercased().contains("yearly")
        AnalyticsManager.shared.trackPurchaseAttempted(productId: productId, isYearly: isYearly)

        Task {
            do {
                try await subscriptionManager.purchase(package)
                AnalyticsManager.shared.trackPurchaseCompleted(productId: productId, isYearly: isYearly)
                await MainActor.run {
                    if subscriptionManager.hasPremiumAccess {
                        finishSuccessfulPurchase()
                    } else {
                        errorMessage = NSLocalizedString("paywall.purchase.no_access", comment: "")
                        showError = true
                    }
                }
            } catch {
                if case SubscriptionError.userCancelled = error {
                    AnalyticsManager.shared.trackPurchaseFailed(productId: productId, error: "user_cancelled")
                    await MainActor.run {
                        if let onCancel {
                            onCancel()
                        } else if showDownsellOnCancel && hasDownsellPlan {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                showDownsell = true
                            }
                        }
                    }
                } else {
                    AnalyticsManager.shared.trackPurchaseFailed(productId: productId, error: error.localizedDescription)
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            isPurchasing = false
        }
    }

    private var downsellPackage: Package? {
        if downsellsMonthly { return downsellMonthlyPackage }
        if downsellsWeekly { return downsellWeeklyPackage }
        return nil
    }

    private func purchaseSecondaryProduct() {
        guard let package = downsellPackage else {
            errorMessage = "Subscription option not available. Please check your internet connection and try again."
            showError = true
            return
        }
        isPurchasing = true
        let productId = package.storeProduct.productIdentifier
        AnalyticsManager.shared.trackPurchaseAttempted(productId: productId, isYearly: false)
        Task {
            do {
                try await subscriptionManager.purchase(package)
                AnalyticsManager.shared.trackPurchaseCompleted(productId: productId, isYearly: false)
                await MainActor.run {
                    showDownsell = false
                    finishSuccessfulPurchase()
                }
            } catch {
                if case SubscriptionError.userCancelled = error {
                    AnalyticsManager.shared.trackPurchaseFailed(productId: productId, error: "user_cancelled")
                } else {
                    AnalyticsManager.shared.trackPurchaseFailed(productId: productId, error: error.localizedDescription)
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            isPurchasing = false
        }
    }

    private func dismissPricingToSales() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            step = .sales
        }
    }

    // MARK: - Text helpers

    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearlyPackage?.storeProduct.priceFormatter?.locale ?? Locale.current
        formatter.maximumFractionDigits = 2
        return formatter.string(from: price as NSNumber) ?? "\(price)"
    }

    private func highlightedText(_ full: String, highlight: String, base: Color, accent: Color) -> Text {
        guard highlight.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2,
              let range = firstWholeWordRange(of: highlight, in: full) else {
            return Text(full).foregroundColor(base)
        }
        let before = String(full[..<range.lowerBound])
        let mid = String(full[range])
        let after = String(full[range.upperBound...])
        return Text(before).foregroundColor(base)
            + Text(mid).foregroundColor(accent).fontWeight(.bold)
            + Text(after).foregroundColor(base)
    }

    private func highlightedHeadline(_ full: String, highlight: String) -> Text {
        highlightedText(full, highlight: highlight, base: AppTheme.textPrimary, accent: AppTheme.primary)
    }

    private struct HighlightPart {
        let value: String
        let isHighlight: Bool
    }

    private func splitHighlighting(
        _ full: String,
        tokens: [String],
        firstOccurrenceToken: String? = nil
    ) -> [HighlightPart] {
        var parts: [HighlightPart] = [HighlightPart(value: full, isHighlight: false)]
        let ordered = ([firstOccurrenceToken].compactMap { $0 } + tokens)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 }
            .sorted { $0.count > $1.count }
        for token in ordered {
            let onlyFirst = firstOccurrenceToken?.caseInsensitiveCompare(token) == .orderedSame
            var next: [HighlightPart] = []
            var didMatch = false
            for part in parts {
                if part.isHighlight {
                    next.append(part)
                    continue
                }
                if onlyFirst, didMatch {
                    next.append(part)
                    continue
                }
                var remaining = part.value
                while let range = firstWholeWordRange(of: token, in: remaining) {
                    let before = String(remaining[..<range.lowerBound])
                    if !before.isEmpty { next.append(HighlightPart(value: before, isHighlight: false)) }
                    next.append(HighlightPart(value: String(remaining[range]), isHighlight: true))
                    remaining = String(remaining[range.upperBound...])
                    if onlyFirst {
                        didMatch = true
                        break
                    }
                }
                if !remaining.isEmpty { next.append(HighlightPart(value: remaining, isHighlight: false)) }
            }
            parts = next
        }
        return parts
    }

    private func firstWholeWordRange(of token: String, in text: String) -> Range<String.Index>? {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return nil }
        let pattern = "(?<!\\p{L})" + NSRegularExpression.escapedPattern(for: trimmed) + "(?!\\p{L})"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let nsRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: nsRange),
              let range = Range(match.range, in: text) else {
            return nil
        }
        return range
    }
}

// MARK: - Pricing CTA pulse (button only)

/// Owns its own pulse state so parent text (disclaimer / “No Payment Due Now”) never animates.
private struct PricingPulsingCTAButton: View {
    let title: String
    let isPurchasing: Bool
    let isEnabled: Bool
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            Group {
                if isPurchasing {
                    SwiftUI.ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 21)
        }
        .buttonStyle(PrimaryButtonStyle(stylesLabel: false))
        .disabled(!isEnabled || isPurchasing)
        .opacity(isPurchasing ? 0.7 : 1)
        .shadow(
            color: AppTheme.primary.opacity(isPurchasing ? 0 : (pulse ? 0.36 : 0.10)),
            radius: isPurchasing ? 0 : (pulse ? 14 : 6),
            y: 4
        )
        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)
        .onAppear {
            pulse = false
            DispatchQueue.main.async { pulse = true }
        }
        .onDisappear { pulse = false }
    }
}

// MARK: - Sales scroll tracking (sticky CTA reveal)

private struct SalesScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// iOS 18+: native scroll geometry. Older: PreferenceKey from a top-of-content anchor.
private struct SalesStickyCTAScrollTracker: ViewModifier {
    let threshold: CGFloat
    let onChange: (Bool) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y > threshold
                } action: { _, shouldShow in
                    onChange(shouldShow)
                }
        } else {
            content
                .onPreferenceChange(SalesScrollOffsetKey.self) { offset in
                    onChange(offset > threshold)
                }
        }
    }
}

/// Pose image for this paywall file (keeps SourceKit happy in a very large view).
private struct PaywallNafsiPose: View {
    let pose: String
    var height: CGFloat = 112

    var body: some View {
        Image(pose)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityHidden(true)
    }
}
