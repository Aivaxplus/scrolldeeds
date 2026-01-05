//
//  FeedbackService.swift
//
//  Sends feedback to webhook when user completes 3 unlocks
//

import Foundation

class FeedbackService {
    static let shared = FeedbackService()
    
    private let webhookURL = "https://hook.eu2.make.com/4m5u56w6pb2wvhogsidpxvdgah7zmqri"
    private let feedbackSentKey = "feedback_sent_to_webhook"
    
    private init() {}
    
    // Send feedback to webhook (first time only, after 3 unlocks)
    func sendFeedback(sessionCount: Int) {
        // Only send once, after 3 unlocks
        if sessionCount == 3 && !UserDefaults.standard.bool(forKey: feedbackSentKey) {
            sendToWebhook(sessionCount: sessionCount)
            UserDefaults.standard.set(true, forKey: feedbackSentKey)
        }
    }
    
    private func sendToWebhook(sessionCount: Int) {
        guard let url = URL(string: webhookURL) else {
            debugPrint("⚠️ FeedbackService: Invalid webhook URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "event": "user_feedback_eligible",
            "session_count": sessionCount,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    debugPrint("❌ FeedbackService: Error sending feedback: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        debugPrint("✅ FeedbackService: Feedback sent successfully")
                    } else {
                        debugPrint("⚠️ FeedbackService: Server returned status code \(httpResponse.statusCode)")
                    }
                }
            }.resume()
        } catch {
            debugPrint("❌ FeedbackService: Error encoding feedback: \(error.localizedDescription)")
        }
    }
}

#if DEBUG
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#else
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // No-op in production
}
#endif

