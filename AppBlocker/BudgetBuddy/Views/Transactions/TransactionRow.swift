import SwiftUI

struct TransactionRow: View {
    @EnvironmentObject var store: BudgetStore
    let transaction: Transaction

    private var category: Category? {
        store.categories.first { $0.name == transaction.categoryName }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((category?.color ?? .gray).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: category?.sfSymbol ?? "questionmark")
                    .foregroundStyle(category?.color ?? .gray)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.body)
                HStack(spacing: 4) {
                    Text(transaction.categoryName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if transaction.paymentMethod == .cash {
                        Text("· Cash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.type == .income ? "+$\(String(format: "%.2f", transaction.amount))"
                                                 : "-$\(String(format: "%.2f", transaction.amount))")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(transaction.type == .income ? .green : .primary)
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
