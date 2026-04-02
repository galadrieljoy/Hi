import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedTab      = 0
    @State private var selectedSidebar: Int? = 0

    var body: some View {
        if sizeClass == .compact {
            // iPhone: tab bar
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "chart.pie.fill") }
                    .tag(0)

                TransactionListView()
                    .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle") }
                    .tag(1)

                BudgetListView()
                    .tabItem { Label("Budgets", systemImage: "dollarsign.circle.fill") }
                    .tag(2)

                WealthView()
                    .tabItem { Label("Wealth", systemImage: "chart.line.uptrend.xyaxis") }
                    .tag(3)

                AssistantView()
                    .tabItem { Label("Assistant", systemImage: "bubble.left.and.bubble.right.fill") }
                    .tag(4)
            }
        } else {
            // iPad / Mac: sidebar + detail
            NavigationSplitView {
                SidebarView(selection: $selectedSidebar)
            } detail: {
                switch selectedSidebar ?? 0 {
                case 0: DashboardView()
                case 1: TransactionListView()
                case 2: BudgetListView()
                case 3: WealthView()
                case 4: AssistantView()
                case 5: SettingsView()
                default: DashboardView()
                }
            }
        }
    }
}

struct SidebarView: View {
    @Binding var selection: Int?

    private let items: [(label: String, icon: String, tag: Int)] = [
        ("Dashboard",    "chart.pie.fill",                         0),
        ("Transactions", "list.bullet.rectangle",                  1),
        ("Budgets",      "dollarsign.circle.fill",                 2),
        ("Wealth",       "chart.line.uptrend.xyaxis",              3),
        ("Assistant",    "bubble.left.and.bubble.right.fill",      4),
        ("Settings",     "gearshape.fill",                         5),
    ]

    var body: some View {
        List(items, id: \.tag, selection: $selection) { item in
            Label(item.label, systemImage: item.icon)
                .tag(item.tag)
        }
        .navigationTitle("BudgetBuddy")
        .listStyle(.sidebar)
    }
}
