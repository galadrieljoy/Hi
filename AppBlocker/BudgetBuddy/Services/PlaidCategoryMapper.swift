import Foundation

/// Maps Plaid's category hierarchy to BudgetBuddy category names.
enum PlaidCategoryMapper {
    static func map(_ plaidCategories: [String]) -> String {
        let top = plaidCategories.first?.lowercased() ?? ""
        let sub = plaidCategories.dropFirst().first?.lowercased() ?? ""

        switch top {
        case "food and drink":
            return "Food"
        case "travel":
            if sub.contains("taxi") || sub.contains("uber") || sub.contains("lyft") || sub.contains("transit") {
                return "Transport"
            }
            if sub.contains("hotel") || sub.contains("lodging") || sub.contains("airbnb") {
                return "Accommodation"
            }
            return "Activities"
        case "transportation":
            return "Transport"
        case "shops", "shopping":
            return "Shopping"
        case "recreation", "entertainment":
            return "Entertainment"
        case "healthcare", "medical":
            return "Health"
        case "service":
            if sub.contains("subscription") || sub.contains("streaming") {
                return "Entertainment"
            }
            return "Other"
        case "transfer", "payment":
            if sub.contains("payroll") || sub.contains("deposit") {
                return "Income"
            }
            return "Other"
        default:
            return "Other"
        }
    }
}
