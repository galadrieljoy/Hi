import Foundation

enum BillingFrequency: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case annual  = "Annual"

    var displayName: String { rawValue }
}

struct Subscription: Identifiable, Codable {
    var id: UUID
    var name: String
    var amount: Double
    var categoryName: String
    var frequency: BillingFrequency
    var billingDay: Int        // day of month 1–28
    var billingMonth: Int?     // 1–12, only used for annual
    var isActive: Bool
    var autoAddToTransactions: Bool
    var nextBillingDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        categoryName: String = "Entertainment",
        frequency: BillingFrequency = .monthly,
        billingDay: Int = 1,
        billingMonth: Int? = nil,
        isActive: Bool = true,
        autoAddToTransactions: Bool = true
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.categoryName = categoryName
        self.frequency = frequency
        self.billingDay = billingDay
        self.billingMonth = billingMonth
        self.isActive = isActive
        self.autoAddToTransactions = autoAddToTransactions
        self.nextBillingDate = Subscription.computeNextBillingDate(
            frequency: frequency, billingDay: billingDay, billingMonth: billingMonth
        )
    }

    static func computeNextBillingDate(frequency: BillingFrequency, billingDay: Int, billingMonth: Int?) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let today = Calendar.current.startOfDay(for: Date())

        switch frequency {
        case .monthly:
            components.day = billingDay
            if let candidate = Calendar.current.date(from: components), candidate >= today {
                return candidate
            }
            // Move to next month
            components.month = (components.month ?? 1) + 1
            return Calendar.current.date(from: components) ?? Date()

        case .annual:
            components.month = billingMonth ?? 1
            components.day   = billingDay
            if let candidate = Calendar.current.date(from: components), candidate >= today {
                return candidate
            }
            components.year = (components.year ?? 2026) + 1
            return Calendar.current.date(from: components) ?? Date()
        }
    }

    mutating func advanceToNextCycle() {
        switch frequency {
        case .monthly:
            nextBillingDate = Calendar.current.date(byAdding: .month, value: 1, to: nextBillingDate) ?? nextBillingDate
        case .annual:
            nextBillingDate = Calendar.current.date(byAdding: .year, value: 1, to: nextBillingDate) ?? nextBillingDate
        }
    }

    var monthlyEquivalentCost: Double {
        switch frequency {
        case .monthly: return amount
        case .annual:  return amount / 12.0
        }
    }
}
