import SwiftUI

struct WealthView: View {
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Segment", selection: $selectedSegment) {
                    Text("Investments").tag(0)
                    Text("Net Worth").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if selectedSegment == 0 {
                    InvestmentsView()
                } else {
                    NetWorthView()
                }
            }
            .navigationTitle("Wealth")
        }
    }
}
