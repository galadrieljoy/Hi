import SwiftUI

/// Guides the user through connecting a bank account via the companion Plaid backend.
/// Full Plaid Link SDK (LinkKit) integration requires the SPM package to be added in Xcode.
/// This view handles the server URL entry and token exchange flow.
struct LinkBankView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    @State private var serverURL  = ""
    @State private var linkToken  = ""
    @State private var isLoading  = false
    @State private var errorMsg: String?
    @State private var phase      = Phase.serverEntry

    enum Phase { case serverEntry, linkReady, success }

    var body: some View {
        NavigationStack {
            Form {
                switch phase {
                case .serverEntry:
                    serverEntrySection

                case .linkReady:
                    Section("Ready to Connect") {
                        Text("A Plaid Link token has been created. Tap below to open the bank authentication flow.")
                            .font(.callout)
                        Button("Open Bank Login") {
                            // In production, present PLKPlaidLink here using the linkToken.
                            // For now, simulate a successful connection with a test item_id.
                            simulateConnection()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }

                case .success:
                    Section {
                        Label("Bank account linked!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Your transactions will sync automatically.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                if let err = errorMsg {
                    Section {
                        Text(err).foregroundStyle(.red).font(.callout)
                    }
                }
            }
            .navigationTitle("Link Bank Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(phase == .success ? "Done" : "Cancel") { dismiss() }
                }
            }
            .disabled(isLoading)
            .overlay { if isLoading { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(.ultraThinMaterial) } }
        }
    }

    private var serverEntrySection: some View {
        Group {
            Section("Plaid Backend URL") {
                TextField("http://localhost:3000", text: $serverURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            Section {
                Button("Create Link Token") {
                    createLinkToken()
                }
                .disabled(serverURL.isEmpty)
            } footer: {
                Text("Run the companion backend server (backend/server.js) and enter its URL here.")
            }
        }
    }

    private func createLinkToken() {
        isLoading = true
        errorMsg  = nil
        Task {
            do {
                let token = try await PlaidService.shared.createLinkToken(serverURL: serverURL)
                linkToken = token
                phase     = .linkReady
            } catch {
                errorMsg  = error.localizedDescription
            }
            isLoading = false
        }
    }

    /// Simulates completing the Plaid Link flow.
    /// In production, replace with actual PLKPlaidLink public_token exchange.
    private func simulateConnection() {
        isLoading = true
        Task {
            do {
                // Exchange a real public_token here when using PLKPlaidLink:
                // let itemID = try await PlaidService.shared.exchangePublicToken(publicToken, serverURL: serverURL)
                let itemID   = "sandbox-item-\(UUID().uuidString.prefix(8))"
                let balance  = try await PlaidService.shared.fetchBalance(itemID: itemID, serverURL: serverURL)
                let account  = LinkedAccount(itemID: itemID, institutionName: balance.institution_name,
                                              accountName: balance.account_name, currentBalance: balance.balance,
                                              serverURL: serverURL)
                store.addLinkedAccount(account)
                phase = .success
            } catch {
                errorMsg = error.localizedDescription
            }
            isLoading = false
        }
    }
}
