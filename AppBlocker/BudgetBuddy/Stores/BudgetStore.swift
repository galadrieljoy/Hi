import Foundation
import UserNotifications

@MainActor
class BudgetStore: ObservableObject {

    // MARK: - Published State

    @Published var transactions:           [Transaction]            = []
    @Published var categories:             [Category]               = Category.systemCategories
    @Published var budgetLimits:           [BudgetLimit]            = []
    @Published var investmentAccounts:     [InvestmentAccount]      = []
    @Published var investmentContributions:[InvestmentContribution] = []
    @Published var cashBudgets:            [CashBudget]             = []
    @Published var subscriptions:          [Subscription]           = []
    @Published var linkedAccounts:         [LinkedAccount]          = []
    @Published var assets:                 [Asset]                  = []
    @Published var liabilities:            [Liability]              = []
    @Published var netWorthHistory:        [NetWorthSnapshot]       = []

    init() {
        loadAll()
    }

    // MARK: - Persistence helpers

    private func save<T: Encodable>(_ value: T, to file: String) {
        Task.detached {
            try? await PersistenceStore.shared.save(value, to: file)
        }
    }

    private func load<T: Decodable>(_ type: T.Type, from file: String, default value: T) -> T {
        // Synchronous load on init (called before async tasks can run)
        guard let url = resolvedURLSync(file) else { return value }
        guard let data = try? Data(contentsOf: url) else { return value }
        return (try? JSONDecoder().decode(type, from: data)) ?? value
    }

    private func resolvedURLSync(_ filename: String) -> URL? {
        // iCloud unavailable (no entitlement on free Apple ID) — use local Documents
        let local = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        return local
    }

    func loadAll() {
        transactions            = load([Transaction].self,             from: "transactions.json",             default: [])
        budgetLimits            = load([BudgetLimit].self,             from: "budgetLimits.json",             default: [])
        investmentAccounts      = load([InvestmentAccount].self,       from: "investmentAccounts.json",       default: [])
        investmentContributions = load([InvestmentContribution].self,  from: "investmentContributions.json",  default: [])
        cashBudgets             = load([CashBudget].self,              from: "cashBudgets.json",              default: [])
        subscriptions           = load([Subscription].self,            from: "subscriptions.json",            default: [])
        linkedAccounts          = load([LinkedAccount].self,           from: "linkedAccounts.json",           default: [])
        assets                  = load([Asset].self,                   from: "assets.json",                   default: [])
        liabilities             = load([Liability].self,               from: "liabilities.json",              default: [])
        netWorthHistory         = load([NetWorthSnapshot].self,        from: "netWorthHistory.json",          default: [])

        let savedCategories = load([Category].self, from: "categories.json", default: [])
        if !savedCategories.isEmpty { categories = savedCategories }
    }

    // MARK: - Transactions

    func add(_ transaction: Transaction) {
        transactions.append(transaction)
        save(transactions, to: "transactions.json")
    }

    func update(_ transaction: Transaction) {
        if let i = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[i] = transaction
            save(transactions, to: "transactions.json")
        }
    }

    func delete(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        save(transactions, to: "transactions.json")
    }

    func addAll(_ newTransactions: [Transaction]) {
        let existingPlaidIDs = Set(transactions.compactMap(\.plaidID))
        let toAdd = newTransactions.filter { t in
            guard let pid = t.plaidID else { return true }
            return !existingPlaidIDs.contains(pid)
        }
        transactions.append(contentsOf: toAdd)
        save(transactions, to: "transactions.json")
    }

    // MARK: - Budget Limits

    func setLimit(_ limit: BudgetLimit) {
        if let i = budgetLimits.firstIndex(where: {
            $0.categoryName == limit.categoryName && $0.month == limit.month && $0.year == limit.year
        }) {
            budgetLimits[i] = limit
        } else {
            budgetLimits.append(limit)
        }
        save(budgetLimits, to: "budgetLimits.json")
    }

    func deleteLimit(_ limit: BudgetLimit) {
        budgetLimits.removeAll { $0.id == limit.id }
        save(budgetLimits, to: "budgetLimits.json")
    }

    func spent(in category: String, month: Int, year: Int) -> Double {
        transactions.filter {
            $0.type == .expense &&
            $0.categoryName == category &&
            Calendar.current.component(.month, from: $0.date) == month &&
            Calendar.current.component(.year,  from: $0.date) == year
        }.reduce(0) { $0 + $1.amount }
    }

    func limit(for category: String, month: Int, year: Int) -> Double? {
        budgetLimits.first {
            $0.categoryName == category && $0.month == month && $0.year == year
        }?.monthlyLimit
    }

    func totalSpent(month: Int, year: Int) -> Double {
        transactions.filter {
            $0.type == .expense &&
            Calendar.current.component(.month, from: $0.date) == month &&
            Calendar.current.component(.year,  from: $0.date) == year
        }.reduce(0) { $0 + $1.amount }
    }

    func totalIncome(month: Int, year: Int) -> Double {
        transactions.filter {
            $0.type == .income &&
            Calendar.current.component(.month, from: $0.date) == month &&
            Calendar.current.component(.year,  from: $0.date) == year
        }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Investment Accounts

    func addAccount(_ account: InvestmentAccount) {
        investmentAccounts.append(account)
        save(investmentAccounts, to: "investmentAccounts.json")
    }

    func updateAccount(_ account: InvestmentAccount) {
        if let i = investmentAccounts.firstIndex(where: { $0.id == account.id }) {
            investmentAccounts[i] = account
            save(investmentAccounts, to: "investmentAccounts.json")
        }
    }

    func deleteAccount(_ account: InvestmentAccount) {
        investmentAccounts.removeAll { $0.id == account.id }
        investmentContributions.removeAll { $0.accountID == account.id }
        save(investmentAccounts, to: "investmentAccounts.json")
        save(investmentContributions, to: "investmentContributions.json")
    }

    func addContribution(_ c: InvestmentContribution) {
        investmentContributions.append(c)
        save(investmentContributions, to: "investmentContributions.json")
    }

    func deleteContribution(_ c: InvestmentContribution) {
        investmentContributions.removeAll { $0.id == c.id }
        save(investmentContributions, to: "investmentContributions.json")
    }

    func contributed(to accountID: UUID, month: Int, year: Int) -> Double {
        investmentContributions.filter {
            $0.accountID == accountID &&
            Calendar.current.component(.month, from: $0.date) == month &&
            Calendar.current.component(.year,  from: $0.date) == year
        }.reduce(0) { $0 + $1.amount }
    }

    func totalContributed(to accountID: UUID) -> Double {
        investmentContributions.filter { $0.accountID == accountID }.reduce(0) { $0 + $1.amount }
    }

    func contributionHistory(for accountID: UUID) -> [(label: String, total: Double)] {
        let relevant = investmentContributions.filter { $0.accountID == accountID }
        let grouped  = Dictionary(grouping: relevant) { c -> String in
            let comps = Calendar.current.dateComponents([.year, .month], from: c.date)
            return "\(comps.year ?? 0)-\(String(format: "%02d", comps.month ?? 0))"
        }
        return grouped.map { (label: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.label < $1.label }
    }

    // MARK: - Cash Budgets

    func addCashBudget(_ budget: CashBudget) {
        cashBudgets.append(budget)
        save(cashBudgets, to: "cashBudgets.json")
    }

    func updateCashBudget(_ budget: CashBudget) {
        if let i = cashBudgets.firstIndex(where: { $0.id == budget.id }) {
            cashBudgets[i] = budget
            save(cashBudgets, to: "cashBudgets.json")
        }
    }

    func deleteCashBudget(_ budget: CashBudget) {
        cashBudgets.removeAll { $0.id == budget.id }
        save(cashBudgets, to: "cashBudgets.json")
    }

    func activeCashBudget(on date: Date = Date()) -> CashBudget? {
        cashBudgets.first {
            $0.startDate <= date && ($0.endDate == nil || $0.endDate! >= date)
        }
    }

    static func weekNumber(for date: Date, startDate: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: startDate),
                                                   to: Calendar.current.startOfDay(for: date)).day ?? 0
        return max(1, days / 7 + 1)
    }

    func cashSpentThisWeek(of budget: CashBudget, on ref: Date = Date()) -> Double {
        let week      = BudgetStore.weekNumber(for: ref, startDate: budget.startDate)
        let weekStart = Calendar.current.date(byAdding: .day, value: (week - 1) * 7, to: budget.startDate)!
        let weekEnd   = Calendar.current.date(byAdding: .day, value: week * 7, to: budget.startDate)!
        return transactions.filter {
            $0.paymentMethod == .cash &&
            $0.type == .expense &&
            $0.date >= weekStart && $0.date < weekEnd
        }.reduce(0) { $0 + $1.amount }
    }

    func cashBreakdown(of budget: CashBudget, weekNumber: Int) -> [(category: String, total: Double)] {
        let weekStart = Calendar.current.date(byAdding: .day, value: (weekNumber - 1) * 7, to: budget.startDate)!
        let weekEnd   = Calendar.current.date(byAdding: .day, value: weekNumber * 7, to: budget.startDate)!
        let relevant  = transactions.filter {
            $0.paymentMethod == .cash && $0.type == .expense &&
            $0.date >= weekStart && $0.date < weekEnd
        }
        let grouped   = Dictionary(grouping: relevant) { $0.categoryName }
        return grouped.map { (category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    // MARK: - Subscriptions

    func addSubscription(_ sub: Subscription) {
        subscriptions.append(sub)
        save(subscriptions, to: "subscriptions.json")
        scheduleSubscriptionNotifications(sub)
    }

    func updateSubscription(_ sub: Subscription) {
        if let i = subscriptions.firstIndex(where: { $0.id == sub.id }) {
            subscriptions[i] = sub
            save(subscriptions, to: "subscriptions.json")
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [sub.id.uuidString + "-today", sub.id.uuidString + "-warning"]
            )
            scheduleSubscriptionNotifications(sub)
        }
    }

    func deleteSubscription(_ sub: Subscription) {
        subscriptions.removeAll { $0.id == sub.id }
        save(subscriptions, to: "subscriptions.json")
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [sub.id.uuidString + "-today", sub.id.uuidString + "-warning"]
        )
    }

    func processSubscriptionsDue() {
        let now = Date()
        var changed = false
        for i in subscriptions.indices {
            guard subscriptions[i].isActive && subscriptions[i].nextBillingDate <= now else { continue }
            if subscriptions[i].autoAddToTransactions {
                let t = Transaction(
                    amount: subscriptions[i].amount,
                    type: .expense,
                    categoryName: subscriptions[i].categoryName,
                    title: subscriptions[i].name,
                    note: "Auto-added subscription"
                )
                transactions.append(t)
            }
            subscriptions[i].advanceToNextCycle()
            scheduleSubscriptionNotifications(subscriptions[i])
            changed = true
        }
        if changed {
            save(subscriptions, to: "subscriptions.json")
            save(transactions, to: "transactions.json")
        }
    }

    func totalMonthlySubscriptionCost() -> Double {
        subscriptions.filter(\.isActive).reduce(0) { $0 + $1.monthlyEquivalentCost }
    }

    private func scheduleSubscriptionNotifications(_ sub: Subscription) {
        guard sub.isActive && sub.autoAddToTransactions else { return }
        let center = UNUserNotificationCenter.current()
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency

        // Day-of notification
        let todayContent = UNMutableNotificationContent()
        todayContent.title = "\(sub.name) bills today"
        todayContent.body  = "\(formatter.string(from: NSNumber(value: sub.amount)) ?? "$\(sub.amount)") will be added to your budget."
        todayContent.sound = .default
        var todayComps     = Calendar.current.dateComponents([.year, .month, .day], from: sub.nextBillingDate)
        todayComps.hour    = 9; todayComps.minute = 0
        let todayTrigger   = UNCalendarNotificationTrigger(dateMatching: todayComps, repeats: false)
        center.add(UNNotificationRequest(identifier: sub.id.uuidString + "-today", content: todayContent, trigger: todayTrigger))

        // 3-day warning
        guard let warningDate = Calendar.current.date(byAdding: .day, value: -3, to: sub.nextBillingDate) else { return }
        let warnContent  = UNMutableNotificationContent()
        warnContent.title = "\(sub.name) bills in 3 days"
        warnContent.body  = formatter.string(from: NSNumber(value: sub.amount)) ?? "$\(sub.amount)"
        warnContent.sound = .default
        var warnComps     = Calendar.current.dateComponents([.year, .month, .day], from: warningDate)
        warnComps.hour    = 9; warnComps.minute = 0
        let warnTrigger   = UNCalendarNotificationTrigger(dateMatching: warnComps, repeats: false)
        center.add(UNNotificationRequest(identifier: sub.id.uuidString + "-warning", content: warnContent, trigger: warnTrigger))
    }

    // MARK: - Linked Accounts (Plaid)

    func addLinkedAccount(_ account: LinkedAccount) {
        linkedAccounts.append(account)
        save(linkedAccounts, to: "linkedAccounts.json")
    }

    func updateLinkedAccount(_ account: LinkedAccount) {
        if let i = linkedAccounts.firstIndex(where: { $0.id == account.id }) {
            linkedAccounts[i] = account
            save(linkedAccounts, to: "linkedAccounts.json")
        }
    }

    func removeLinkedAccount(_ account: LinkedAccount) {
        linkedAccounts.removeAll { $0.id == account.id }
        save(linkedAccounts, to: "linkedAccounts.json")
    }

    func totalBankBalance() -> Double {
        linkedAccounts.reduce(0) { $0 + $1.currentBalance }
    }

    func syncBankAssetsFromLinkedAccounts() {
        for account in linkedAccounts {
            let name = "\(account.institutionName) \(account.accountName)"
            if let i = assets.firstIndex(where: { $0.name == name && $0.type == .bankAccount }) {
                assets[i].value       = account.currentBalance
                assets[i].lastUpdated = Date()
            } else {
                assets.append(Asset(name: name, type: .bankAccount, value: account.currentBalance))
            }
        }
        save(assets, to: "assets.json")
    }

    func checkLowBalanceAlert(threshold: Double) {
        for account in linkedAccounts where account.currentBalance < threshold {
            let content    = UNMutableNotificationContent()
            content.title  = "Low Balance Alert"
            content.body   = "\(account.institutionName) \(account.accountName) balance is \(String(format: "$%.2f", account.currentBalance)) — below your $\(Int(threshold)) threshold."
            content.sound  = .default
            let trigger    = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: "low-balance-\(account.id)", content: content, trigger: trigger)
            )
        }
    }

    // MARK: - Assets & Liabilities

    func addAsset(_ asset: Asset) {
        assets.append(asset)
        save(assets, to: "assets.json")
    }

    func updateAsset(_ asset: Asset) {
        if let i = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[i] = asset
            save(assets, to: "assets.json")
        }
    }

    func deleteAsset(_ asset: Asset) {
        assets.removeAll { $0.id == asset.id }
        save(assets, to: "assets.json")
    }

    func addLiability(_ liability: Liability) {
        liabilities.append(liability)
        save(liabilities, to: "liabilities.json")
    }

    func updateLiability(_ liability: Liability) {
        if let i = liabilities.firstIndex(where: { $0.id == liability.id }) {
            liabilities[i] = liability
            save(liabilities, to: "liabilities.json")
        }
    }

    func deleteLiability(_ liability: Liability) {
        liabilities.removeAll { $0.id == liability.id }
        save(liabilities, to: "liabilities.json")
    }

    func currentNetWorth() -> Double {
        assets.reduce(0) { $0 + $1.value } - liabilities.reduce(0) { $0 + $1.balance }
    }

    func recordNetWorthSnapshot() {
        let snapshot = NetWorthSnapshot(
            totalAssets:      assets.reduce(0) { $0 + $1.value },
            totalLiabilities: liabilities.reduce(0) { $0 + $1.balance }
        )
        netWorthHistory.append(snapshot)
        save(netWorthHistory, to: "netWorthHistory.json")
    }

    func syncInvestmentAssets() {
        for account in investmentAccounts {
            let total = totalContributed(to: account.id)
            let name  = account.name
            if let i = assets.firstIndex(where: { $0.name == name && $0.type == .investment }) {
                assets[i].value       = total
                assets[i].lastUpdated = Date()
            } else if total > 0 {
                assets.append(Asset(name: name, type: .investment, value: total))
            }
        }
        save(assets, to: "assets.json")
    }

    // MARK: - Summary text for Claude

    func summaryText(month: Int, year: Int) -> String {
        let calendar  = Calendar.current
        let monthName = DateFormatter().monthSymbols[month - 1]
        var lines     = ["Budget summary — \(monthName) \(year):"]
        lines.append("  Total spent:  $\(String(format: "%.2f", totalSpent(month: month, year: year)))")
        lines.append("  Total income: $\(String(format: "%.2f", totalIncome(month: month, year: year)))")

        for cat in categories where cat.name != "Income" {
            let s = spent(in: cat.name, month: month, year: year)
            if s > 0 {
                let lim = limit(for: cat.name, month: month, year: year).map { " / $\(String(format: "%.2f", $0))" } ?? ""
                lines.append("  \(cat.name): $\(String(format: "%.2f", s))\(lim)")
            }
        }

        // Bank balance
        if !linkedAccounts.isEmpty {
            lines.append("")
            lines.append("Bank balance: $\(String(format: "%.2f", totalBankBalance()))")
        }

        // Active cash trip
        if let trip = activeCashBudget() {
            let week  = BudgetStore.weekNumber(for: Date(), startDate: trip.startDate)
            let spent = cashSpentThisWeek(of: trip)
            lines.append("")
            lines.append("Active trip: \(trip.tripName) — Week \(week)")
            lines.append("  Weekly cash budget: $\(String(format: "%.2f", trip.weeklyLimit))")
            lines.append("  Spent this week: $\(String(format: "%.2f", spent))")
            lines.append("  Remaining: $\(String(format: "%.2f", max(0, trip.weeklyLimit - spent)))")
        }

        // Subscriptions
        let activeSubs = subscriptions.filter(\.isActive)
        if !activeSubs.isEmpty {
            lines.append("")
            lines.append("Monthly subscriptions: $\(String(format: "%.2f", totalMonthlySubscriptionCost()))/mo")
            for sub in activeSubs.prefix(5) {
                lines.append("  \(sub.name): $\(String(format: "%.2f", sub.monthlyEquivalentCost))/mo")
            }
        }

        // Net worth
        let nw = currentNetWorth()
        if nw != 0 {
            lines.append("")
            lines.append("Net worth: $\(String(format: "%.2f", nw))")
            lines.append("  Assets: $\(String(format: "%.2f", assets.reduce(0) { $0 + $1.value }))")
            lines.append("  Liabilities: $\(String(format: "%.2f", liabilities.reduce(0) { $0 + $1.balance }))")
        }

        return lines.joined(separator: "\n")
    }
}
