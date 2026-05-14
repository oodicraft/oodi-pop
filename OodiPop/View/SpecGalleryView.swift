import SwiftUI
import AppKit

struct SpecGalleryView: View {
    let items: [OodiPopSpec]

    @State private var availableWidth: CGFloat = 404

    private let spacing: CGFloat = 8

    var body: some View {
        ScrollView {
            let layout = makeLayout(availableWidth: availableWidth)

            HStack(alignment: .top, spacing: spacing) {
                ForEach(layout.columns.indices, id: \.self) { columnIndex in
                    LazyVStack(spacing: spacing) {
                        ForEach(layout.columns[columnIndex]) { item in
                            SpecGalleryCard(item: item, columnWidth: layout.columnWidth)
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        }
                    }
                    .frame(width: layout.columnWidth)
                }
            }
            .frame(height: layout.height, alignment: .top)
            .padding(8)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SpecGalleryWidthPreferenceKey.self, value: proxy.size.width)
                }
            )
            .onPreferenceChange(SpecGalleryWidthPreferenceKey.self) { width in
                availableWidth = width
            }
            .animation(.spring(response: 0.26, dampingFraction: 0.88), value: items.map(\.id))
        }
    }

    private func makeLayout(availableWidth: CGFloat) -> SpecGalleryLayout {
        let columnCount = max(1, min(3, Int((availableWidth + spacing) / 126)))
        let columnWidth = floor((availableWidth - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount))
        var columns = Array(repeating: [OodiPopSpec](), count: columnCount)
        var heights = Array(repeating: CGFloat.zero, count: columnCount)

        for item in items {
            let targetColumn = heights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columns[targetColumn].append(item)
            heights[targetColumn] += SpecGalleryCard.height(for: item, columnWidth: columnWidth) + spacing
        }

        return SpecGalleryLayout(
            columns: columns,
            columnWidth: columnWidth,
            height: max(1, (heights.max() ?? 1) - spacing)
        )
    }
}

private struct SpecGalleryLayout {
    let columns: [[OodiPopSpec]]
    let columnWidth: CGFloat
    let height: CGFloat
}

private struct SpecGalleryWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 404

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct SpecGalleryCard: View {
    let item: OodiPopSpec
    let columnWidth: CGFloat

    private var dimension: OodiPopDimension? {
        OodiPopDimension(rawValue: item.dimensions)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Text(dimensionText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)

            Button {
                copySpec()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
            .padding(7)
            .background(.regularMaterial)
            .clipShape(Circle())
            .help("Copy")
            .padding(6)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var dimensionText: String {
        if let dimension {
            return dimension.label
        }

        if let dimensions = item.dimensions, !dimensions.isEmpty {
            return dimensions
        }

        if let aspectRatio = item.aspectRatio, !aspectRatio.isEmpty {
            return aspectRatio
        }

        return "Size varies"
    }

    private var cardHeight: CGFloat {
        Self.height(for: item, columnWidth: columnWidth)
    }

    static func height(for item: OodiPopSpec, columnWidth: CGFloat) -> CGFloat {
        guard let dimension = OodiPopDimension(rawValue: item.dimensions) else {
            return 104
        }

        let ratio = CGFloat(dimension.height) / CGFloat(dimension.width)
        return min(max(columnWidth * ratio, 92), 230)
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
