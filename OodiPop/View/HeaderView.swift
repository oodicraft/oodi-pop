import SwiftUI

struct HeaderView: View {
    @EnvironmentObject private var store: OodiPopStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Oodi Pop")
                .font(.title2)
                .fontWeight(.semibold)

            if let updatedAt = store.catalog?.updatedAt {
                Text("Updated: \(updatedAt)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
