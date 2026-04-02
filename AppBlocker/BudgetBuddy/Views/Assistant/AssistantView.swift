import SwiftUI

struct AssistantView: View {
    @EnvironmentObject var store: BudgetStore
    @AppStorage("budgetClaudeAPIKey") private var apiKey = ""

    @State private var messages:         [BudgetClaudeService.Message] = []
    @State private var input             = ""
    @State private var isLoading         = false
    @State private var showAPIKeySheet   = false
    @State private var pendingProposals: [ProposedTransaction]?
    @State private var errorMsg: String?

    private var month: Int { Calendar.current.component(.month, from: Date()) }
    private var year:  Int { Calendar.current.component(.year,  from: Date()) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat history
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if messages.isEmpty {
                                emptyState
                            }
                            ForEach(Array(messages.enumerated()), id: \.offset) { i, msg in
                                ChatBubble(role: msg.role, text: msg.content)
                                    .id(i)
                            }
                            if isLoading {
                                HStack {
                                    ProgressView().padding(12)
                                    Spacer()
                                }
                            }
                            if let err = errorMsg {
                                Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { newCount in
                        withAnimation { proxy.scrollTo(newCount - 1) }
                    }
                }

                // Proposed transaction confirmation card
                if let proposals = pendingProposals {
                    ProposedTransactionCard(
                        proposals: proposals,
                        onConfirm: { confirmProposals(proposals) },
                        onDiscard: { pendingProposals = nil }
                    )
                    .padding(.bottom, 8)
                }

                Divider()

                // Input bar
                HStack(spacing: 8) {
                    TextField("Ask anything or describe your spending…", text: $input, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button {
                        send()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(input.isEmpty || isLoading ? Color.secondary : Color.accentColor)
                    }
                    .disabled(input.isEmpty || isLoading)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Assistant")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAPIKeySheet = true } label: {
                        Image(systemName: "key.fill")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    if !messages.isEmpty {
                        Button("Clear") {
                            messages        = []
                            pendingProposals = nil
                            errorMsg        = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showAPIKeySheet) {
                APIKeySheet(apiKey: $apiKey)
            }
        }
    }

    // MARK: - Send

    private func send() {
        guard !input.isEmpty else { return }
        errorMsg = nil
        let userMsg = BudgetClaudeService.Message(role: "user", content: input)
        messages.append(userMsg)
        input     = ""
        isLoading = true

        Task {
            do {
                let reply = try await BudgetClaudeService.shared.send(
                    history:        messages,
                    apiKey:         apiKey,
                    tripContext:    buildTripContext(),
                    spendingContext: store.summaryText(month: month, year: year)
                )
                messages.append(BudgetClaudeService.Message(role: "assistant", content: reply.visibleText))
                pendingProposals = reply.proposedTransactions
            } catch {
                errorMsg = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Confirm proposals

    private func confirmProposals(_ proposals: [ProposedTransaction]) {
        for p in proposals {
            store.add(Transaction(
                date:          p.date,
                amount:        p.amount,
                type:          .expense,
                categoryName:  p.category,
                title:         p.title,
                paymentMethod: p.paymentMethod
            ))
        }
        pendingProposals = nil

        let confirmed = BudgetClaudeService.Message(
            role: "user",
            content: "✓ Added \(proposals.count) transaction\(proposals.count == 1 ? "" : "s")."
        )
        messages.append(confirmed)
    }

    // MARK: - Trip context builder

    private func buildTripContext() -> BudgetClaudeService.TripContext? {
        guard let trip = store.activeCashBudget() else { return nil }
        let week  = BudgetStore.weekNumber(for: Date(), startDate: trip.startDate)
        let spent = store.cashSpentThisWeek(of: trip)
        let f     = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return BudgetClaudeService.TripContext(
            tripName:          trip.tripName,
            weeklyLimit:       trip.weeklyLimit,
            currentWeek:       week,
            cashSpentThisWeek: spent,
            todayDateString:   f.string(from: Date())
        )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Ask about your spending, get budget advice, or describe cash purchases to log them automatically.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
