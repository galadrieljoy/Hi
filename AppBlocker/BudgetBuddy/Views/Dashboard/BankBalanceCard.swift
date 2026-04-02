import SwiftUI

struct BankBalanceCard: View {
    @EnvironmentObject var store: BudgetStore
    @AppStorage("lowBalanceThreshold") private var threshold = 500.0
    let account: LinkedAccount

    private var isLow: Bool { account.currentBalance < threshold }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.institutionName)
                        .font(.headline)
                    Text(account.accountName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "building.columns.fill")
                    .foregroundStyle(isLow ? .red : .blue)
            }

            Text("$\(String(format: "%.2f", account.currentBalance))")
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(isLow ? .red : .primary)

            if isLow {
                Label("Below your $\(Int(threshold)) alert threshold", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text("Synced \(account.lastSynced, style: .relative) ago")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(isLow ? Color.red.opacity(0.06) : Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isLow ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
