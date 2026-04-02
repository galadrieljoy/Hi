import SwiftUI

struct AddContributionView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    var preselectedAccount: InvestmentAccount?

    @State private var selectedAccountID: UUID?
    @State private var amount = 0.0
    @State private var date   = Date()
    @State private var note   = ""

    var body: some View {
        NavigationStack {
            Form {
                if preselectedAccount == nil {
                    Section("Account") {
                        Picker("Account", selection: $selectedAccountID) {
                            Text("Select…").tag(Optional<UUID>.none)
                            ForEach(store.investmentAccounts) { a in
                                Text(a.name).tag(Optional(a.id))
                            }
                        }
                    }
                }
                Section("Contribution") {
                    CurrencyTextField(label: "Amount", value: $amount)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note (optional)", text: $note)
                }
            }
            .navigationTitle("Log Contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(amount <= 0 || (preselectedAccount == nil && selectedAccountID == nil))
                }
            }
            .onAppear {
                selectedAccountID = preselectedAccount?.id ?? store.investmentAccounts.first?.id
            }
        }
    }

    private func save() {
        guard let acctID = preselectedAccount?.id ?? selectedAccountID else { return }
        store.addContribution(InvestmentContribution(accountID: acctID, date: date, amount: amount, note: note))
        dismiss()
    }
}
