import SwiftUI

struct SpecRow: View {
    let label: String
    let value: String?

    var body: some View {
        if let value, !value.isEmpty {
            HStack(alignment: .top) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(value)
                    .font(.caption)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
