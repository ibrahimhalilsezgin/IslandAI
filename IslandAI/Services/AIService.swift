import Foundation

public enum AIServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case noChoices

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL yapılandırması."
        case .invalidResponse:
            return "Sunucudan geçersiz yanıt alındı."
        case .apiError(let message):
            return "API Hatası: \(message)"
        case .noChoices:
            return "Yanıt içeriği bulunamadı."
        }
    }
}

public class AIService {
    public init() {}

    public func sendMessage(messages: [ChatMessage], baseURL: String, apiKey: String, model: String, systemPrompt: String) async throws -> String {
        var trimmedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedBaseURL.hasSuffix("/") {
            trimmedBaseURL.removeLast()
        }

        guard let url = URL(string: "\(trimmedBaseURL)/chat/completions") else {
            throw AIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        var apiMessages: [[String: String]] = []

        if !systemPrompt.isEmpty {
            apiMessages.append(["role": "system", "content": systemPrompt])
        }

        for msg in messages {
            apiMessages.append(["role": msg.role.rawValue, "content": msg.content])
        }

        let payload: [String: Any] = [
            "model": model,
            "messages": apiMessages,
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = errorJson["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                throw AIServiceError.apiError("\(httpResponse.statusCode) - \(message)")
            }
            throw AIServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let messageObj = firstChoice["message"] as? [String: Any],
              let content = messageObj["content"] as? String else {
            throw AIServiceError.noChoices
        }

        return content
    }
}
