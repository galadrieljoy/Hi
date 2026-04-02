import SwiftUI

struct AddSubscriptionView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    var existing: Subscription?

    @State private var name                  = ""
    @State private var amount                = 0.0
    @State private var categoryName          = "Entertainment"
    @State private var frequency             = BillingFrequency.monthly
    @State private var billingDay            = 1
    @State private var billingMonth          = 1
    @State private var autoAdd               = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    TextField("Name (e.g. Netflix)", text: $name)
                    CurrencyTextField(label: "Amount", value: $amount)
                    CategoryPickerView(selected: $categoryName)
                }
                Section("Billing") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(BillingFrequency.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    Stepper("Billing day: \(billingDay)", value: $billingDay, in: 1...28)
                    if frequency == .annual {
                        Picker("Billing month", selection: $billingMonth) {
                            ForEach(1...12, id: \.self) { m in
                                Text(DateFormatter().monthSymbols[m - 1]).tag(m)
                            }
                        }
                    }
                }
                Section {
                    Toggle("Auto-add to transactions", isOn: $autoAdd)
                } footer: {
                    Text("Automatically records a transaction on the billing date.")
                }
            }
            .navigationTitle(existing == nil ? "Add Subscription" : "Edit Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.isEmpty || amount <= 0)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let s = existing else { return }
        name         = s.name
        amount       = s.amount
        categoryName = s.categoryName
        frequency    = s.frequency
        billingDay   = s.billingDay
        billingMonth = s.billingMonth ?? 1
        autoAdd      = s.autoAddToTransactions
    }

    private func save() {
        var sub = Subscription(
            id:           existing?.id ?? UUID(),
            name:         name,
            amount:       amount,
            categoryName: categoryName,
            frequency:    frequency,
            billingDay:   billingDay,
            billingMonth: frequency == .annual ? billingMonth : nil,
            autoAddToTransactions: autoAdd
        )
        if existing != nil { store.updateSubscription(sub) } else { store.addSubscription(sub) }
        dismiss()
    }
}
