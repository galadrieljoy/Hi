import SwiftUI
import FamilyControls

struct ContentView: View {
    @EnvironmentObject private var manager: BlockingManager
    @State private var showPicker  = false
    @State private var activeTab: Tab = .home

    enum Tab { case home, schedule, override, settings }

    var body: some View {
        Group {
            if !manager.isAuthorized {
                authorizationView
            } else {
                TabView(selection: $activeTab) {
                    homeTab
                        .tabItem { Label("Home",     systemImage: "shield.fill") }
                        .tag(Tab.home)

                    ScheduleView()
                        .tabItem { Label("Schedule", systemImage: "clock.fill") }
                        .tag(Tab.schedule)

                    OverrideView()
                        .tabItem { Label("Ask Claude", systemImage: "bubble.left.and.bubble.right.fill") }
                        .tag(Tab.override)

                    settingsTab
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                        .tag(Tab.settings)
                }
                // Badge the Override tab when blocking is active & Claude lock is on
                .onChange(of: manager.isBlocking) { _, _ in }
            }
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $manager.selection)
        .alert("Authorization Error",
               isPresented: .constant(manager.authorizationError != nil),
               actions: { Button("OK") { manager.authorizationError = nil } },
               message: { Text(manager.authorizationError ?? "") })
    }

    // MARK: - Authorization Screen

    private var authorizationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("App Blocker")
                .font(.largeTitle.bold())

            Text("App Blocker needs Screen Time permission to block apps on your device.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button {
                Task { await manager.requestAuthorization() }
            } label: {
                Label("Allow Screen Time Access", systemImage: "checkmark.shield")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        NavigationStack {
            VStack(spacing: 20) {
                statusCard
                appSelectionCard
                claudeLockToggle
                blockButton
                Spacer()
            }
            .padding()
            .navigationTitle("App Blocker")
        }
    }

    private var statusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(manager.isBlocking ? "Blocking Active" : "Not Blocking")
                    .font(.headline)
                if manager.isBlocking && manager.claudeOverrideRequired {
                    Label("Claude override required to unlock", systemImage: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else {
                    Text(manager.isBlocking
                         ? "\(manager.selection.applicationTokens.count) app(s) blocked"
                         : "Tap below to start blocking")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: manager.isBlocking ? "shield.fill" : "shield.slash")
                .font(.title)
                .foregroundStyle(manager.isBlocking ? .red : .gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(manager.isBlocking ? Color.red.opacity(0.1) : Color(.systemGray6))
        )
    }

    private var appSelectionCard: some View {
        Button { showPicker = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Apps to Block")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(manager.selection.applicationTokens.isEmpty
                         ? "No apps selected"
                         : "\(manager.selection.applicationTokens.count) app(s) selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
        .disabled(manager.isBlocking)
    }

    private var claudeLockToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Label("Require Claude to unlock", systemImage: "brain")
                    .font(.subheadline.bold())
                Text("You must convince Claude to remove the block")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $manager.claudeOverrideRequired)
                .labelsHidden()
                .disabled(manager.isBlocking)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    private var blockButton: some View {
        Group {
            if manager.isBlocking && manager.claudeOverrideRequired {
                // Locked — point user to the Override tab
                Button {
                    activeTab = .override
                } label: {
                    Label("Talk to Claude to Unlock", systemImage: "bubble.left.and.bubble.right.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                Button {
                    if manager.isBlocking {
                        manager.stopBlocking()
                    } else {
                        manager.startBlocking(requireClaudeOverride: manager.claudeOverrideRequired)
                    }
                } label: {
                    Label(manager.isBlocking ? "Stop Blocking" : "Start Blocking",
                          systemImage: manager.isBlocking ? "xmark.shield" : "checkmark.shield")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(manager.isBlocking ? Color.red : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(manager.selection.applicationTokens.isEmpty && !manager.isBlocking)
            }
        }
    }

    // MARK: - Settings Tab

    private var settingsTab: some View {
        NavigationStack {
            List {
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Framework", value: "Screen Time API")
                }
                Section {
                    Button(role: .destructive) {
                        manager.stopBlocking()
                    } label: {
                        Label("Clear All Restrictions", systemImage: "trash")
                    }
                    .disabled(manager.claudeOverrideRequired && manager.isBlocking)
                } footer: {
                    if manager.claudeOverrideRequired && manager.isBlocking {
                        Text("Claude override is active. Use the Ask Claude tab to unlock.")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BlockingManager())
}
