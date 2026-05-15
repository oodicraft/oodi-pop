import AppKit
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins

enum MediaPreviewExportError: LocalizedError {
    case cannotLoadImage
    case cannotCreateBitmap
    case cannotCreateVideoExport
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .cannotLoadImage:
            "Could not load the source image."
        case .cannotCreateBitmap:
            "Could not render the resized image."
        case .cannotCreateVideoExport:
            "Could not create a video export session."
        case .exportFailed:
            "The video export failed."
        }
    }
}

enum MediaPreviewExportService {
    static func exportImage(sourceURL: URL, dimension: OodiPopDimension, destinationURL: URL) throws {
        guard let sourceImage = NSImage(contentsOf: sourceURL),
              let cgImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw MediaPreviewExportError.cannotLoadImage
        }

        let targetSize = CGSize(width: dimension.width, height: dimension.height)
        guard let context = CGContext(
            data: nil,
            width: dimension.width,
            height: dimension.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw MediaPreviewExportError.cannotCreateBitmap
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: aspectFillRect(sourceSize: CGSize(width: cgImage.width, height: cgImage.height), targetSize: targetSize))

        guard let renderedImage = context.makeImage() else {
            throw MediaPreviewExportError.cannotCreateBitmap
        }

        let bitmap = NSBitmapImageRep(cgImage: renderedImage)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw MediaPreviewExportError.cannotCreateBitmap
        }

        try data.write(to: destinationURL, options: .atomic)
    }

    static func exportVideo(sourceURL: URL, dimension: OodiPopDimension, destinationURL: URL) async throws {
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        let asset = AVURLAsset(url: sourceURL)
        let targetSize = CGSize(width: dimension.width, height: dimension.height)
        let composition = try await makeVideoComposition(asset: asset, targetSize: targetSize)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw MediaPreviewExportError.cannotCreateVideoExport
        }

        exportSession.videoComposition = composition
        exportSession.shouldOptimizeForNetworkUse = true

        try await exportSession.export(to: destinationURL, as: .mp4)
    }

    private static func makeVideoComposition(asset: AVAsset, targetSize: CGSize) async throws -> AVMutableVideoComposition {
        let composition = try await withCheckedThrowingContinuation { continuation in
            AVMutableVideoComposition.videoComposition(with: asset) { request in
                applyAspectFill(to: request, targetSize: targetSize)
            } completionHandler: { composition, error in
                if let composition {
                    continuation.resume(returning: composition)
                } else {
                    continuation.resume(throwing: error ?? MediaPreviewExportError.cannotCreateVideoExport)
                }
            }
        }

        composition.renderSize = targetSize
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        return composition
    }

    private static func applyAspectFill(to request: AVAsynchronousCIImageFilteringRequest, targetSize: CGSize) {
        let sourceImage = request.sourceImage
        let sourceExtent = sourceImage.extent
        let fillRect = aspectFillRect(sourceSize: sourceExtent.size, targetSize: targetSize)
        let scale = fillRect.width / sourceExtent.width
        let transform = CGAffineTransform(translationX: fillRect.minX, y: fillRect.minY).scaledBy(x: scale, y: scale)
        let output = sourceImage
            .transformed(by: transform)
            .cropped(to: CGRect(origin: .zero, size: targetSize))

        request.finish(with: output, context: nil)
    }

    private static func aspectFillRect(sourceSize: CGSize, targetSize: CGSize) -> CGRect {
        let scale = max(targetSize.width / sourceSize.width, targetSize.height / sourceSize.height)
        let width = sourceSize.width * scale
        let height = sourceSize.height * scale
        return CGRect(
            x: (targetSize.width - width) / 2,
            y: (targetSize.height - height) / 2,
            width: width,
            height: height
        )
    }
}
