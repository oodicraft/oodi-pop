import SwiftUI

struct SearchBarView: View {
    @EnvironmentObject private var store: OodiPopStore

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search size, format, ratio...", text: $store.searchText)
                .textFieldStyle(.plain)

            if !store.searchText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                        store.searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
    }
}
