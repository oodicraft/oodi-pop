import SwiftUI

struct OodiPopMenuView: View {
    @EnvironmentObject private var store: OodiPopStore
    @State private var displayMode: SpecDisplayMode = .card

    var body: some View {
        VStack(spacing: 0) {
            if let catalog = store.catalog {
                PlatformPickerView(platforms: catalog.platforms)

                Divider()

                SearchBarView(displayMode: $displayMode)

                Divider()

                Group {
                    switch displayMode {
                    case .list:
                        SpecListView(items: store.filteredItems)
                    case .card:
                        SpecGalleryView(items: store.filteredItems)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .animation(.spring(response: 0.24, dampingFraction: 0.88), value: displayMode)
            } else {
                ProgressView("Loading Oodi Pop...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            FooterView()
        }
    }
}

enum SpecDisplayMode: String, CaseIterable, Identifiable {
    case list
    case card

    var id: String { rawValue }

    var title: String {
        switch self {
        case .list:
            "List"
        case .card:
            "Card"
        }
    }

    var systemImage: String {
        switch self {
        case .list:
            "list.bullet"
        case .card:
            "square.grid.2x2"
        }
    }
}
