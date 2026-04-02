import SwiftUI

struct AddLiabilityView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss
    var existing: Liability?

    @State private var name    = ""
    @State private var type    = LiabilityType.other
    @State private var balance = 0.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Liability") {
                    TextField("Name (e.g. Student Loan)", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(LiabilityType.allCases, id: \.self) {
                            Label($0.rawValue, systemImage: $0.sfSymbol).tag($0)
                        }
                    }
                    CurrencyTextField(label: "Balance owed", value: $balance)
                }
            }
            .navigationTitle(existing == nil ? "Add Liability" : "Edit Liability")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let l = Liability(id: existing?.id ?? UUID(), name: name, type: type, balance: balance)
                        if existing != nil { store.updateLiability(l) } else { store.addLiability(l) }
                        dismiss()
                    }.disabled(name.isEmpty || balance <= 0)
                }
            }
            .onAppear {
                if let l = existing { name = l.name; type = l.type; balance = l.balance }
            }
        }
    }
}
