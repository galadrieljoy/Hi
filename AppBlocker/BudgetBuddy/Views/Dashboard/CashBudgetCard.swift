import SwiftUI

struct CashBudgetCard: View {
    @EnvironmentObject var store: BudgetStore
    let budget: CashBudget

    private var week: Int { BudgetStore.weekNumber(for: Date(), startDate: budget.startDate) }
    private var spent: Double { store.cashSpentThisWeek(of: budget) }
    private var progress: Double { min(spent / budget.weeklyLimit, 1.0) }
    private var isOver: Bool { spent > budget.weeklyLimit }
    private var breakdown: [(category: String, total: Double)] { store.cashBreakdown(of: budget, weekNumber: week) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(budget.tripName)
                        .font(.headline)
                    Text("Week \(week)\(totalWeeks.map { " of \($0)" } ?? "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "suitcase.fill")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Cash this week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", spent)) / $\(String(format: "%.2f", budget.weeklyLimit))")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(isOver ? .red : .primary)
                }
                ProgressView(value: progress)
                    .tint(isOver ? .red : progress > 0.8 ? .orange : .green)
            }

            if !breakdown.isEmpty {
                HStack(spacing: 4) {
                    ForEach(breakdown.prefix(3), id: \.category) { item in
                        Text("\(item.category) $\(String(format: "%.0f", item.total))")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private var totalWeeks: Int? {
        guard let end = budget.endDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: budget.startDate, to: end).day ?? 0
        return max(1, (days + 6) / 7)
    }
}
