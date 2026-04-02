import SwiftUI
import Charts

struct ContributionHistoryView: View {
    @EnvironmentObject var store: BudgetStore
    let account: InvestmentAccount

    private var history: [(label: String, total: Double)] {
        store.contributionHistory(for: account.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Total invested header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Invested")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(String(format: "%.2f", store.totalContributed(to: account.id)))")
                        .font(.largeTitle.bold().monospacedDigit())
                }
                .padding(.horizontal)

                // Line chart
                if history.count >= 2 {
                    Chart(history, id: \.label) { item in
                        LineMark(x: .value("Month", item.label), y: .value("Amount", item.total))
                            .foregroundStyle(Color(hex: account.colorHex))
                        PointMark(x: .value("Month", item.label), y: .value("Amount", item.total))
                            .foregroundStyle(Color(hex: account.colorHex))
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                } else {
                    Text("Add more contributions to see your history chart.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                // Contribution list
                LazyVStack(spacing: 0) {
                    ForEach(store.investmentContributions.filter { $0.accountID == account.id }
                                .sorted { $0.date > $1.date }, id: \.id) { c in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.date, style: .date).font(.subheadline)
                                if !c.note.isEmpty { Text(c.note).font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            Text("+$\(String(format: "%.2f", c.amount))")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        Divider().padding(.leading)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
