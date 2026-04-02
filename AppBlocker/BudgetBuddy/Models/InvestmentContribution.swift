import Foundation

struct InvestmentContribution: Identifiable, Codable {
    var id: UUID
    var accountID: UUID
    var date: Date
    var amount: Double
    var note: String

    init(id: UUID = UUID(), accountID: UUID, date: Date = Date(), amount: Double, note: String = "") {
        self.id = id
        self.accountID = accountID
        self.date = date
        self.amount = amount
        self.note = note
    }
}
