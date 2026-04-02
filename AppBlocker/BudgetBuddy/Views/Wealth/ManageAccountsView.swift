import SwiftUI

struct ManageAccountsView: View {
    @EnvironmentObject var store: BudgetStore
    @State private var showAdd    = false
    @State private var editTarget: InvestmentAccount?

    var body: some View {
        List {
            ForEach(store.investmentAccounts) { account in
                HStack {
                    Circle()
                        .fill(Color(hex: account.colorHex).opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(Text(account.accountType.rawValue.prefix(3)).font(.caption2.bold()).foregroundStyle(Color(hex: account.colorHex)))
                    VStack(alignment: .leading) {
                        Text(account.name)
                        Text(account.accountType.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("$\(String(format: "%.0f", account.monthlyGoal))/mo").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                .swipeActions {
                    Button(role: .destructive) { store.deleteAccount(account) } label: { Label("Delete", systemImage: "trash") }
                    Button { editTarget = account } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                }
            }
            Button { showAdd = true } label: { Label("Add Account", systemImage: "plus") }
        }
        .navigationTitle("Accounts")
        .sheet(isPresented: $showAdd) { AddAccountView() }
        .sheet(item: $editTarget) { AddAccountView(existing: $0) }
    }
}
