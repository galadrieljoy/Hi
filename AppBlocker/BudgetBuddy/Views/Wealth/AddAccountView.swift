import SwiftUI

struct AddAccountView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    var existing: InvestmentAccount?

    private let palette = ["#4A90D9","#E74C3C","#2ECC71","#F39C12","#8E44AD","#1ABC9C","#FF6B35","#7B68EE"]

    @State private var name        = ""
    @State private var accountType = AccountType.brokerage
    @State private var monthlyGoal = 0.0
    @State private var colorHex    = "#4A90D9"

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Name (e.g. Fidelity 401k)", text: $name)
                    Picker("Type", selection: $accountType) {
                        ForEach(AccountType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    CurrencyTextField(label: "Monthly goal", value: $monthlyGoal)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 8), spacing: 8) {
                        ForEach(palette, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay(Circle().stroke(Color.white, lineWidth: colorHex == hex ? 3 : 0))
                                .shadow(radius: colorHex == hex ? 2 : 0)
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(existing == nil ? "Add Account" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let a = existing { name = a.name; accountType = a.accountType; monthlyGoal = a.monthlyGoal; colorHex = a.colorHex }
            }
        }
    }

    private func save() {
        let acct = InvestmentAccount(id: existing?.id ?? UUID(), name: name, accountType: accountType,
                                      monthlyGoal: monthlyGoal, colorHex: colorHex)
        if existing != nil { store.updateAccount(acct) } else { store.addAccount(acct) }
        dismiss()
    }
}
