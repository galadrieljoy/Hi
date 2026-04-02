import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var store: BudgetStore
    @State private var showAdd     = false
    @State private var editTarget: Transaction?
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear  = Calendar.current.component(.year,  from: Date())
    @State private var filterMethod: PaymentMethod? = nil

    private var filtered: [Transaction] {
        store.transactions.filter {
            Calendar.current.component(.month, from: $0.date) == selectedMonth &&
            Calendar.current.component(.year,  from: $0.date) == selectedYear &&
            (filterMethod == nil || $0.paymentMethod == filterMethod)
        }
        .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthPicker
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                filterBar
                    .padding(.horizontal)
                    .padding(.bottom, 4)

                List {
                    ForEach(filtered) { txn in
                        TransactionRow(transaction: txn)
                            .contentShape(Rectangle())
                            .onTapGesture { editTarget = txn }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { store.delete(txn) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddTransactionView()
            }
            .sheet(item: $editTarget) { txn in
                AddTransactionView(existing: txn)
            }
        }
    }

    private var monthPicker: some View {
        HStack {
            Button {
                if selectedMonth == 1 { selectedMonth = 12; selectedYear -= 1 }
                else { selectedMonth -= 1 }
            } label: { Image(systemName: "chevron.left") }

            Spacer()
            Text(monthYearLabel)
                .font(.headline)
            Spacer()

            Button {
                if selectedMonth == 12 { selectedMonth = 1; selectedYear += 1 }
                else { selectedMonth += 1 }
            } label: { Image(systemName: "chevron.right") }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            filterChip(label: "All",  active: filterMethod == nil)  { filterMethod = nil }
            filterChip(label: "Card", active: filterMethod == .card) { filterMethod = .card }
            filterChip(label: "Cash", active: filterMethod == .cash) { filterMethod = .cash }
            Spacer()
            Text("\(filtered.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func filterChip(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(active ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(active ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var monthYearLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        var comps = DateComponents(); comps.month = selectedMonth; comps.year = selectedYear
        return f.string(from: Calendar.current.date(from: comps) ?? Date())
    }
}
