import SwiftUI

struct ProposedTransactionCard: View {
    let proposals: [ProposedTransaction]
    let onConfirm: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "plus.circle.fill").foregroundStyle(.green)
                Text("Add \(proposals.count) transaction\(proposals.count == 1 ? "" : "s")?")
                    .font(.subheadline.bold())
                Spacer()
            }

            ForEach(proposals) { p in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.title).font(.caption.weight(.medium))
                        Text(p.category).font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("$\(String(format: "%.2f", p.amount))")
                        .font(.caption.monospacedDigit())
                    Image(systemName: p.paymentMethod == .cash ? "banknote" : "creditcard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                Button("Discard", action: onDiscard)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Add All", action: onConfirm)
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }
}
