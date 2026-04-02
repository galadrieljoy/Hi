import SwiftUI

struct SetCashBudgetView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    var existing: CashBudget?

    @State private var tripName    = ""
    @State private var weeklyLimit = 0.0
    @State private var startDate   = Date()
    @State private var hasEndDate  = false
    @State private var endDate     = Date().addingTimeInterval(14 * 86400)

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip name (e.g. Costa Rica)", text: $tripName)
                    CurrencyTextField(label: "Weekly cash budget", value: $weeklyLimit)
                }
                Section("Dates") {
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                    Toggle("Set end date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("End date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(existing == nil ? "New Cash Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(tripName.isEmpty || weeklyLimit <= 0)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let b = existing else { return }
        tripName    = b.tripName
        weeklyLimit = b.weeklyLimit
        startDate   = b.startDate
        if let end  = b.endDate { hasEndDate = true; endDate = end }
    }

    private func save() {
        let budget = CashBudget(
            id:          existing?.id ?? UUID(),
            tripName:    tripName,
            weeklyLimit: weeklyLimit,
            startDate:   startDate,
            endDate:     hasEndDate ? endDate : nil
        )
        if existing != nil { store.updateCashBudget(budget) } else { store.addCashBudget(budget) }
        dismiss()
    }
}
