import SwiftUI

struct SpecListView: View {
    let items: [OodiPopSpec]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    SpecCardView(item: item)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding()
            .animation(.spring(response: 0.26, dampingFraction: 0.88), value: items.map(\.id))
        }
    }
}
