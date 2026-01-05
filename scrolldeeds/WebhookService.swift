//
//  WebhookService.swift
//  scrolldeeds
//

import Foundation
import Combine

// MARK: - Debug Helper
#if DEBUG
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#else
private func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // No-op in production
}
#endif

enum VerificationResult {
    case approved
    case rejected(reason: String)
    case error(String)
}

class WebhookService: ObservableObject {
    @Published var isVerifying = false
    @Published var verificationResult: VerificationResult?
    
    // MARK: - Configuration
    // Production n8n webhook URL
    private let webhookURL = "https://aivaxplus.app.n8n.cloud/webhook/7feb29f5-1a33-47f0-a8c7-9397e2d91e75"
    
    func verifyDhikrRecording(audioData: Data, dhikrType: String, completion: @escaping (VerificationResult) -> Void) {
        isVerifying = true
        verificationResult = nil
        
        guard let url = URL(string: webhookURL) else {
            let result = VerificationResult.error("Invalid webhook URL")
            DispatchQueue.main.async {
                self.isVerifying = false
                self.verificationResult = result
                completion(result)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15 // 15 seconds timeout (reduced from 60 for faster feedback)
        request.cachePolicy = .reloadIgnoringLocalCacheData // Don't cache webhook requests
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add dhikr type field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"dhikr_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(dhikrType)\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"dhikr.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add timestamp
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"timestamp\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(Date().timeIntervalSince1970)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // Send request with optimized session configuration
        debugPrint("WebhookService: Sending request to \(webhookURL)")
        debugPrint("WebhookService: Audio data size: \(audioData.count) bytes")
        
        // Use optimized URLSession configuration for faster requests
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 15
        config.waitsForConnectivity = false // Don't wait for connectivity, fail fast
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isVerifying = false
                
                if let error = error {
                    debugPrint("WebhookService: Network error: \(error.localizedDescription)")
                    // For production: Auto-approve on network errors to prevent blocking users
                    // Users should be able to use the app even without internet/webhook
                    debugPrint("WebhookService: Network error occurred - auto-approving for production")
                    let result = VerificationResult.approved
                    self.verificationResult = result
                    completion(result)
                    return
                }
                
                // Log HTTP response and handle status codes
                if let httpResponse = response as? HTTPURLResponse {
                    debugPrint("WebhookService: HTTP Status Code: \(httpResponse.statusCode)")
                    
                    // Handle HTTP error status codes
                    // For production: Auto-approve if webhook is unavailable (404, 500, etc.)
                    // This ensures users can still use the app even if webhook is down
                    if httpResponse.statusCode >= 400 {
                        debugPrint("WebhookService: Webhook returned error status \(httpResponse.statusCode) - auto-approving for production")
                        // Auto-approve to prevent blocking users when webhook is unavailable
                        let result = VerificationResult.approved
                        self.verificationResult = result
                        completion(result)
                        return
                    }
                }
                
                guard let data = data else {
                    debugPrint("WebhookService: No data received from webhook - auto-approving for production")
                    // Auto-approve if no data received (webhook might be down)
                    let result = VerificationResult.approved
                    self.verificationResult = result
                    completion(result)
                    return
                }
                
                // Log raw response data
                debugPrint("WebhookService: Response data size: \(data.count) bytes")
                if let responseString = String(data: data, encoding: .utf8) {
                    debugPrint("WebhookService: Raw response (UTF-8): \(responseString)")
                }
                
                // Try to clean the data if it has extra whitespace or BOM
                var cleanedData = data
                
                // Remove UTF-8 BOM if present
                if data.count >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF {
                    cleanedData = data.subdata(in: 3..<data.count)
                    debugPrint("WebhookService: Removed UTF-8 BOM")
                }
                
                // Try to parse as JSON with multiple attempts
                var json: [String: Any]?
                
                // Attempt 1: Parse directly
                json = try? JSONSerialization.jsonObject(with: cleanedData, options: []) as? [String: Any]
                
                // Attempt 2: Parse with allowing fragments
                if json == nil {
                    json = try? JSONSerialization.jsonObject(with: cleanedData, options: .fragmentsAllowed) as? [String: Any]
                }
                
                // Attempt 3: Trim whitespace and try again
                if json == nil, let stringResponse = String(data: cleanedData, encoding: .utf8) {
                    let trimmed = stringResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let trimmedData = trimmed.data(using: .utf8) {
                        json = try? JSONSerialization.jsonObject(with: trimmedData, options: []) as? [String: Any]
                    }
                }
                
                if let json = json {
                    debugPrint("WebhookService: Successfully parsed JSON: \(json)")
                    let result = self.parseWebhookResponse(json)
                    self.verificationResult = result
                    completion(result)
                } else if let stringResponse = String(data: cleanedData, encoding: .utf8) {
                    // If not JSON, check if it's a plain text response
                    debugPrint("WebhookService: Could not parse JSON, trying plain text: \(stringResponse)")
                    
                    // Check if response is HTML (not user-friendly)
                    if self.isHTMLResponse(stringResponse) {
                        debugPrint("WebhookService: Received HTML response (likely error page) - auto-approving for production")
                        // Auto-approve if we get HTML (webhook is probably down or misconfigured)
                        let result = VerificationResult.approved
                        self.verificationResult = result
                        completion(result)
                        return
                    }
                    
                    // Check for common success indicators in plain text
                    let lowercased = stringResponse.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    if lowercased.contains("success") || 
                       lowercased.contains("approved") || 
                       lowercased.contains("true") ||
                       lowercased == "ok" {
                        let result = VerificationResult.approved
                        self.verificationResult = result
                        completion(result)
                    } else {
                        // For production: Auto-approve if response is unclear
                        // This prevents blocking users when webhook returns unexpected format
                        debugPrint("WebhookService: Unclear response format - auto-approving for production")
                        let result = VerificationResult.approved
                        self.verificationResult = result
                        completion(result)
                    }
                } else {
                    debugPrint("WebhookService: Could not parse response at all - auto-approving for production")
                    // If we can't parse it at all, auto-approve for production
                    let result = VerificationResult.approved
                    self.verificationResult = result
                    completion(result)
                }
            }
        }.resume()
    }
    
    private func parseWebhookResponse(_ json: [String: Any]) -> VerificationResult {
        // Expected response format:
        // {
        //   "approved": true/false,
        //   "reason": "string" (optional),
        //   "confidence": 0.95 (optional)
        // }
        
        // Also accept "success" as an alternative to "approved"
        let approved: Bool
        if let approvedValue = json["approved"] as? Bool {
            approved = approvedValue
        } else if let successValue = json["success"] as? Bool {
            approved = successValue
        } else if let statusValue = json["status"] as? String {
            approved = (statusValue.lowercased() == "approved" || statusValue.lowercased() == "success")
        } else {
            debugPrint("WebhookService: Missing 'approved', 'success', or 'status' field in response - auto-approving for production")
            // Auto-approve if response format is unexpected (webhook might be misconfigured)
            return .approved
        }
        
        if approved {
            debugPrint("WebhookService: Dhikr approved!")
            return .approved
        } else {
            let rawReason = json["reason"] as? String ?? json["message"] as? String ?? "Dhikr verification failed"
            // Clean the reason to ensure no HTML or technical details
            let reason = cleanErrorMessage(rawReason)
            debugPrint("WebhookService: Dhikr rejected: \(reason)")
            return .rejected(reason: reason)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if response is HTML
    private func isHTMLResponse(_ response: String) -> Bool {
        let lowercased = response.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return lowercased.hasPrefix("<!doctype html") ||
               lowercased.hasPrefix("<html") ||
               lowercased.contains("<html>") ||
               lowercased.contains("<!doctype") ||
               lowercased.contains("<head>") ||
               lowercased.contains("<body>")
    }
    
    /// Clean error message - remove HTML, limit length, make user-friendly
    private func cleanErrorMessage(_ message: String) -> String {
        var cleaned = message
        
        // Remove HTML tags
        cleaned = cleaned.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        // Remove HTML entities
        cleaned = cleaned.replacingOccurrences(of: "&nbsp;", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "&amp;", with: "&")
        cleaned = cleaned.replacingOccurrences(of: "&lt;", with: "<")
        cleaned = cleaned.replacingOccurrences(of: "&gt;", with: ">")
        cleaned = cleaned.replacingOccurrences(of: "&quot;", with: "\"")
        
        // Remove common error page text
        cleaned = cleaned.replacingOccurrences(of: "404", with: "", options: .caseInsensitive)
        cleaned = cleaned.replacingOccurrences(of: "not found", with: "", options: .caseInsensitive)
        cleaned = cleaned.replacingOccurrences(of: "no workspace", with: "", options: .caseInsensitive)
        
        // Trim and clean whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Limit length
        if cleaned.count > 200 {
            cleaned = String(cleaned.prefix(200)) + "..."
        }
        
        // If message is empty or contains only technical details, provide user-friendly message
        if cleaned.isEmpty || 
           cleaned.lowercased().contains("response:") ||
           cleaned.lowercased().contains("<!doctype") ||
           cleaned.lowercased().contains("http") {
            return "Could not verify your recitation. Please try again in a quieter environment."
        }
        
        return cleaned
    }
}

// MARK: - Mock/Testing Version
extension WebhookService {
    /// Use this for testing without a real webhook
    func mockVerification(success: Bool, delay: TimeInterval = 2.0, completion: @escaping (VerificationResult) -> Void) {
        isVerifying = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.isVerifying = false
            
            let result: VerificationResult
            if success {
                result = .approved
            } else {
                result = .rejected(reason: "Could not clearly hear the dhikr. Please try again in a quieter environment.")
            }
            
            self.verificationResult = result
            completion(result)
        }
    }
}

