import SwiftUI
import AppKit

struct PlatformIconView: View {
    let resourceName: String

    var body: some View {
        if let image = PlatformIconLoader.image(named: resourceName) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
        } else {
            Image(systemName: "network")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 14, height: 14)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}

private enum PlatformIconLoader {
    static func image(named resourceName: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "svg"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }

        image.isTemplate = true
        return image
    }
}
