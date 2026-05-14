import SwiftUI

struct FooterView: View {
    var body: some View {
        HStack(spacing: 10) {
            Button {
                NotificationCenter.default.post(name: .oodiPopOpenMediaRequested, object: nil)
            } label: {
                Label("Open Image", systemImage: "photo.badge.plus")
            }
            .buttonStyle(.plain)
            .help("Open an image or video preview")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Oodi Pop")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

extension Notification.Name {
    static let oodiPopOpenMediaRequested = Notification.Name("oodiPopOpenMediaRequested")
}
