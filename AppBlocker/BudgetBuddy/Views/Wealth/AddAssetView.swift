import SwiftUI

struct AddAssetView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss
    var existing: Asset?

    @State private var name  = ""
    @State private var type  = AssetType.other
    @State private var value = 0.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Asset") {
                    TextField("Name (e.g. My Car)", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(AssetType.allCases, id: \.self) {
                            Label($0.rawValue, systemImage: $0.sfSymbol).tag($0)
                        }
                    }
                    CurrencyTextField(label: "Value", value: $value)
                }
            }
            .navigationTitle(existing == nil ? "Add Asset" : "Edit Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let a = Asset(id: existing?.id ?? UUID(), name: name, type: type, value: value)
                        if existing != nil { store.updateAsset(a) } else { store.addAsset(a) }
                        dismiss()
                    }.disabled(name.isEmpty || value <= 0)
                }
            }
            .onAppear {
                if let a = existing { name = a.name; type = a.type; value = a.value }
            }
        }
    }
}
