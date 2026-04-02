import SwiftUI

struct InvestmentsView: View {
    @EnvironmentObject var store: BudgetStore
    @State private var showAddAccount      = false
    @State private var showAddContribution = false
    @State private var selectedAccount: InvestmentAccount?

    private var month: Int { Calendar.current.component(.month, from: Date()) }
    private var year:  Int { Calendar.current.component(.year,  from: Date()) }

    private var totalGoal:        Double { store.investmentAccounts.reduce(0) { $0 + $1.monthlyGoal } }
    private var totalContributed: Double { store.investmentAccounts.reduce(0) { $0 + store.contributed(to: $1.id, month: month, year: year) } }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Monthly summary card
                VStack(spacing: 6) {
                    Text("Invested This Month").font(.caption).foregroundStyle(.secondary)
                    Text("$\(String(format: "%.2f", totalContributed)) / $\(String(format: "%.2f", totalGoal))")
                        .font(.title2.bold().monospacedDigit())
                    if totalGoal > 0 {
                        ProgressView(value: min(totalContributed / totalGoal, 1.0))
                            .tint(totalContributed >= totalGoal ? .green : .accentColor)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                .padding(.horizontal)

                // Account rows
                VStack(spacing: 0) {
                    ForEach(store.investmentAccounts) { account in
                        NavigationLink(destination: ContributionHistoryView(account: account)) {
                            InvestmentAccountRow(account: account)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button { selectedAccount = account; showAddContribution = true } label: {
                                Label("Contribute", systemImage: "plus.circle")
                            }.tint(.green)
                            Button { store.deleteAccount(account) } label: {
                                Label("Delete", systemImage: "trash")
                            }.tint(.red)
                        }
                        Divider().padding(.leading, 64)
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                .padding(.horizontal)

                if store.investmentAccounts.isEmpty {
                    Text("Add investment accounts to track your contributions.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showAddAccount = true } label: { Label("Add Account", systemImage: "plus.circle") }
                    Button { showAddContribution = true } label: { Label("Log Contribution", systemImage: "dollarsign.circle") }
                } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddAccount) { AddAccountView() }
        .sheet(isPresented: $showAddContribution) {
            AddContributionView(preselectedAccount: selectedAccount)
                .onDisappear { selectedAccount = nil }
        }
    }
}
