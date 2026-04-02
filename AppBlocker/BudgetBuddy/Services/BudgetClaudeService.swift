import Foundation

enum BudgetClaudeError: Error {
    case apiError(String)
}

actor BudgetClaudeService {
    static let shared = BudgetClaudeService()

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model  = "claude-sonnet-4-6"

    // MARK: - Types (mirrors ClaudeService.swift pattern)

    struct Message: Codable {
        let role: String
        let content: String
    }

    private struct RequestBody: Codable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]
    }

    private struct ResponseBody: Codable {
        struct Content: Codable { let text: String }
        let content: [Content]
    }

    struct TripContext {
        let tripName: String
        let weeklyLimit: Double
        let currentWeek: Int
        let cashSpentThisWeek: Double
        let todayDateString: String
    }

    struct BudgetReply {
        let visibleText: String
        let proposedTransactions: [ProposedTransaction]?
    }

    // MARK: - System prompt

    private func buildSystemPrompt(tripContext: TripContext?, spendingContext: String) -> String {
        let today = tripContext?.todayDateString ?? {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
        }()

        var prompt = """
        You are a helpful budgeting assistant inside BudgetBuddy, a personal finance app.
        Help the user track spending, understand their budget, and make smart financial decisions.
        Keep your replies concise and mobile-friendly.

        When the user describes spending (e.g., "spent $25 at lunch and $10 on a taxi"), \
        parse each item and include a structured block at the END of your response:

        [PROPOSED_TRANSACTIONS]
        [{"title":"<name>","amount":<number>,"category":"<cat>","paymentMethod":"<method>","date":"<yyyy-MM-dd>"}]
        [/PROPOSED_TRANSACTIONS]

        Valid categories: Food, Transport, Shopping, Activities, Accommodation, Entertainment, Health, Utilities, Income, Other
        Valid paymentMethod values: "cash", "card"
        Always use today's date unless the user specifies otherwise.
        The JSON block must appear AFTER your conversational reply, on its own — never mention the tokens in your text.
        If the user is not describing spending (asking questions, requesting advice), omit the block entirely.
        Today's date is \(today).

        Current financial context:
        \(spendingContext)
        """

        if let trip = tripContext {
            let remaining = max(0, trip.weeklyLimit - trip.cashSpentThisWeek)
            prompt += """


        Active trip: \(trip.tripName)
        Weekly cash budget: $\(String(format: "%.2f", trip.weeklyLimit))
        Current week: \(trip.currentWeek)
        Cash spent this week so far: $\(String(format: "%.2f", trip.cashSpentThisWeek))
        Remaining this week: $\(String(format: "%.2f", remaining))

        Default all travel spending to paymentMethod "cash" unless the user says "by card" or "card".
        """
        }

        return prompt
    }

    // MARK: - Send

    func send(
        history: [Message],
        apiKey: String,
        tripContext: TripContext?,
        spendingContext: String
    ) async throws -> BudgetReply {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey,             forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")

        let body = RequestBody(
            model:      model,
            max_tokens: 1024,
            system:     buildSystemPrompt(tripContext: tripContext, spendingContext: spendingContext),
            messages:   history
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown error"
            throw BudgetClaudeError.apiError(msg)
        }

        let decoded  = try JSONDecoder().decode(ResponseBody.self, from: data)
        let rawText  = decoded.content.first?.text ?? ""
        return Self.extractProposals(from: rawText)
    }

    // MARK: - Token extraction (mirrors [OVERRIDE_APPROVED] pattern from ClaudeService.swift)

    static func extractProposals(from raw: String) -> BudgetReply {
        let openTag  = "[PROPOSED_TRANSACTIONS]"
        let closeTag = "[/PROPOSED_TRANSACTIONS]"

        guard
            let openRange  = raw.range(of: openTag),
            let closeRange = raw.range(of: closeTag),
            openRange.upperBound <= closeRange.lowerBound
        else {
            return BudgetReply(visibleText: raw.trimmingCharacters(in: .whitespacesAndNewlines), proposedTransactions: nil)
        }

        let visibleText = String(raw[raw.startIndex..<openRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let jsonStr = String(raw[openRange.upperBound..<closeRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let jsonData  = jsonStr.data(using: .utf8),
            var proposals = try? JSONDecoder().decode([ProposedTransaction].self, from: jsonData)
        else {
            return BudgetReply(visibleText: visibleText, proposedTransactions: nil)
        }

        for i in proposals.indices { proposals[i].id = i }
        return BudgetReply(visibleText: visibleText, proposedTransactions: proposals)
    }
}
