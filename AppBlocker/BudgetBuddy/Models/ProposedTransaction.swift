import Foundation

/// Ephemeral — created by Claude AI parsing, never persisted.
/// A UUID is only assigned when the user confirms and it becomes a full Transaction.
struct ProposedTransaction: Identifiable, Codable {
    var id: Int  // positional index within a proposal batch
    var title: String
    var amount: Double
    var category: String
    var paymentMethod: PaymentMethod
    var date: Date

    enum CodingKeys: String, CodingKey {
        case title, amount, category, paymentMethod, date
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title         = try c.decode(String.self,      forKey: .title)
        amount        = try c.decode(Double.self,       forKey: .amount)
        category      = try c.decode(String.self,      forKey: .category)
        paymentMethod = try c.decode(PaymentMethod.self, forKey: .paymentMethod)
        let dateStr   = try c.decode(String.self,      forKey: .date)
        date          = ProposedTransaction.dateFormatter.date(from: dateStr) ?? Date()
        id            = 0  // caller sets after decoding the array
    }

    init(id: Int, title: String, amount: Double, category: String, paymentMethod: PaymentMethod, date: Date) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.paymentMethod = paymentMethod
        self.date = date
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title,         forKey: .title)
        try c.encode(amount,        forKey: .amount)
        try c.encode(category,      forKey: .category)
        try c.encode(paymentMethod, forKey: .paymentMethod)
        try c.encode(ProposedTransaction.dateFormatter.string(from: date), forKey: .date)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
}
