import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var store: BudgetStore
    @State private var month = Calendar.current.component(.month, from: Date())
    @State private var year  = Calendar.current.component(.year,  from: Date())

    private var totalSpent:  Double { store.totalSpent(month: month, year: year) }
    private var totalIncome: Double { store.totalIncome(month: month, year: year) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Month nav
                    monthPickerRow
                        .padding(.horizontal)

                    // Monthly summary card
                    summaryCard
                        .padding(.horizontal)

                    // Bank balance cards
                    if !store.linkedAccounts.isEmpty {
                        ForEach(store.linkedAccounts) { account in
                            BankBalanceCard(account: account)
                                .padding(.horizontal)
                        }
                    }

                    // Active cash trip
                    if let trip = store.activeCashBudget() {
                        CashBudgetCard(budget: trip)
                            .padding(.horizontal)
                    }

                    // Spending donut chart
                    spendingChart
                        .padding(.horizontal)

                    // Budget progress rows
                    budgetProgressSection
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Sub-views

    private var monthPickerRow: some View {
        HStack {
            Button {
                if month == 1 { month = 12; year -= 1 } else { month -= 1 }
            } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(monthYearLabel).font(.headline)
            Spacer()
            Button {
                if month == 12 { month = 1; year += 1 } else { month += 1 }
            } label: { Image(systemName: "chevron.right") }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            summaryCell(title: "Spent",  value: totalSpent,  color: .primary)
            Divider().frame(height: 40)
            summaryCell(title: "Income", value: totalIncome, color: .green)
            Divider().frame(height: 40)
            summaryCell(title: "Net",    value: totalIncome - totalSpent, color: totalIncome >= totalSpent ? .green : .red)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private func summaryCell(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("$\(String(format: "%.0f", abs(value)))")
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var spendingChart: some View {
        let data = store.categories.filter { $0.name != "Income" }.compactMap { cat -> (name: String, amount: Double, color: Color)? in
            let s = store.spent(in: cat.name, month: month, year: year)
            guard s > 0 else { return nil }
            return (cat.name, s, cat.color)
        }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Spending Breakdown")
                .font(.headline)

            if data.isEmpty {
                Text("No spending this month.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Chart(data, id: \.name) { item in
                    if #available(iOS 17.0, *) {
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.55),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.color)
                        .cornerRadius(4)
                    } else {
                        BarMark(x: .value("Category", item.name), y: .value("Amount", item.amount))
                            .foregroundStyle(item.color)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private var budgetProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget Progress")
                .font(.headline)

            ForEach(store.categories.filter { $0.name != "Income" }, id: \.id) { cat in
                let s    = store.spent(in: cat.name, month: month, year: year)
                let lim  = store.limit(for: cat.name, month: month, year: year)
                if s > 0 || lim != nil {
                    BudgetProgressRow(category: cat, spent: s, limit: lim)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private var monthYearLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        var c = DateComponents(); c.month = month; c.year = year
        return f.string(from: Calendar.current.date(from: c) ?? Date())
    }
}

struct BudgetProgressRow: View {
    let category: Category
    let spent: Double
    let limit: Double?

    private var progress: Double { limit.map { min(spent / $0, 1.0) } ?? 0 }
    private var isOver: Bool    { limit.map { spent > $0 } ?? false }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(category.name, systemImage: category.sfSymbol)
                    .foregroundStyle(category.color)
                    .font(.subheadline)
                Spacer()
                if let l = limit {
                    Text("$\(String(format: "%.0f", spent)) / $\(String(format: "%.0f", l))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(isOver ? .red : .secondary)
                } else {
                    Text("$\(String(format: "%.0f", spent))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            if limit != nil {
                ProgressView(value: progress)
                    .tint(isOver ? .red : progress > 0.8 ? .orange : .green)
            }
        }
    }
}
