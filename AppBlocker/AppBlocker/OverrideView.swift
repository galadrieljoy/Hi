import SwiftUI

/// Chat screen where the user talks to Claude to request an early override.
struct OverrideView: View {
    @EnvironmentObject private var manager: BlockingManager
    @AppStorage("claudeAPIKey") private var apiKey = ""

    @State private var messages: [ClaudeService.Message] = []
    @State private var inputText  = ""
    @State private var isLoading  = false
    @State private var errorMsg: String?
    @State private var decision: ClaudeService.OverrideDecision = .pending
    @State private var showAPIKeySheet = false

    private var conversationStarted: Bool { !messages.isEmpty }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Chat history ──
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if !conversationStarted {
                                introCard
                            }
                            ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                                ChatBubble(role: msg.role, text: msg.content)
                                    .id(msg.content)
                            }
                            if isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Claude is thinking…")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.content, anchor: .bottom) }
                        }
                    }
                }

                // ── Decision banner ──
                if decision != .pending {
                    decisionBanner
                }

                // ── Error ──
                if let err = errorMsg {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Divider()

                // ── Input bar ──
                if decision == .pending {
                    inputBar
                }
            }
            .navigationTitle("Ask Claude to Override")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAPIKeySheet = true } label: {
                        Image(systemName: "key.fill")
                    }
                }
                if conversationStarted && decision == .pending {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Reset") { reset() }
                    }
                }
            }
            .sheet(isPresented: $showAPIKeySheet) {
                APIKeySheet(apiKey: $apiKey)
            }
            .onAppear {
                if !manager.isBlocking {
                    // Nothing to override
                }
            }
        }
    }

    // MARK: - Subviews

    private var introCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Override Protection")
                .font(.title2.bold())

            Text("Your apps are currently blocked. To unlock them early, explain to Claude why you need access. Claude will decide whether to approve your request.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.subheadline)

            if !manager.isBlocking {
                Label("No active block to override", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
                    .font(.subheadline)
            } else if apiKey.isEmpty {
                Button { showAPIKeySheet = true } label: {
                    Label("Add Claude API Key to start", systemImage: "key")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                Button { startConversation() } label: {
                    Label("Start Conversation", systemImage: "message")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding()
    }

    private var decisionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: decision == .approved ? "checkmark.shield.fill" : "xmark.shield.fill")
                .font(.title2)
            VStack(alignment: .leading) {
                Text(decision == .approved ? "Access Granted" : "Access Denied")
                    .font(.headline)
                Text(decision == .approved
                     ? "Claude has approved your override."
                     : "Claude has denied your request.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if decision == .approved {
                Button("Unblock Now") {
                    manager.stopBlocking()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
        .background(decision == .approved ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Type your message…", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading || apiKey.isEmpty)
        }
        .padding()
    }

    // MARK: - Logic

    private func startConversation() {
        let opening = "Hi! I have my apps blocked right now. I'd like to ask you to let me override the block."
        messages.append(.init(role: "user", content: opening))
        fetchReply()
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        messages.append(.init(role: "user", content: text))
        fetchReply()
    }

    private func fetchReply() {
        isLoading = true
        errorMsg  = nil
        Task {
            do {
                let reply = try await ClaudeService.shared.send(history: messages, apiKey: apiKey)
                messages.append(.init(role: "assistant", content: reply.text))
                decision = reply.decision
            } catch {
                errorMsg = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func reset() {
        messages  = []
        decision  = .pending
        errorMsg  = nil
        inputText = ""
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let role: String
    let text: String

    private var isUser: Bool { role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            Text(text)
                .padding(12)
                .background(isUser ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if !isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
    }
}

// MARK: - API Key Sheet

struct APIKeySheet: View {
    @Binding var apiKey: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-…", text: $draft)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Anthropic API Key")
                } footer: {
                    Text("Your key is stored only on this device. Get one at console.anthropic.com")
                }
            }
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        apiKey = draft
                        dismiss()
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { draft = apiKey }
        }
    }
}

#Preview {
    OverrideView()
        .environmentObject(BlockingManager())
}
