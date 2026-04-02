import SwiftUI

struct InvestmentAccountRow: View {
    @EnvironmentObject var store: BudgetStore
    let account: InvestmentAccount

    private var month: Int { Calendar.current.component(.month, from: Date()) }
    private var year:  Int { Calendar.current.component(.year,  from: Date()) }

    private var contributed: Double { store.contributed(to: account.id, month: month, year: year) }
    private var progress: Double    { account.monthlyGoal > 0 ? min(contributed / account.monthlyGoal, 1.0) : 0 }
    private var isGoalMet: Bool     { contributed >= account.monthlyGoal && account.monthlyGoal > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(Color(hex: account.colorHex).opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(account.accountType.rawValue.prefix(3))
                            .font(.caption2.bold())
                            .foregroundStyle(Color(hex: account.colorHex))
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(account.name).font(.body)
                    Text(account.accountType.rawValue).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("$\(String(format: "%.0f", contributed)) / $\(String(format: "%.0f", account.monthlyGoal))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(isGoalMet ? .green : .secondary)
                    if isGoalMet { Text("Goal met ✓").font(.caption2).foregroundStyle(.green) }
                }
            }
            if account.monthlyGoal > 0 {
                ProgressView(value: progress)
                    .tint(isGoalMet ? .green : Color(hex: account.colorHex))
            }
        }
    }
}
