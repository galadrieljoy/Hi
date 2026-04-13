import SwiftUI

#if os(iOS)
import FamilyControls
#endif

@main
struct AppBlockerApp: App {
    @StateObject private var blockingManager = BlockingManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(blockingManager)
                .task {
                    await blockingManager.requestAuthorization()
                }
        }

        #if os(macOS)
        Settings {
            MacSettingsView()
                .environmentObject(blockingManager)
        }
        #endif
    }
}

#if os(macOS)
/// Minimal macOS Settings window (Cmd-,) for API key and preferences.
struct MacSettingsView: View {
    @EnvironmentObject private var manager: BlockingManager
    @AppStorage("claudeAPIKey") private var apiKey = ""

    var body: some View {
        Form {
            Section("Claude API Key") {
                SecureField("sk-ant-…", text: $apiKey)
                    .autocorrectionDisabled()
                Text("Your key is stored only on this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("About") {
                LabeledContent("Version", value: "2.0.0")
                LabeledContent("Framework", value: "NSWorkspace (macOS)")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .padding()
        .navigationTitle("Settings")
    }
}
#endif
