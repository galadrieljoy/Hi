import SwiftUI
import FamilyControls

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
    }
}
