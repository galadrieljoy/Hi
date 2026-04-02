import Foundation

/// Communicates with the companion Plaid backend server.
/// No Plaid credentials are stored on device — all sensitive operations go through the backend.
actor PlaidService {
    static let shared = PlaidService()

    // MARK: - Backend API

    struct LinkTokenResponse: Decodable { let link_token: String }
    struct ExchangeResponse:  Decodable { let item_id: String }
    struct BalanceResponse:   Decodable { let balance: Double; let account_name: String; let institution_name: String }

    struct PlaidTransactionResponse: Decodable {
        let transaction_id: String
        let name: String
        let amount: Double
        let date: String
        let category: [String]
    }

    func createLinkToken(serverURL: String) async throws -> String {
        let url  = try makeURL(serverURL, path: "/create_link_token")
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(LinkTokenResponse.self, from: data).link_token
    }

    func exchangePublicToken(_ publicToken: String, serverURL: String) async throws -> String {
        let url  = try makeURL(serverURL, path: "/exchange_token")
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody   = try JSONEncoder().encode(["public_token": publicToken])
        let (data, _)  = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(ExchangeResponse.self, from: data).item_id
    }

    func fetchBalance(itemID: String, serverURL: String) async throws -> BalanceResponse {
        var components    = URLComponents(string: serverURL + "/balance")!
        components.queryItems = [URLQueryItem(name: "item_id", value: itemID)]
        let (data, _)     = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode(BalanceResponse.self, from: data)
    }

    func fetchTransactions(itemID: String, since: Date, serverURL: String) async throws -> [PlaidTransactionResponse] {
        let formatter     = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startStr      = formatter.string(from: since)
        let endStr        = formatter.string(from: Date())
        var components    = URLComponents(string: serverURL + "/transactions")!
        components.queryItems = [
            URLQueryItem(name: "item_id", value: itemID),
            URLQueryItem(name: "start",   value: startStr),
            URLQueryItem(name: "end",     value: endStr),
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([PlaidTransactionResponse].self, from: data)
    }

    // MARK: - Helpers

    private func makeURL(_ base: String, path: String) throws -> URL {
        guard let url = URL(string: base + path) else {
            throw URLError(.badURL)
        }
        return url
    }

    // MARK: - Convert to app transactions

    func toTransactions(_ plaidTxns: [PlaidTransactionResponse]) -> [Transaction] {
        let formatter  = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return plaidTxns.map { p in
            let date  = formatter.date(from: p.date) ?? Date()
            let cat   = PlaidCategoryMapper.map(p.category)
            // Plaid: positive amount = debit (money out), negative = credit (money in)
            let type: TransactionType = p.amount < 0 ? .income : .expense
            return Transaction(
                date:          date,
                amount:        abs(p.amount),
                type:          type,
                categoryName:  cat,
                title:         p.name,
                paymentMethod: .card,
                plaidID:       p.transaction_id
            )
        }
    }
}
