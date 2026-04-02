import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    var existing: Transaction?

    @State private var title         = ""
    @State private var amount        = 0.0
    @State private var type          = TransactionType.expense
    @State private var categoryName  = "Food"
    @State private var date          = Date()
    @State private var note          = ""
    @State private var paymentMethod = PaymentMethod.card

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    CurrencyTextField(label: "Amount", value: $amount)
                    Picker("Type", selection: $type) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Category & Payment") {
                    CategoryPickerView(selected: $categoryName)
                    Picker("Payment", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Date & Note") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note (optional)", text: $note)
                }
            }
            .navigationTitle(existing == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.isEmpty || amount <= 0)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let t = existing else { return }
        title         = t.title
        amount        = t.amount
        type          = t.type
        categoryName  = t.categoryName
        date          = t.date
        note          = t.note
        paymentMethod = t.paymentMethod
    }

    private func save() {
        if let t = existing {
            store.update(Transaction(id: t.id, date: date, amount: amount, type: type,
                                     categoryName: categoryName, title: title, note: note,
                                     paymentMethod: paymentMethod, plaidID: t.plaidID))
        } else {
            store.add(Transaction(date: date, amount: amount, type: type,
                                   categoryName: categoryName, title: title, note: note,
                                   paymentMethod: paymentMethod))
        }
        dismiss()
    }
}
