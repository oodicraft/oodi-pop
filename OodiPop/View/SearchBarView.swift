import SwiftUI

struct SearchBarView: View {
    @EnvironmentObject private var store: OodiPopStore
    @Binding var displayMode: SpecDisplayMode

    var body: some View {
        HStack(spacing: 8) {
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

            Button {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                    displayMode = displayMode == .list ? .card : .list
                }
            } label: {
                Image(systemName: displayMode.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .help(displayMode == .list ? "Switch to Card" : "Switch to List")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
