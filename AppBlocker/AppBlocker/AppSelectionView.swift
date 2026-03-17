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
                    Text("Apps and categories you select here will be blocked when you turn on blocking.")
                }

                if !manager.selection.applicationTokens.isEmpty {
                    Section("Selected Apps (\(manager.selection.applicationTokens.count))") {
                        ForEach(Array(manager.selection.applicationTokens), id: \.self) { token in
                            Label {
                                Text("App")  // tokens are opaque; real names show in the picker
                            } icon: {
                                Image(systemName: "app.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                if !manager.selection.categoryTokens.isEmpty {
                    Section("Selected Categories (\(manager.selection.categoryTokens.count))") {
                        ForEach(Array(manager.selection.categoryTokens), id: \.self) { token in
                            Label {
                                Text("Category")
                            } icon: {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                if !manager.selection.applicationTokens.isEmpty ||
                   !manager.selection.categoryTokens.isEmpty {
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
            .familyActivityPicker(isPresented: $showPicker,
                                  selection: $manager.selection)
        }
    }
}

#Preview {
    AppSelectionView()
        .environmentObject(BlockingManager())
}
