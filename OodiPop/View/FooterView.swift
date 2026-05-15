import SwiftUI

struct FooterView: View {
    var body: some View {
        HStack(spacing: 10) {
            Button {
                NotificationCenter.default.post(name: .oodiPopOpenMediaRequested, object: nil)
            } label: {
                Label("Open", systemImage: "photo.badge.plus")
            }
            .buttonStyle(.plain)
            .help("Open an image or video preview")

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

extension Notification.Name {
    static let oodiPopOpenMediaRequested = Notification.Name("oodiPopOpenMediaRequested")
}
