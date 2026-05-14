import SwiftUI
import AppKit

struct SpecCardView: View {
    let item: OodiPopSpec

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)

                    if let format = item.format {
                        Text(format)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    copySpec()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy")
            }

            VStack(spacing: 8) {
                SpecRow(label: "Dimensions", value: item.dimensions)
                SpecRow(label: "Aspect Ratio", value: item.aspectRatio)
                SpecRow(label: "File Type", value: item.fileType)
                SpecRow(label: "File Size", value: item.fileSize)
            }

            if let settings = item.settings, !settings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(settings)
                        .font(.caption)
                }
            }

            if let notes = item.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(notes)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func copySpec() {
        let text = """
        \(item.title)
        Dimensions: \(item.dimensions ?? "-")
        Aspect Ratio: \(item.aspectRatio ?? "-")
        Format: \(item.format ?? "-")
        File Type: \(item.fileType ?? "-")
        File Size: \(item.fileSize ?? "-")
        Settings: \(item.settings ?? "-")
        Notes: \(item.notes ?? "-")
        """

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
