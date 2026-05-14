import SwiftUI

struct FooterView: View {
    var body: some View {
        HStack {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
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
