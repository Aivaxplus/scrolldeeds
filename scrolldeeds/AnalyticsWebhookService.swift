//
//  AnalyticsWebhookService.swift
//  scrolldeeds
//
//  Sends user analytics data to webhook for tracking conversions and demographics
//

import Foundation

class AnalyticsWebhookService {
    static let shared = AnalyticsWebhookService()
    
    // Make.com Webhook URL - Alle data (betalend + niet-betalend)
    private let webhookURL = "https://hook.eu2.make.com/3oje7xgcfk7dpx7grp4ipdsp37hs1rec"
    
    // Premium Users Webhook - Ontvangt ALLEEN data van gebruikers die WEL hebben betaald
    private let premiumWebhookURL = "https://hook.eu2.make.com/pfnxmwq5tnqnwhnlafmass3y1a3eo0fy"
    
    private init() {}
    
    // MARK: - Send User Data
    
    func sendUserData(
        age: String?,
        referralSource: String?,
        isPremium: Bool,
        event: AnalyticsEvent
    ) {
        guard let url = URL(string: webhookURL) else {
            debugPrint("❌ Invalid webhook URL")
            return
        }
        
        // Get user ID from UserDataManager
        let userID = UserDataManager.shared.userID
        
        // Prepare payload
        let payload: [String: Any] = [
            "event": event.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "user_id": userID, // Unique user identifier
            "user_data": [
                "age_group": age ?? "unknown",
                "referral_source": referralSource ?? "unknown",
                "is_premium": isPremium,
                "platform": "iOS",
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ]
        ]
        
        // Convert to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            debugPrint("❌ Failed to serialize webhook payload")
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                debugPrint("❌ Webhook error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    debugPrint("✅ Webhook sent successfully: \(event.rawValue)")
                } else {
                    debugPrint("⚠️ Webhook returned status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    // MARK: - Send to Premium Webhook (Only for paying users)
    
    private func sendToPremiumWebhook(
        age: String?,
        referralSource: String?,
        event: AnalyticsEvent
    ) {
        guard let url = URL(string: premiumWebhookURL) else {
            debugPrint("❌ Invalid premium webhook URL")
            return
        }
        
        // Get user ID from UserDataManager
        let userID = UserDataManager.shared.userID
        
        // Prepare payload (same structure as regular webhook)
        let payload: [String: Any] = [
            "event": event.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "user_id": userID, // Unique user identifier
            "user_data": [
                "age_group": age ?? "unknown",
                "referral_source": referralSource ?? "unknown",
                "is_premium": true, // Always true for premium webhook
                "platform": "iOS",
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ]
        ]
        
        // Convert to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            debugPrint("❌ Failed to serialize premium webhook payload")
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                debugPrint("❌ Premium webhook error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    debugPrint("✅ Premium webhook sent successfully: \(event.rawValue)")
                } else {
                    debugPrint("⚠️ Premium webhook returned status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    // MARK: - Convenience Methods
    
    func trackOnboardingCompleted(age: String?, referralSource: String?) {
        sendUserData(
            age: age,
            referralSource: referralSource,
            isPremium: false,
            event: .onboardingCompleted
        )
    }
    
    func trackUserSubscribed(age: String?, referralSource: String?) {
        // Send to regular webhook (all users)
        sendUserData(
            age: age,
            referralSource: referralSource,
            isPremium: true,
            event: .userSubscribed
        )
        
        // ALSO send to premium webhook (only paying users)
        sendToPremiumWebhook(
            age: age,
            referralSource: referralSource,
            event: .userSubscribed
        )
    }
    
    func trackPaywallShown(age: String?, referralSource: String?) {
        sendUserData(
            age: age,
            referralSource: referralSource,
            isPremium: false,
            event: .paywallShown
        )
    }
    
    func trackPaywallDismissed(age: String?, referralSource: String?) {
        sendUserData(
            age: age,
            referralSource: referralSource,
            isPremium: false,
            event: .paywallDismissed
        )
    }
    
    func trackSubscriptionCancelled(
        age: String?,
        referralSource: String?,
        cancellationReason: String? = nil,
        daysActive: Int? = nil
    ) {
        // Get user ID
        let userID = UserDataManager.shared.userID
        
        // Send to regular webhook
        guard let url = URL(string: webhookURL) else {
            debugPrint("❌ Invalid webhook URL")
            return
        }
        
        var payload: [String: Any] = [
            "event": "subscription_cancelled",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "user_id": userID,
            "user_data": [
                "age_group": age ?? "unknown",
                "referral_source": referralSource ?? "unknown",
                "is_premium": false, // No longer premium
                "platform": "iOS",
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ]
        ]
        
        // Add cancellation details
        if let reason = cancellationReason {
            payload["cancellation_reason"] = reason
        }
        if let days = daysActive {
            payload["days_active"] = days
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            debugPrint("❌ Failed to serialize cancellation payload")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                debugPrint("❌ Cancellation webhook error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    debugPrint("✅ Cancellation tracked successfully")
                } else {
                    debugPrint("⚠️ Cancellation webhook returned status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
}

// MARK: - Analytics Events

enum AnalyticsEvent: String {
    case onboardingCompleted = "onboarding_completed"
    case paywallShown = "paywall_shown"
    case paywallDismissed = "paywall_dismissed"
    case userSubscribed = "user_subscribed"
}
