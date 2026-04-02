import Foundation

struct CashBudget: Identifiable, Codable {
    var id: UUID
    var tripName: String
    var weeklyLimit: Double
    var startDate: Date
    var endDate: Date?

    init(id: UUID = UUID(), tripName: String, weeklyLimit: Double, startDate: Date, endDate: Date? = nil) {
        self.id = id
        self.tripName = tripName
        self.weeklyLimit = weeklyLimit
        self.startDate = startDate
        self.endDate = endDate
    }
}
