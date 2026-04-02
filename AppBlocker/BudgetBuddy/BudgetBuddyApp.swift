import SwiftUI
import UserNotifications

@main
struct BudgetBuddyApp: App {
    @StateObject private var store = BudgetStore()

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .onAppear {
                    store.processSubscriptionsDue()
                }
        }
    }
}
