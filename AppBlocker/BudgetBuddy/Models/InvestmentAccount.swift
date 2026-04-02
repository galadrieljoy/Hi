import Foundation

enum AccountType: String, Codable, CaseIterable {
    case retirement401k  = "401k"
    case rothIRA         = "Roth IRA"
    case traditionalIRA  = "Traditional IRA"
    case brokerage       = "Brokerage"
    case hsa             = "HSA"
    case savingsAccount  = "Savings"
    case other           = "Other"
}

struct InvestmentAccount: Identifiable, Codable {
    var id: UUID
    var name: String
    var accountType: AccountType
    var monthlyGoal: Double
    var colorHex: String

    init(id: UUID = UUID(), name: String, accountType: AccountType, monthlyGoal: Double, colorHex: String = "#4A90D9") {
        self.id = id
        self.name = name
        self.accountType = accountType
        self.monthlyGoal = monthlyGoal
        self.colorHex = colorHex
    }
}
