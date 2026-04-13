#if os(iOS)
import SwiftUI
import FamilyControls
import ManagedSettings

/// Wraps Apple's `FamilyActivityPicker` in a full navigable screen.
struct AppSelectionView: View {
    @EnvironmentObject private var manager: BlockingManager
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { showPicker = true } label: {
                        Label("Choose Apps & Categories", systemImage: "apps.iphone")
                    }
                } footer: {
                    Text("Apps and categories selected here will be blocked when you turn on blocking.")
                }

                if !manager.selection.applicationTokens.isEmpty {
                    Section("Selected Apps (\(manager.selection.applicationTokens.count))") {
                        ForEach(Array(manager.selection.applicationTokens), id: \.self) { _ in
                            Label("App", systemImage: "app.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                if !manager.selection.categoryTokens.isEmpty {
                    Section("Selected Categories (\(manager.selection.categoryTokens.count))") {
                        ForEach(Array(manager.selection.categoryTokens), id: \.self) { _ in
                            Label("Category", systemImage: "folder.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }

                if !manager.selection.applicationTokens.isEmpty || !manager.selection.categoryTokens.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            manager.selection = FamilyActivitySelection()
                            if manager.isBlocking { manager.stopBlocking() }
                        } label: {
                            Label("Clear Selection", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("App Selection")
            .familyActivityPicker(isPresented: $showPicker, selection: $manager.selection)
        }
    }
}

#Preview {
    AppSelectionView()
        .environmentObject(BlockingManager())
}
#endif

// MARK: - macOS App Picker

#if os(macOS)
import SwiftUI
import AppKit

struct InstalledApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let path: String
}

/// macOS sheet for selecting which apps to block.
struct MacAppSelectionView: View {
    @EnvironmentObject private var manager: BlockingManager
    @Environment(\.dismiss) private var dismiss

    @State private var installedApps: [InstalledApp] = []
    @State private var searchText = ""
    @State private var isLoading = true

    private var filtered: [InstalledApp] {
        if searchText.isEmpty { return installedApps }
        return installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading apps…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filtered) { app in
                        HStack {
                            let isBlocked = manager.blockedBundleIDs.contains(app.bundleIdentifier)
                            Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                                .resizable()
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name).font(.body)
                                Text(app.bundleIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isBlocked {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if manager.blockedBundleIDs.contains(app.bundleIdentifier) {
                                manager.blockedBundleIDs.remove(app.bundleIdentifier)
                            } else {
                                manager.blockedBundleIDs.insert(app.bundleIdentifier)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search apps")
                }
            }
            .navigationTitle("Select Apps to Block")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .automatic) {
                    Text("\(manager.blockedBundleIDs.count) selected")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 500)
        .task { await loadApps() }
    }

    private func loadApps() async {
        let dirs = ["/Applications", "/System/Applications",
                    "\(NSHomeDirectory())/Applications"]
        var apps: [InstalledApp] = []
        let fm = FileManager.default

        for dir in dirs {
            guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for item in contents where item.hasSuffix(".app") {
                let path = "\(dir)/\(item)"
                guard let bundle = Bundle(path: path),
                      let bundleID = bundle.bundleIdentifier else { continue }
                let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                        ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                        ?? item.replacingOccurrences(of: ".app", with: "")
                apps.append(InstalledApp(name: name, bundleIdentifier: bundleID, path: path))
            }
        }

        let sorted = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        await MainActor.run {
            installedApps = sorted
            isLoading = false
        }
    }
}
#endif
