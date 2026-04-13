import SwiftUI

// MARK: - ClaudeChatView

/// A reusable chat interface for all Claude accountability conversations.
/// Handles: regular override, blackout emergency, earn task, sick day,
/// always-free requests, and settings change requests.
struct ClaudeChatView: View {
    let mode: ChatMode

    @EnvironmentObject private var manager: BlockingManager
    @AppStorage("claudeAPIKey") private var apiKey = ""

    @State private var messages: [ClaudeService.Message] = []
    @State private var inputText  = ""
    @State private var isLoading  = false
    @State private var errorMsg: String?
    @State private var decision: ClaudeService.OverrideDecision = .pending
    @State private var showAPIKeySheet = false

    private var conversationStarted: Bool { !messages.isEmpty }

    // MARK: - Mode-Specific Text

    private var title: String {
        switch mode {
        case .override:          return "Ask Claude to Override"
        case .blackoutEmergency: return "Emergency Override"
        case .earnTask(let t):   return "Claim: \(t.name)"
        case .sickDay:           return "Sick Day Request"
        case .alwaysFree:        return "Request Always-Free App"
        case .travelSettings:    return "Change Travel Limits"
        case .sickDaySettings:   return "Change Sick Day Limit"
        }
    }

    private var introText: String {
        switch mode {
        case .override:
            return "Your apps are currently blocked. Explain to Claude why you need access — Claude will decide."
        case .blackoutEmergency:
            return "It's blackout hours. Only genuine emergencies (medical, safety, family crisis) will be approved."
        case .earnTask(let t):
            return "Tell Claude what you did to complete \"\(t.name)\". Be specific — vague answers will be denied."
        case .sickDay:
            return "Tell Claude your symptoms. Claude will assess if you're genuinely ill and decide how many hours to grant. You don't choose the duration."
        case .alwaysFree:
            return "Request an app to be permanently on your always-free list. Only essential utilities (Maps, medical apps, etc.) will be approved."
        case .travelSettings:
            return "Explain why your current travel limits need to change. Limits becoming more strict are easier to approve."
        case .sickDaySettings:
            return "Explain why your sick day limit needs to change."
        }
    }

    private var openingMessage: String {
        switch mode {
        case .override:
            return "Hi! I have my apps blocked right now and I'd like to ask you to let me override the block."
        case .blackoutEmergency:
            return "Hi, I need emergency access during blackout hours."
        case .earnTask(let t):
            return "Hi! I've completed the task \"\(t.name)\" and I'd like to claim my \(t.minutesEarned) minutes."
        case .sickDay:
            return "Hi, I'm not feeling well and I'd like to request sick day access to my apps."
        case .alwaysFree:
            return "Hi, I'd like to request that an app be added to my always-free list."
        case .travelSettings:
            return "Hi, I'd like to change my travel access limits."
        case .sickDaySettings:
            return "Hi, I'd like to change my sick day limit."
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat history
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
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.content, anchor: .bottom) }
                        }
                    }
                }

                // Decision banner
                if decision != .pending {
                    decisionBanner
                }

                // Error
                if let err = errorMsg {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Divider()

                // Input bar
                if decision == .pending {
                    inputBar
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button { showAPIKeySheet = true } label: {
                        Image(systemName: "key.fill")
                    }
                }
                if conversationStarted && decision == .pending {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Reset") { reset() }
                    }
                }
            }
            .sheet(isPresented: $showAPIKeySheet) {
                APIKeySheet(apiKey: $apiKey)
            }
        }
    }

    // MARK: - Subviews

    private var introCard: some View {
        VStack(spacing: 12) {
            Image(systemName: modeIcon)
                .font(.system(size: 48))
                .foregroundStyle(modeColor)

            Text(title)
                .font(.title2.bold())

            Text(introText)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.subheadline)

            if apiKey.isEmpty {
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
                        .background(modeColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.adaptiveGray6))
        .padding()
    }

    private var modeIcon: String {
        switch mode {
        case .override:          return "bubble.left.and.bubble.right.fill"
        case .blackoutEmergency: return "exclamationmark.shield.fill"
        case .earnTask:          return "star.circle.fill"
        case .sickDay:           return "cross.case.fill"
        case .alwaysFree:        return "checkmark.seal.fill"
        case .travelSettings, .sickDaySettings: return "gearshape.fill"
        }
    }

    private var modeColor: Color {
        switch mode {
        case .override:          return .blue
        case .blackoutEmergency: return .red
        case .earnTask:          return .orange
        case .sickDay:           return .green
        case .alwaysFree:        return .teal
        case .travelSettings, .sickDaySettings: return .purple
        }
    }

    private var decisionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: isPositiveDecision ? "checkmark.shield.fill" : "xmark.shield.fill")
                .font(.title2)
                .foregroundStyle(isPositiveDecision ? .green : .red)

            VStack(alignment: .leading) {
                Text(decisionTitle)
                    .font(.headline)
                Text(decisionSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isPositiveDecision {
                Button(decisionActionLabel) {
                    handleApproval()
                }
                .buttonStyle(.borderedProminent)
                .tint(modeColor)
            }
        }
        .padding()
        .background(isPositiveDecision ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
    }

    private var isPositiveDecision: Bool {
        switch decision {
        case .approved, .taskApproved, .sickDayApproved, .alwaysFreeApproved, .settingsApproved:
            return true
        default:
            return false
        }
    }

    private var decisionTitle: String {
        switch decision {
        case .approved:                    return "Access Granted"
        case .denied:                      return "Access Denied"
        case .taskApproved:                return "Task Approved!"
        case .taskDenied:                  return "Task Not Approved"
        case .sickDayApproved(let h):      return "Sick Day: \(h) hour(s) granted"
        case .sickDayDenied:               return "Sick Day Denied"
        case .alwaysFreeApproved(let app): return "\(app) Added to Always-Free"
        case .alwaysFreeDenied:            return "App Not Approved"
        case .settingsApproved:            return "Settings Change Approved"
        case .settingsDenied:              return "Settings Change Denied"
        case .pending:                     return ""
        }
    }

    private var decisionSubtitle: String {
        switch decision {
        case .approved:           return "Claude has approved your override."
        case .denied:             return "Claude has denied your request."
        case .taskApproved:       return "Your earned time has been added!"
        case .taskDenied:         return "Your task completion wasn't convincing enough."
        case .sickDayApproved:    return "Blocking is suspended for the granted duration."
        case .sickDayDenied:      return "Claude doesn't think you're sick enough to qualify."
        case .alwaysFreeApproved: return "This app will never be blocked going forward."
        case .alwaysFreeDenied:   return "Only essential utilities can be always-free."
        case .settingsApproved:   return "Your limits have been updated."
        case .settingsDenied:     return "Claude didn't approve the change."
        case .pending:            return ""
        }
    }

    private var decisionActionLabel: String {
        switch mode {
        case .override, .blackoutEmergency: return "Unblock Now"
        case .earnTask:                     return "Start Earned Session"
        case .sickDay:                      return "Activate Sick Day"
        case .alwaysFree:                   return "Saved"
        case .travelSettings, .sickDaySettings: return "Apply"
        }
    }

    private func handleApproval() {
        switch decision {
        case .approved:
            manager.stopBlocking()
        case .taskApproved:
            if case .earnTask(let task) = mode {
                manager.addEarnedMinutes(task.minutesEarned)
                manager.startEarnedSession()
            }
        case .sickDayApproved(let hours):
            manager.activateSickDay(hours: hours)
        case .alwaysFreeApproved(let appName):
            let app = AlwaysFreeApp(name: appName, bundleIdentifier: "")
            manager.alwaysFreeApps.append(app)
        case .settingsApproved(let raw):
            applySettingsChange(raw: raw)
        default:
            break
        }
    }

    private func applySettingsChange(raw: String) {
        switch mode {
        case .travelSettings:
            // Parse "uses=N, hours=H"
            let parts = raw.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            var uses = manager.travelUsesPerMonth
            var hours = manager.travelMaxHoursPerUse
            for part in parts {
                if part.hasPrefix("uses="), let n = Int(part.dropFirst(5)) { uses = n }
                if part.hasPrefix("hours="), let n = Int(part.dropFirst(6)) { hours = n }
            }
            manager.updateTravelSettings(usesPerMonth: uses, maxHoursPerUse: hours)
        case .sickDaySettings:
            // Parse "sickDays=N"
            if let range = raw.range(of: #"sickDays=(\d+)"#, options: .regularExpression) {
                let token = String(raw[range])
                if let n = Int(token.components(separatedBy: "=").last ?? "") {
                    manager.updateSickDaySettings(daysPerMonth: n)
                }
            }
        default:
            break
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Type your message…", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)

            Button { sendMessage() } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading || apiKey.isEmpty)
        }
        .padding()
    }

    // MARK: - Logic

    private func startConversation() {
        messages.append(.init(role: "user", content: openingMessage))
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
                let reply = try await ClaudeService.shared.send(
                    history: messages,
                    apiKey: apiKey,
                    mode: mode
                )
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
                .background(isUser ? Color.blue : Color.adaptiveGray5)
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
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                } header: {
                    Text("Anthropic API Key")
                } footer: {
                    Text("Your key is stored only on this device.")
                }
            }
            .navigationTitle("API Key")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { apiKey = draft; dismiss() }
                        .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { draft = apiKey }
        }
    }
}

// Keep backward-compatible type alias so existing references still compile.
typealias OverrideView = ClaudeChatView

#Preview {
    ClaudeChatView(mode: .override)
        .environmentObject(BlockingManager())
}
