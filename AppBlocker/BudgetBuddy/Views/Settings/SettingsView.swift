import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: BudgetStore
    @AppStorage("budgetClaudeAPIKey")    private var apiKey            = ""
    @AppStorage("lowBalanceThreshold")   private var lowBalanceThreshold = 500.0
    @State private var showAPIKeySheet   = false
    @State private var showLinkBank      = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                // AI
                Section("AI Assistant") {
                    HStack {
                        Text("Anthropic API Key")
                        Spacer()
                        Text(apiKey.isEmpty ? "Not set" : "••••\(apiKey.suffix(4))")
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showAPIKeySheet = true }
                }

                // Bank
                Section("Bank Account") {
                    if store.linkedAccounts.isEmpty {
                        Button("Link Bank Account") { showLinkBank = true }
                    } else {
                        ForEach(store.linkedAccounts) { account in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(account.institutionName).font(.body)
                                    Text(account.accountName).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Sync") { syncAccount(account) }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                            }
                        }
                        .onDelete { indices in
                            indices.forEach { store.removeLinkedAccount(store.linkedAccounts[$0]) }
                        }
                        Button("Link Another Account") { showLinkBank = true }
                    }
                }

                // Alerts
                Section("Alerts") {
                    HStack {
                        Text("Low balance alert")
                        Spacer()
                        TextField("500", value: $lowBalanceThreshold, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                // iCloud
                Section("Sync") {
                    HStack {
                        Label("iCloud Sync", systemImage: "icloud")
                        Spacer()
                        Text(FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil ? "On" : "Off")
                            .foregroundStyle(FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil ? .green : .secondary)
                    }
                    Text("Sign into iCloud on all devices to sync data automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Danger zone
                Section {
                    Button("Delete All Data", role: .destructive) { showDeleteConfirm = true }
                } header: {
                    Text("Danger Zone")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAPIKeySheet) { APIKeySheet(apiKey: $apiKey) }
            .sheet(isPresented: $showLinkBank)    { LinkBankView() }
            .confirmationDialog("Delete all data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Everything", role: .destructive) { deleteAll() }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    private func syncAccount(_ account: LinkedAccount) {
        Task {
            do {
                let balance = try await PlaidService.shared.fetchBalance(itemID: account.itemID, serverURL: account.serverURL)
                var updated = account
                updated.currentBalance = balance.balance
                updated.lastSynced     = Date()
                store.updateLinkedAccount(updated)

                let plaidTxns = try await PlaidService.shared.fetchTransactions(
                    itemID: account.itemID, since: account.lastSynced, serverURL: account.serverURL)
                let txns = await PlaidService.shared.toTransactions(plaidTxns)
                store.addAll(txns)
                store.checkLowBalanceAlert(threshold: lowBalanceThreshold)
                store.syncBankAssetsFromLinkedAccounts()
            } catch {
                // Silently ignore sync errors in Settings — user will see stale lastSynced date
            }
        }
    }

    private func deleteAll() {
        store.transactions            = []
        store.budgetLimits            = []
        store.investmentAccounts      = []
        store.investmentContributions = []
        store.cashBudgets             = []
        store.subscriptions           = []
        store.linkedAccounts          = []
        store.assets                  = []
        store.liabilities             = []
        store.netWorthHistory         = []
        store.loadAll()  // re-seed categories
    }
}
