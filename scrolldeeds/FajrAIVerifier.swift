import Foundation
import UIKit

/// Cheap Fajr photo check: OpenAI `gpt-4o-mini` with low-detail JPEGs.
/// Cost is typically well under a cent per attempt (two tiny images + a short reply).
enum FajrAIVerifier {
    private static let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    static var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "NafsiOpenAIAPIKey") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static var isConfigured: Bool { !apiKey.isEmpty }

    static func matchesObject(capture: UIImage, objectName: String) async -> Bool? {
        guard isConfigured, let captureData = jpegData(capture) else { return nil }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 14
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let prompt = """
        You verify a Fajr wake-up photo for a Muslim app.
        The user chose this object: \(objectName).
        The image is a photo taken now to stop the alarm.
        Reply with JSON only: {"match":true} or {"match":false}
        true = the photo clearly shows that kind of real-world object.
        false = different object, a person, a screen, or an unclear photo.
        """

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "temperature": 0,
            "max_tokens": 24,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    imagePart(captureData)
                ]
            ]]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return await sendMatchRequest(request)
    }

    static func matches(capture: UIImage, reference: UIImage, objectName: String) async -> Bool? {
        guard isConfigured else { return nil }
        guard
            let captureData = jpegData(capture),
            let referenceData = jpegData(reference)
        else { return nil }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 14
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let prompt = """
        You verify a Fajr wake-up photo for a Muslim app.
        Image 1 is the enrolled object: \(objectName).
        Image 2 is a new photo taken now.
        Reply with JSON only: {"match":true} or {"match":false}
        true = image 2 shows the same kind of object and could reasonably be the same item.
        false = different object, wrong room, person, screen, or unclear photo.
        """

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "temperature": 0,
            "max_tokens": 24,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    imagePart(referenceData),
                    imagePart(captureData)
                ]
            ]]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return await sendMatchRequest(request)
    }

    private static func sendMatchRequest(_ request: URLRequest) async -> Bool? {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            return parseMatch(data)
        } catch {
            return nil
        }
    }

    private static func imagePart(_ jpeg: Data) -> [String: Any] {
        [
            "type": "image_url",
            "image_url": [
                "url": "data:image/jpeg;base64,\(jpeg.base64EncodedString())",
                "detail": "low"
            ]
        ]
    }

    private static func jpegData(_ image: UIImage) -> Data? {
        let maxSide: CGFloat = 384
        let width = max(image.size.width, 1)
        let height = max(image.size.height, 1)
        let scale = min(1, maxSide / max(width, height))
        let size = CGSize(width: width * scale, height: height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return rendered.jpegData(compressionQuality: 0.38)
    }

    private static func parseMatch(_ data: Data) -> Bool? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { return nil }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let inner = try? JSONSerialization.jsonObject(with: Data(trimmed.utf8)) as? [String: Any],
           let match = inner["match"] as? Bool {
            return match
        }
        let lower = trimmed.lowercased()
        if lower.contains("\"match\":true") || lower.contains("\"match\": true") { return true }
        if lower.contains("\"match\":false") || lower.contains("\"match\": false") { return false }
        return nil
    }
}
