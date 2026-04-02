import Foundation

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "cash"
    case card = "card"

    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .card: return "Card"
        }
    }
}
