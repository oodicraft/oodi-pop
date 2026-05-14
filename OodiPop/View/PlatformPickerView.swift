import SwiftUI

struct PlatformPickerView: View {
    @EnvironmentObject private var store: OodiPopStore

    let platforms: [OodiPopPlatform]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(platforms) { platform in
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                            store.selectedPlatform = platform
                            store.searchText = ""
                        }
                    } label: {
                        HStack(spacing: 6) {
                            PlatformIconView(resourceName: platform.iconResourceName)

                            Text(platform.platform)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            store.selectedPlatform?.id == platform.id
                            ? Color.accentColor.opacity(0.18)
                            : Color.gray.opacity(0.12)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}
