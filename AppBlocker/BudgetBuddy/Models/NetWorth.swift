import Foundation

enum AssetType: String, Codable, CaseIterable {
    case bankAccount = "Bank Account"
    case investment  = "Investment"
    case property    = "Property"
    case vehicle     = "Vehicle"
    case other       = "Other"

    var sfSymbol: String {
        switch self {
        case .bankAccount: return "building.columns.fill"
        case .investment:  return "chart.line.uptrend.xyaxis"
        case .property:    return "house.fill"
        case .vehicle:     return "car.fill"
        case .other:       return "briefcase.fill"
        }
    }
}

enum LiabilityType: String, Codable, CaseIterable {
    case creditCard  = "Credit Card"
    case studentLoan = "Student Loan"
    case autoLoan    = "Auto Loan"
    case mortgage    = "Mortgage"
    case other       = "Other"

    var sfSymbol: String {
        switch self {
        case .creditCard:  return "creditcard.fill"
        case .studentLoan: return "graduationcap.fill"
        case .autoLoan:    return "car.fill"
        case .mortgage:    return "house.fill"
        case .other:       return "doc.fill"
        }
    }
}

struct Asset: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: AssetType
    var value: Double
    var lastUpdated: Date

    init(id: UUID = UUID(), name: String, type: AssetType, value: Double, lastUpdated: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.value = value
        self.lastUpdated = lastUpdated
    }
}

struct Liability: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: LiabilityType
    var balance: Double
    var lastUpdated: Date

    init(id: UUID = UUID(), name: String, type: LiabilityType, balance: Double, lastUpdated: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.lastUpdated = lastUpdated
    }
}

struct NetWorthSnapshot: Identifiable, Codable {
    var id: UUID
    var date: Date
    var totalAssets: Double
    var totalLiabilities: Double

    var netWorth: Double { totalAssets - totalLiabilities }

    init(id: UUID = UUID(), date: Date = Date(), totalAssets: Double, totalLiabilities: Double) {
        self.id = id
        self.date = date
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
    }
}
