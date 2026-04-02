import SwiftUI

struct Category: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var sfSymbol: String
    var colorHex: String
    var isSystem: Bool

    var color: Color { Color(hex: colorHex) }

    static let systemCategories: [Category] = [
        Category(id: UUID(), name: "Food",           sfSymbol: "fork.knife",          colorHex: "#FF6B35", isSystem: true),
        Category(id: UUID(), name: "Rent",           sfSymbol: "house.fill",          colorHex: "#4A90D9", isSystem: true),
        Category(id: UUID(), name: "Transport",      sfSymbol: "car.fill",            colorHex: "#7B68EE", isSystem: true),
        Category(id: UUID(), name: "Entertainment",  sfSymbol: "tv.fill",             colorHex: "#FF69B4", isSystem: true),
        Category(id: UUID(), name: "Health",         sfSymbol: "heart.fill",          colorHex: "#E74C3C", isSystem: true),
        Category(id: UUID(), name: "Shopping",       sfSymbol: "bag.fill",            colorHex: "#2ECC71", isSystem: true),
        Category(id: UUID(), name: "Activities",     sfSymbol: "figure.hiking",       colorHex: "#27AE60", isSystem: true),
        Category(id: UUID(), name: "Accommodation",  sfSymbol: "bed.double.fill",     colorHex: "#8E44AD", isSystem: true),
        Category(id: UUID(), name: "Utilities",      sfSymbol: "bolt.fill",           colorHex: "#F39C12", isSystem: true),
        Category(id: UUID(), name: "Income",         sfSymbol: "dollarsign.circle.fill", colorHex: "#1ABC9C", isSystem: true),
        Category(id: UUID(), name: "Other",          sfSymbol: "ellipsis.circle.fill",   colorHex: "#95A5A6", isSystem: true),
    ]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)         / 255
        self.init(red: r, green: g, blue: b)
    }
}
