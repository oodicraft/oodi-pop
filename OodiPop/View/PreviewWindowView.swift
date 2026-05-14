import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct PreviewWindowView: View {
    @StateObject var session: OodiPopPreviewSession

    var body: some View {
        NavigationSplitView {
            List(session.catalog.platforms, selection: selectedPlatformID) { platform in
                HStack(spacing: 10) {
                    PlatformIconView(resourceName: platform.iconResourceName)
                        .frame(width: 18, height: 18)

                    Text(platform.platform)
                        .lineLimit(1)
                }
                .tag(platform.id)
            }
            .listStyle(.sidebar)
            .navigationTitle(session.fileURL.lastPathComponent)
//            .navigationSubtitle("\(mediaKindLabel) preview export")
//            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
        } detail: {
            VStack(spacing: 0) {
                previewContent

                if let errorMessage = session.errorMessage {
                    Divider()

                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                        Text(errorMessage)
                            .lineLimit(2)
                        Spacer()
                        Button("Dismiss") {
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                                session.errorMessage = nil
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 860, minHeight: 560)
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var previewContent: some View {
        if session.previewItems.isEmpty {
            ContentUnavailableView(
                "No matching specs",
                systemImage: "rectangle.dashed",
                description: Text("This platform does not have exportable \(mediaKindLabel) specs with numeric dimensions.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                WaterfallPreviewGrid(session: session)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var mediaKindLabel: String {
        switch session.mediaKind {
        case .image:
            "Image"
        case .video:
            "Video"
        }
    }

    private var selectedPlatformID: Binding<String?> {
        Binding(
            get: { session.selectedPlatform.id },
            set: { id in
                guard let id,
                      let platform = session.catalog.platforms.first(where: { $0.id == id }) else {
                    return
                }

                withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                    session.selectedPlatform = platform
                    session.errorMessage = nil
                }
            }
        )
    }
}

private struct WaterfallPreviewGrid: View {
    @ObservedObject var session: OodiPopPreviewSession

    @State private var availableWidth: CGFloat = 980

    private let spacing: CGFloat = 12

    var body: some View {
        let layout = makeLayout(availableWidth: availableWidth)

        HStack(alignment: .top, spacing: spacing) {
            ForEach(layout.columns.indices, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(layout.columns[columnIndex]) { item in
                        PreviewSpecCard(
                            session: session,
                            item: item,
                            columnWidth: layout.columnWidth
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                .frame(width: layout.columnWidth)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: layout.height, alignment: .top)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: WaterfallWidthPreferenceKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(WaterfallWidthPreferenceKey.self) { width in
            availableWidth = width
        }
        .animation(.spring(response: 0.26, dampingFraction: 0.88), value: session.previewItems.map(\.id))
    }

    private func makeLayout(availableWidth: CGFloat) -> WaterfallLayout {
        let columnCount = max(1, min(4, Int((availableWidth + spacing) / 220)))
        let columnWidth = floor((availableWidth - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount))
        var columns = Array(repeating: [OodiPopPreviewItem](), count: columnCount)
        var heights = Array(repeating: CGFloat.zero, count: columnCount)

        for item in session.previewItems {
            let cardHeight = PreviewSpecCard.height(for: item.dimension, columnWidth: columnWidth)
            let targetColumn = heights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columns[targetColumn].append(item)
            heights[targetColumn] += cardHeight + spacing
        }

        let height = max(1, (heights.max() ?? 1) - spacing)
        return WaterfallLayout(columns: columns, columnWidth: columnWidth, height: height)
    }
}

private struct WaterfallLayout {
    let columns: [[OodiPopPreviewItem]]
    let columnWidth: CGFloat
    let height: CGFloat
}

private struct WaterfallWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 980

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct PreviewSpecCard: View {
    @ObservedObject var session: OodiPopPreviewSession
    let item: OodiPopPreviewItem
    let columnWidth: CGFloat

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PreviewMediaView(fileURL: session.fileURL, mediaKind: session.mediaKind)
                .opacity(0.95)
                .overlay(Color.black.opacity(0.08))
                .frame(width: columnWidth, height: cardHeight)
                .clipped()

            HStack(spacing: 8) {
                Text(item.dimension.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(.regularMaterial)
                    .clipShape(Capsule())

                Button {
                    export()
                } label: {
                    if session.exportingItemID == item.id {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)
                .disabled(session.exportingItemID != nil)
                .frame(width: 32, height: 32)
                .background(.regularMaterial)
                .clipShape(Circle())
                .help("Export \(item.dimension.label)")
            }
            .padding(12)
        }
        .frame(width: columnWidth, height: cardHeight)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .frame(height: cardHeight)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var cardHeight: CGFloat {
        Self.height(for: item.dimension, columnWidth: columnWidth)
    }

    static func height(for dimension: OodiPopDimension, columnWidth: CGFloat) -> CGFloat {
        let ratioHeight = columnWidth * CGFloat(dimension.height) / CGFloat(dimension.width)
        return max(ratioHeight, 76)
    }

    private func export() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = defaultFilename

        switch session.mediaKind {
        case .image:
            panel.allowedContentTypes = [.png]
        case .video:
            panel.allowedContentTypes = [.mpeg4Movie]
        }

        guard panel.runModal() == .OK, let destinationURL = panel.url else {
            return
        }

        session.exportingItemID = item.id
        session.errorMessage = nil

        Task {
            do {
                switch session.mediaKind {
                case .image:
                    try MediaPreviewExportService.exportImage(
                        sourceURL: session.fileURL,
                        dimension: item.dimension,
                        destinationURL: destinationURL
                    )
                case .video:
                    try await MediaPreviewExportService.exportVideo(
                        sourceURL: session.fileURL,
                        dimension: item.dimension,
                        destinationURL: destinationURL
                    )
                }

                await MainActor.run {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                        session.exportingItemID = nil
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                        session.exportingItemID = nil
                        session.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private var defaultFilename: String {
        let base = "\(session.selectedPlatform.platform)-\(item.spec.title)-\(item.dimension.label)"
            .replacingOccurrences(of: "[^A-Za-z0-9_-]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        switch session.mediaKind {
        case .image:
            return "\(base).png"
        case .video:
            return "\(base).mp4"
        }
    }
}

private struct PreviewMediaView: View {
    let fileURL: URL
    let mediaKind: OodiPopMediaKind

    var body: some View {
        switch mediaKind {
        case .image:
            if let image = NSImage(contentsOf: fileURL) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        case .video:
            VideoThumbnailView(fileURL: fileURL)
        }
    }

    private var placeholder: some View {
        Color.gray.opacity(0.1)
    }
}

private struct VideoThumbnailView: View {
    let fileURL: URL

    @State private var thumbnail: NSImage?

    var body: some View {
        ZStack {
            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.1)
                ProgressView()
                    .controlSize(.small)
            }
        }
        .task(id: fileURL) {
            thumbnail = await generateThumbnail()
        }
    }

    private func generateThumbnail() async -> NSImage? {
        await Task.detached(priority: .userInitiated) {
            let asset = AVURLAsset(url: fileURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 900, height: 900)

            guard let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) else {
                return nil
            }

            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }.value
    }
}
