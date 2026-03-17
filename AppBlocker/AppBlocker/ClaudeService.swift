import Foundation

/// Talks to the Anthropic API and decides whether the user may override their block.
actor ClaudeService {

    static let shared = ClaudeService()

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model  = "claude-sonnet-4-6"

    // MARK: - System prompt

    /// This prompt defines Claude's role as a strict-but-fair accountability partner.
    private let systemPrompt = """
    You are an accountability coach built into an app blocker. \
    The user has voluntarily set up app-blocking to help themselves focus or build healthier habits. \
    They are now asking you to override (unlock) their blocked apps early.

    Your job:
    1. Have a SHORT conversation (1-3 exchanges) to understand why they want to unlock early.
    2. Be empathetic but firm. It is okay to say no if the reason isn't compelling.
    3. Good reasons to approve: genuine emergency, work requirement, done with scheduled task early.
    4. Bad reasons to approve: boredom, "just for a minute", social pressure, vague excuses.
    5. When you decide, end your message with EXACTLY one of these tokens on its own line:
       [OVERRIDE_APPROVED] — if you are granting access
       [OVERRIDE_DENIED]   — if you are not granting access
    6. Do not include the token until you have enough information to make a decision.
    7. Keep your replies concise and conversational — this is a mobile app.
    """

    // MARK: - API call

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct RequestBody: Codable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]
    }

    struct ResponseBody: Codable {
        struct Content: Codable { let text: String }
        let content: [Content]
    }

    enum OverrideDecision {
        case approved
        case denied
        case pending   // Claude hasn't decided yet; keep chatting
    }

    struct ClaudeReply {
        let text: String
        let decision: OverrideDecision
    }

    /// Send the full conversation history and get Claude's next reply.
    func send(history: [Message], apiKey: String) async throws -> ClaudeReply {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json",       forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey,                   forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",             forHTTPHeaderField: "anthropic-version")

        let body = RequestBody(
            model: model,
            max_tokens: 512,
            system: systemPrompt,
            messages: history
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown error"
            throw ClaudeError.apiError(body)
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        let text = decoded.content.first?.text ?? ""

        let decision: OverrideDecision
        if text.contains("[OVERRIDE_APPROVED]") {
            decision = .approved
        } else if text.contains("[OVERRIDE_DENIED]") {
            decision = .denied
        } else {
            decision = .pending
        }

        // Strip the token from the visible text
        let cleanText = text
            .replacingOccurrences(of: "[OVERRIDE_APPROVED]", with: "")
            .replacingOccurrences(of: "[OVERRIDE_DENIED]",   with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return ClaudeReply(text: cleanText, decision: decision)
    }
}

enum ClaudeError: LocalizedError {
    case apiError(String)
    var errorDescription: String? {
        switch self {
        case .apiError(let msg): return "Claude API error: \(msg)"
        }
    }
}
