import SwiftUI

struct OodiPopMenuView: View {
    @EnvironmentObject private var store: OodiPopStore

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            Divider()

            if let catalog = store.catalog {
                PlatformPickerView(platforms: catalog.platforms)

                Divider()

                SearchBarView()

                Divider()

                SpecListView(items: store.filteredItems)
            } else {
                ProgressView("Loading Oodi Pop...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            FooterView()
        }
    }
}
