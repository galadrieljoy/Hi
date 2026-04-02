import SwiftUI

struct SetBudgetView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    let categoryName: String
    let month: Int
    let year: Int

    @State private var limitAmount = 0.0

    private var existing: BudgetLimit? {
        store.budgetLimits.first { $0.categoryName == categoryName && $0.month == month && $0.year == year }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Monthly Limit for \(categoryName)") {
                    CurrencyTextField(label: "Limit", value: $limitAmount)
                }
            }
            .navigationTitle("Set Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setLimit(BudgetLimit(categoryName: categoryName, monthlyLimit: limitAmount,
                                                    month: month, year: year))
                        dismiss()
                    }
                    .disabled(limitAmount <= 0)
                }
            }
            .onAppear { limitAmount = existing?.monthlyLimit ?? 0 }
        }
    }
}
