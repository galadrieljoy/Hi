import SwiftUI

#if os(iOS)
import FamilyControls
#endif

// MARK: - Cross-Platform Colors

extension Color {
    static var adaptiveGray5: Color {
        #if os(iOS)
        Color(UIColor.systemGray5)
        #else
        Color(NSColor.quinaryLabel)
        #endif
    }
    static var adaptiveGray6: Color {
        #if os(iOS)
        Color(UIColor.systemGray6)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }
}

// MARK: - Tab Definition

enum Tab: String, CaseIterable {
    case home, schedule, earn, override, settings

    var label: String {
        switch self {
        case .home:     return "Home"
        case .schedule: return "Schedule"
        case .earn:     return "Earn Time"
        case .override: return "Ask Claude"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home:     return "shield.fill"
        case .schedule: return "clock.fill"
        case .earn:     return "star.circle.fill"
        case .override: return "bubble.left.and.bubble.right.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var manager: BlockingManager
    @State private var activeTab: Tab = .home

    #if os(iOS)
    @State private var showPicker = false
    @State private var showAlwaysFreePicker = false
    #endif

    #if os(macOS)
    @State private var showMacAppPicker = false
    @State private var showAlwaysFreeSheet = false
    #endif

    var body: some View {
        Group {
            if !manager.isAuthorized {
                authorizationView
            } else {
                #if os(iOS)
                iOSTabView
                    .familyActivityPicker(isPresented: $showPicker, selection: $manager.selection)
                #elseif os(macOS)
                macOSSplitView
                #endif
            }
        }
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

    // MARK: - iOS Tab Layout

    #if os(iOS)
    private var iOSTabView: some View {
        TabView(selection: $activeTab) {
            homeTab
                .tabItem { Label(Tab.home.label,     systemImage: Tab.home.icon) }
                .tag(Tab.home)
            ScheduleView()
                .tabItem { Label(Tab.schedule.label, systemImage: Tab.schedule.icon) }
                .tag(Tab.schedule)
            EarnView()
                .tabItem { Label(Tab.earn.label,     systemImage: Tab.earn.icon) }
                .tag(Tab.earn)
            ClaudeChatView(mode: manager.isInBlackout ? .blackoutEmergency : .override)
                .tabItem { Label(Tab.override.label, systemImage: Tab.override.icon) }
                .tag(Tab.override)
            settingsTab
                .tabItem { Label(Tab.settings.label, systemImage: Tab.settings.icon) }
                .tag(Tab.settings)
        }
    }
    #endif

    // MARK: - macOS Split Layout

    #if os(macOS)
    private var macOSSplitView: some View {
        NavigationSplitView {
            List(Tab.allCases, id: \.self, selection: $activeTab) { tab in
                Label(tab.label, systemImage: tab.icon)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 200)
            .navigationTitle("App Blocker")
        } detail: {
            switch activeTab {
            case .home:     homeTab
            case .schedule: ScheduleView()
            case .earn:     EarnView()
            case .override: ClaudeChatView(mode: manager.isInBlackout ? .blackoutEmergency : .override)
            case .settings: settingsTab
            }
        }
    }
    #endif

    // MARK: - Home Tab

    private var homeTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusCard
                    appSelectionCard
                    if manager.isInBlackout {
                        blackoutBanner
                    }
                    if manager.travelSessionActive || manager.sickDaySessionActive {
                        specialSessionCard
                    }
                    travelSickDayRow
                    claudeLockToggle
                    blockButton
                }
                .padding()
            }
            .navigationTitle("App Blocker")
        }
    }

    private var statusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(manager.isBlocking ? "Blocking Active" : "Not Blocking")
                    .font(.headline)
                if manager.isInBlackout {
                    Label("Blackout hours active", systemImage: "moon.fill")
                        .font(.subheadline)
                        .foregroundStyle(.indigo)
                } else if manager.isBlocking && manager.claudeOverrideRequired {
                    Label("Claude override required to unlock", systemImage: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else {
                    Text(manager.isBlocking
                         ? "\(manager.selectedAppCount) app(s) blocked"
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
                .fill(manager.isBlocking ? Color.red.opacity(0.1) : Color.adaptiveGray6)
        )
    }

    private var appSelectionCard: some View {
        #if os(iOS)
        Button { showPicker = true } label: { appSelectionLabel }
            .disabled(manager.isBlocking)
        #elseif os(macOS)
        Button {
            showMacAppPicker = true
        } label: {
            appSelectionLabel
        }
        .disabled(manager.isBlocking)
        .sheet(isPresented: $showMacAppPicker) {
            MacAppSelectionView()
                .environmentObject(manager)
        }
        #endif
    }

    private var appSelectionLabel: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Select Apps to Block")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(manager.selectedAppCount == 0
                     ? "No apps selected"
                     : "\(manager.selectedAppCount) app(s) selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.adaptiveGray6))
    }

    private var blackoutBanner: some View {
        HStack {
            Image(systemName: "moon.fill")
                .foregroundStyle(.indigo)
            VStack(alignment: .leading, spacing: 2) {
                Text("Blackout Hours Active")
                    .font(.subheadline.bold())
                Text("Only always-free apps are accessible. Earning is paused.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.indigo.opacity(0.12)))
    }

    private var specialSessionCard: some View {
        HStack {
            Image(systemName: manager.travelSessionActive ? "airplane" : "cross.case.fill")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(manager.travelSessionActive ? "Travel Mode Active" : "Sick Day Active")
                    .font(.subheadline.bold())
                if let endsAt = manager.travelSessionActive ? manager.travelSessionEndsAt : manager.sickDaySessionEndsAt {
                    Text("Access until \(endsAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.green.opacity(0.12)))
    }

    private var travelSickDayRow: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: TravelAccessView().environmentObject(manager)) {
                VStack(spacing: 6) {
                    Image(systemName: "airplane")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("Travel")
                        .font(.caption.bold())
                    Text("\(manager.travelUsesRemaining) left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.adaptiveGray6))
            }
            .buttonStyle(.plain)

            NavigationLink(destination: ClaudeChatView(mode: .sickDay).environmentObject(manager)) {
                VStack(spacing: 6) {
                    Image(systemName: "cross.case.fill")
                        .font(.title2)
                        .foregroundStyle(manager.sickDaysRemaining > 0 ? .green : .gray)
                    Text("Sick Day")
                        .font(.caption.bold())
                    Text("\(manager.sickDaysRemaining) left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.adaptiveGray6))
            }
            .buttonStyle(.plain)
            .disabled(manager.sickDaysRemaining == 0)
        }
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
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.adaptiveGray6))
    }

    private var blockButton: some View {
        Group {
            if manager.isBlocking && manager.claudeOverrideRequired && !manager.hasActiveSpecialSession {
                Button { activeTab = .override } label: {
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
                .disabled(manager.selectedAppCount == 0 && !manager.isBlocking)
            }
        }
    }

    // MARK: - Settings Tab

    private var settingsTab: some View {
        NavigationStack {
            List {
                Section("Limits (Claude-gated)") {
                    NavigationLink("Travel Access Settings") {
                        TravelSettingsView().environmentObject(manager)
                    }
                    NavigationLink("Sick Day Settings") {
                        SickDaySettingsView().environmentObject(manager)
                    }
                }

                Section("Always-Free Apps") {
                    ForEach(manager.alwaysFreeApps) { app in
                        Label(app.name, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    NavigationLink("Request Always-Free App") {
                        ClaudeChatView(mode: .alwaysFree).environmentObject(manager)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "2.0.0")
                    LabeledContent("Framework") {
                        #if os(iOS)
                        Text("Screen Time API")
                        #else
                        Text("NSWorkspace")
                        #endif
                    }
                }

                Section {
                    Button(role: .destructive) {
                        manager.stopBlocking()
                    } label: {
                        Label("Clear All Restrictions", systemImage: "trash")
                    }
                    .disabled(manager.claudeOverrideRequired && manager.isBlocking && !manager.hasActiveSpecialSession)
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

// MARK: - Travel Access View

struct TravelAccessView: View {
    @EnvironmentObject private var manager: BlockingManager
    @State private var selectedHours: Int = 4

    var body: some View {
        Form {
            Section("Remaining Uses") {
                LabeledContent("Uses this month", value: "\(manager.travelUsesUsedThisMonth) / \(manager.travelUsesPerMonth)")
                LabeledContent("Max hours per use", value: "\(manager.travelMaxHoursPerUse) hrs")
            }

            if manager.travelSessionActive, let endsAt = manager.travelSessionEndsAt {
                Section("Active Session") {
                    Label("Access until \(endsAt.formatted(date: .omitted, time: .shortened))",
                          systemImage: "airplane.circle.fill")
                        .foregroundStyle(.green)
                    Text("Cannot be extended.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if manager.travelUsesRemaining > 0 {
                Section("Activate Travel Access") {
                    Stepper("Hours: \(selectedHours)", value: $selectedHours,
                            in: 1...manager.travelMaxHoursPerUse)
                    Button("Activate for \(selectedHours) hour(s)") {
                        manager.activateTravelAccess(hours: selectedHours)
                    }
                    .buttonStyle(.borderedProminent)
                }
                Section {
                    Text("Once activated, hours cannot be added. Uses reset monthly.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    Label("No travel uses remaining this month.", systemImage: "xmark.circle")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Travel Access")
    }
}

// MARK: - Travel Settings View (Claude-gated)

struct TravelSettingsView: View {
    @EnvironmentObject private var manager: BlockingManager

    private var currentSettingsDescription: String {
        "\(manager.travelUsesPerMonth) uses/month, max \(manager.travelMaxHoursPerUse) hrs each"
    }

    var body: some View {
        ClaudeChatView(
            mode: .travelSettings(current: currentSettingsDescription)
        )
        .environmentObject(manager)
        .navigationTitle("Change Travel Limits")
    }
}

// MARK: - Sick Day Settings View (Claude-gated)

struct SickDaySettingsView: View {
    @EnvironmentObject private var manager: BlockingManager

    private var currentDescription: String {
        "\(manager.sickDaysPerMonth) sick days/month"
    }

    var body: some View {
        ClaudeChatView(
            mode: .sickDaySettings(current: currentDescription)
        )
        .environmentObject(manager)
        .navigationTitle("Change Sick Day Limit")
    }
}

#Preview {
    ContentView()
        .environmentObject(BlockingManager())
}
