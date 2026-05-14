import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct PreviewWindowView: View {
    @StateObject var session: OodiPopPreviewSession

    var body: some View {
        VStack(spacing: 0) {
            previewHeader

            Divider()

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
                        .padding(20)
                }
            }

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
        .frame(minWidth: 720, minHeight: 520)
    }

    private var previewHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.fileURL.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)

                    Text("\(mediaKindLabel) preview export")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(session.catalog.platforms) { platform in
                        Button {
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                session.selectedPlatform = platform
                                session.errorMessage = nil
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
                                session.selectedPlatform.id == platform.id
                                ? Color.accentColor.opacity(0.18)
                                : Color.gray.opacity(0.12)
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
    }

    private var mediaKindLabel: String {
        switch session.mediaKind {
        case .image:
            "Image"
        case .video:
            "Video"
        }
    }
}

private struct WaterfallPreviewGrid: View {
    @ObservedObject var session: OodiPopPreviewSession

    @State private var availableWidth: CGFloat = 980

    private let spacing: CGFloat = 16
    private let cardChromeHeight: CGFloat = 73
    private let cardPadding: CGFloat = 20
    private let maxPreviewHeight: CGFloat = 320

    var body: some View {
        let layout = makeLayout(availableWidth: availableWidth)

        HStack(alignment: .top, spacing: spacing) {
            ForEach(layout.columns.indices, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(layout.columns[columnIndex]) { item in
                        PreviewSpecCard(
                            session: session,
                            item: item,
                            previewSize: previewSize(for: item.dimension, scale: layout.scale)
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                .frame(width: layout.columnWidth)
            }
        }
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
        let columnCount = max(1, min(4, Int((availableWidth + spacing) / 260)))
        let columnWidth = floor((availableWidth - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount))
        let previewWidth = max(1, columnWidth - cardPadding)
        let scale = previewScale(previewWidth: previewWidth)
        var columns = Array(repeating: [OodiPopPreviewItem](), count: columnCount)
        var heights = Array(repeating: CGFloat.zero, count: columnCount)

        for item in session.previewItems {
            let previewSize = previewSize(for: item.dimension, scale: scale)
            let cardHeight = previewSize.height + cardChromeHeight
            let targetColumn = heights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columns[targetColumn].append(item)
            heights[targetColumn] += cardHeight + spacing
        }

        let height = max(1, (heights.max() ?? 1) - spacing)
        return WaterfallLayout(columns: columns, columnWidth: columnWidth, scale: scale, height: height)
    }

    private func previewScale(previewWidth: CGFloat) -> CGFloat {
        guard let widest = session.previewItems.map({ CGFloat($0.dimension.width) }).max(),
              let tallest = session.previewItems.map({ CGFloat($0.dimension.height) }).max(),
              widest > 0,
              tallest > 0 else {
            return 1
        }

        return min(previewWidth / widest, maxPreviewHeight / tallest)
    }

    private func previewSize(for dimension: OodiPopDimension, scale: CGFloat) -> CGSize {
        CGSize(
            width: max(1, CGFloat(dimension.width) * scale),
            height: max(1, CGFloat(dimension.height) * scale)
        )
    }
}

private struct WaterfallLayout {
    let columns: [[OodiPopPreviewItem]]
    let columnWidth: CGFloat
    let scale: CGFloat
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
    let previewSize: CGSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                PreviewMediaView(fileURL: session.fileURL, mediaKind: session.mediaKind)
                    .frame(width: previewSize.width, height: previewSize.height)
                    .background(Color.black.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )

                HStack(spacing: 6) {
                    Text(item.dimension.label)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
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
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(session.exportingItemID != nil)
                    .padding(6)
                    .background(.regularMaterial)
                    .clipShape(Circle())
                    .help("Export \(item.dimension.label)")
                }
                .padding(8)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.spec.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if let format = item.spec.format, !format.isEmpty {
                    Text(format)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        ZStack {
            Color.gray.opacity(0.1)
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
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

            Image(systemName: "play.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(radius: 4)
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
