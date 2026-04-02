import Foundation

struct BudgetLimit: Identifiable, Codable {
    var id: UUID
    var categoryName: String
    var monthlyLimit: Double
    var month: Int
    var year: Int

    init(id: UUID = UUID(), categoryName: String, monthlyLimit: Double, month: Int, year: Int) {
        self.id = id
        self.categoryName = categoryName
        self.monthlyLimit = monthlyLimit
        self.month = month
        self.year = year
    }
}
