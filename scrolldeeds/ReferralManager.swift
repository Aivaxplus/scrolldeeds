import Foundation
import Combine

@MainActor
final class ReferralManager: ObservableObject {
    static let shared = ReferralManager()

    @Published var isValidating: Bool = false
    @Published var validationError: String?
    @Published private(set) var hasActiveReferral: Bool
    @Published private(set) var hasInfluencerAccess: Bool

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let referralValid              = "referral.valid"
        static let referralDiscountPercent    = "referral.discount_percent"
        static let referralOfferingIdentifier = "referral.offering_identifier"
        static let influencerValid            = "referral.influencer_valid"
        static let referralCode               = "referral.code"   // stores the exact entered code
    }

    private static let webhookURL = URL(string: "https://hook.eu1.make.com/gibaovjebssl50wgjjo26feh21h7ar97")!

    private init() {
        hasActiveReferral = defaults.bool(forKey: Keys.referralValid)
        hasInfluencerAccess = defaults.bool(forKey: Keys.influencerValid)
    }

    /// Fixed code for influencers that should grant free access and skip the paywall.
    /// You can rename/change this later if you want another specific code.
    static let influencerFreeCode = "INFLUENCERFREE"

    var discountPercent: Int {
        let value = defaults.integer(forKey: Keys.referralDiscountPercent)
        return value > 0 ? value : 0
    }

    var offeringIdentifier: String {
        defaults.string(forKey: Keys.referralOfferingIdentifier) ?? "referral_15"
    }

    func clearReferral() {
        defaults.set(false, forKey: Keys.referralValid)
        defaults.removeObject(forKey: Keys.referralDiscountPercent)
        defaults.removeObject(forKey: Keys.referralOfferingIdentifier)
        hasActiveReferral = false
        validationError = nil
    }

    func clearAll() {
        clearReferral()
        defaults.set(false, forKey: Keys.influencerValid)
        hasInfluencerAccess = false
    }

    func validateCode(_ code: String) async -> Bool {
        let trimmed = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard !trimmed.isEmpty else {
            clearAll()
            return false
        }

        // Influencer fixed code → free access (paywall skip).
        if trimmed == Self.influencerFreeCode {
            defaults.set(true,   forKey: Keys.influencerValid)
            defaults.set(trimmed, forKey: Keys.referralCode)
            hasInfluencerAccess = true
            clearReferral()
            validationError = nil
            NotificationManager.shared.cancelLeaveAppNonSubscriberWinback()
            return true
        }

        // Offline referral codes → RevenueCat offering `referral_15`:
        //   monthly → App Store `monthly_referral`
        //   yearly  → App Store `yearly_referral`
        // Weekly stays on the default offering. See SubscriptionManager.resolvedPaywallOffering().
        //
        // Prefix rule: any code starting with "SCROLLDEEDS15_" followed by at least one
        // character is automatically valid (e.g. SCROLLDEEDS15_YUSUF, SCROLLDEEDS15_AHMED).
        let exactCodes: [String: (discountPercent: Int, offeringIdentifier: String)] = [
            "SCROLLDEEDS15":     (15, "referral_15"),
            "ADDICTION15":       (15, "referral_15"),
            "DOOMSCROLLING15":   (15, "referral_15")
        ]

        isValidating = true
        validationError = nil

        defer { isValidating = false }

        // 1. Exact match
        if let match = exactCodes[trimmed] {
            defaults.set(true,                    forKey: Keys.referralValid)
            defaults.set(match.discountPercent,   forKey: Keys.referralDiscountPercent)
            defaults.set(match.offeringIdentifier, forKey: Keys.referralOfferingIdentifier)
            defaults.set(trimmed,                 forKey: Keys.referralCode)
            hasActiveReferral = true
            hasInfluencerAccess = false
            validationError = nil
            return true
        }

        // 2. Prefix match: SCROLLDEEDS15_<anything>
        let influencerPrefix = "SCROLLDEEDS15_"
        if trimmed.hasPrefix(influencerPrefix), trimmed.count > influencerPrefix.count {
            defaults.set(true,          forKey: Keys.referralValid)
            defaults.set(15,            forKey: Keys.referralDiscountPercent)
            defaults.set("referral_15", forKey: Keys.referralOfferingIdentifier)
            defaults.set(trimmed,       forKey: Keys.referralCode)
            hasActiveReferral = true
            hasInfluencerAccess = false
            validationError = nil
            return true
        }

        clearAll()
        validationError = NSLocalizedString("referral.invalid_code", comment: "Invalid referral code.")
        return false
    }

    // MARK: - Webhook

    /// Call this once after a successful App Store purchase.
    /// Sends the referral code + plan to Make.com only when the user has actually paid.
    func sendPurchaseWebhook(plan: String) {
        let code     = defaults.string(forKey: Keys.referralCode) ?? "unknown"
        let userID   = defaults.string(forKey: "userID")   ?? "unknown"
        let userName = defaults.string(forKey: "userName") ?? ""
        let payload: [String: Any] = [
            "code":       code,
            "plan":       plan,        // "weekly" | "monthly" | "yearly"
            "user_id":    userID,
            "user_name":  userName,
            "timestamp":  ISO8601DateFormatter().string(from: Date())
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        var request = URLRequest(url: Self.webhookURL)
        request.httpMethod = "POST"
        request.httpBody   = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        Task.detached {
            try? await URLSession.shared.data(for: request)
        }
    }
}

