import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case expense = "expense"
    case income  = "income"
}

struct Transaction: Identifiable, Codable {
    var id: UUID
    var date: Date
    var amount: Double
    var type: TransactionType
    var categoryName: String
    var title: String
    var note: String
    var paymentMethod: PaymentMethod
    var plaidID: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Double,
        type: TransactionType = .expense,
        categoryName: String,
        title: String,
        note: String = "",
        paymentMethod: PaymentMethod = .card,
        plaidID: String? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.type = type
        self.categoryName = categoryName
        self.title = title
        self.note = note
        self.paymentMethod = paymentMethod
        self.plaidID = plaidID
    }
}
