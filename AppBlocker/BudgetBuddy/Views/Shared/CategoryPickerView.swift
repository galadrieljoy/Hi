import SwiftUI

struct CategoryPickerView: View {
    @EnvironmentObject var store: BudgetStore
    @Binding var selected: String

    var body: some View {
        Picker("Category", selection: $selected) {
            ForEach(store.categories, id: \.name) { cat in
                Label(cat.name, systemImage: cat.sfSymbol).tag(cat.name)
            }
        }
    }
}
