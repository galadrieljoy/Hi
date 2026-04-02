import SwiftUI

/// A text field that accepts decimal input and binds to a Double.
struct CurrencyTextField: View {
    let label: String
    @Binding var value: Double
    @State private var text: String = ""

    var body: some View {
        HStack {
            Text("$").foregroundStyle(.secondary)
            TextField(label, text: $text)
                .keyboardType(.decimalPad)
                .onChange(of: text) { newVal in
                    value = Double(newVal) ?? 0
                }
                .onAppear {
                    text = value == 0 ? "" : String(format: "%.2f", value)
                }
        }
    }
}
