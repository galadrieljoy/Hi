import SwiftUI
import Charts

struct NetWorthView: View {
    @EnvironmentObject var store: BudgetStore
    @State private var showAddAsset     = false
    @State private var showAddLiability = false
    @State private var editAsset: Asset?
    @State private var editLiability: Liability?

    private var totalAssets:      Double { store.assets.reduce(0) { $0 + $1.value } }
    private var totalLiabilities: Double { store.liabilities.reduce(0) { $0 + $1.balance } }
    private var netWorth:         Double { store.currentNetWorth() }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Net worth header card
                netWorthHeader

                // Line chart
                if store.netWorthHistory.count >= 2 {
                    netWorthChart
                }

                // Assets
                assetsSection

                // Liabilities
                liabilitiesSection
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showAddAsset = true } label: { Label("Add Asset", systemImage: "plus.circle") }
                    Button { showAddLiability = true } label: { Label("Add Liability", systemImage: "minus.circle") }
                    Button { store.syncBankAssetsFromLinkedAccounts(); store.syncInvestmentAssets(); store.recordNetWorthSnapshot() }
                    label: { Label("Refresh & Snapshot", systemImage: "arrow.clockwise") }
                } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddAsset) { AddAssetView() }
        .sheet(isPresented: $showAddLiability) { AddLiabilityView() }
        .sheet(item: $editAsset) { AddAssetView(existing: $0) }
        .sheet(item: $editLiability) { AddLiabilityView(existing: $0) }
    }

    // MARK: - Sub-views

    private var netWorthHeader: some View {
        VStack(spacing: 8) {
            Text("Net Worth")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("$\(String(format: "%.2f", netWorth))")
                .font(.largeTitle.bold().monospacedDigit())
                .foregroundStyle(netWorth >= 0 ? .primary : .red)

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("Assets").font(.caption).foregroundStyle(.secondary)
                    Text("$\(String(format: "%.0f", totalAssets))").font(.subheadline.monospacedDigit().bold()).foregroundStyle(Color.green)
                }
                VStack(spacing: 2) {
                    Text("Liabilities").font(.caption).foregroundStyle(.secondary)
                    Text("$\(String(format: "%.0f", totalLiabilities))").font(.subheadline.monospacedDigit().bold()).foregroundStyle(Color.red)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private var netWorthChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Net Worth History").font(.headline)
            Chart(store.netWorthHistory) { snap in
                LineMark(x: .value("Date", snap.date), y: .value("Net Worth", snap.netWorth))
                    .foregroundStyle(Color.accentColor)
                AreaMark(x: .value("Date", snap.date), y: .value("Net Worth", snap.netWorth))
                    .foregroundStyle(Color.accentColor.opacity(0.1))
            }
            .frame(height: 160)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private var assetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ASSETS").font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                Text("$\(String(format: "%.0f", totalAssets))").font(.caption.bold()).foregroundStyle(.green)
            }
            ForEach(store.assets) { asset in
                HStack {
                    Label(asset.name, systemImage: asset.type.sfSymbol)
                        .font(.subheadline)
                    Spacer()
                    Text("$\(String(format: "%.0f", asset.value))").font(.subheadline.monospacedDigit())
                }
                .swipeActions {
                    Button(role: .destructive) { store.deleteAsset(asset) } label: { Label("Delete", systemImage: "trash") }
                    Button { editAsset = asset } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                }
            }
            Button { showAddAsset = true } label: { Label("Add Asset", systemImage: "plus").font(.subheadline) }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private var liabilitiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LIABILITIES").font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                Text("$\(String(format: "%.0f", totalLiabilities))").font(.caption.bold()).foregroundStyle(Color.red)
            }
            ForEach(store.liabilities) { liability in
                HStack {
                    Label(liability.name, systemImage: liability.type.sfSymbol).font(.subheadline)
                    Spacer()
                    Text("$\(String(format: "%.0f", liability.balance))").font(.subheadline.monospacedDigit()).foregroundStyle(Color.red)
                }
                .swipeActions {
                    Button(role: .destructive) { store.deleteLiability(liability) } label: { Label("Delete", systemImage: "trash") }
                    Button { editLiability = liability } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                }
            }
            Button { showAddLiability = true } label: { Label("Add Liability", systemImage: "plus").font(.subheadline) }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
