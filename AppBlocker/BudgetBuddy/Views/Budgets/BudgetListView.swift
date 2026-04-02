import SwiftUI
import Charts

struct BudgetListView: View {
    @EnvironmentObject var store: BudgetStore
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear  = Calendar.current.component(.year,  from: Date())
    @State private var setBudgetFor: String?
    @State private var showAddCashBudget = false
    @State private var editCashBudget: CashBudget?
    @State private var showAddSubscription = false
    @State private var editSubscription: Subscription?

    var body: some View {
        NavigationStack {
            List {
                // Monthly category budgets
                Section("Monthly Budgets") {
                    ForEach(store.categories.filter { $0.name != "Income" }, id: \.id) { cat in
                        categoryRow(cat)
                    }
                }

                // Cash envelopes
                Section {
                    ForEach(store.cashBudgets) { budget in
                        CashBudgetCard(budget: budget)
                            .swipeActions {
                                Button(role: .destructive) { store.deleteCashBudget(budget) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { editCashBudget = budget } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    Button { showAddCashBudget = true } label: {
                        Label("New Cash Trip", systemImage: "plus")
                    }
                } header: {
                    Text("Cash Envelopes")
                }

                // Subscriptions
                Section {
                    ForEach(store.subscriptions) { sub in
                        subscriptionRow(sub)
                    }
                    Button { showAddSubscription = true } label: {
                        Label("Add Subscription", systemImage: "plus")
                    }
                    if !store.subscriptions.isEmpty {
                        HStack {
                            Text("Total monthly")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(String(format: "%.2f", store.totalMonthlySubscriptionCost()))/mo")
                                .font(.headline)
                        }
                    }
                } header: {
                    Text("Subscriptions")
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showAddCashBudget = true } label: { Label("New Cash Trip", systemImage: "dollarsign.circle") }
                        Button { showAddSubscription = true } label: { Label("Add Subscription", systemImage: "repeat") }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $setBudgetFor) { cat in
                SetBudgetView(categoryName: cat, month: selectedMonth, year: selectedYear)
            }
            .sheet(isPresented: $showAddCashBudget) { SetCashBudgetView() }
            .sheet(item: $editCashBudget) { b in SetCashBudgetView(existing: b) }
            .sheet(isPresented: $showAddSubscription) { AddSubscriptionView() }
            .sheet(item: $editSubscription) { s in AddSubscriptionView(existing: s) }
        }
    }

    private func categoryRow(_ cat: Category) -> some View {
        let s     = store.spent(in: cat.name, month: selectedMonth, year: selectedYear)
        let lim   = store.limit(for: cat.name, month: selectedMonth, year: selectedYear)
        let prog  = lim.map { min(s / $0, 1.0) } ?? 0

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(cat.name, systemImage: cat.sfSymbol)
                    .foregroundStyle(cat.color)
                Spacer()
                if let l = lim {
                    Text("$\(String(format: "%.0f", s)) / $\(String(format: "%.0f", l))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(prog > 1 ? .red : .secondary)
                } else {
                    Text("$\(String(format: "%.0f", s))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text("Set limit")
                        .font(.caption)
                        .foregroundStyle(.accentColor)
                }
            }
            if lim != nil {
                ProgressView(value: prog)
                    .tint(prog > 1 ? .red : prog > 0.8 ? .orange : .green)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { setBudgetFor = cat.name }
    }

    private func subscriptionRow(_ sub: Subscription) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name).font(.body)
                Text("\(sub.frequency.displayName) · Bills \(sub.billingDay.ordinal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", sub.amount))")
                    .font(.body.monospacedDigit())
                Text(sub.frequency == .annual ? "/yr" : "/mo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions {
            Button(role: .destructive) { store.deleteSubscription(sub) } label: {
                Label("Delete", systemImage: "trash")
            }
            Button { editSubscription = sub } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

extension Int {
    var ordinal: String {
        let suffix: String
        switch self % 100 {
        case 11...13: suffix = "th"
        default:
            switch self % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(self)\(suffix)"
    }
}

extension String: Identifiable {
    public var id: String { self }
}
