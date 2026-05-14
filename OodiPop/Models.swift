import Foundation
import Combine
import UniformTypeIdentifiers

struct OodiPopCatalog: Codable {
    let updatedAt: String
    let platforms: [OodiPopPlatform]
}

struct OodiPopPlatform: Codable, Identifiable {
    var id: String { platform }
    var iconResourceName: String {
        switch platform {
        case "Instagram":
            "oodipop-icon-instagram"
        case "Facebook":
            "oodipop-icon-facebook"
        case "X (Twitter)":
            "oodipop-icon-x"
        case "LinkedIn":
            "oodipop-icon-linkedin"
        case "Threads":
            "oodipop-icon-threads"
        case "Pinterest":
            "oodipop-icon-pinterest"
        case "YouTube":
            "oodipop-icon-youtube"
        case "TikTok":
            "oodipop-icon-tiktok"
        case "Twitch":
            "oodipop-icon-twitch"
        case "Snapchat":
            "oodipop-icon-snapchat"
        case "Google Ads":
            "oodipop-icon-google-ads"
        case "Etsy":
            "oodipop-icon-etsy"
        case "Reddit":
            "oodipop-icon-reddit"
        case "Spotify":
            "oodipop-icon-spotify"
        case "Bluesky":
            "oodipop-icon-bluesky"
        case "Discord":
            "oodipop-icon-discord"
        case "Mastodon":
            "oodipop-icon-mastodon"
        default:
            "oodipop-icon-generic"
        }
    }

    let platform: String
    let description: String
    let items: [OodiPopSpec]
}

struct OodiPopSpec: Codable, Identifiable {
    var id: String {
        [
            title,
            dimensions,
            aspectRatio,
            format,
            fileType,
            fileSize,
            notes
        ]
        .compactMap { $0 }
        .joined(separator: "-")
    }

    let title: String
    let dimensions: String?
    let aspectRatio: String?
    let format: String?
    let fileType: String?
    let fileSize: String?
    let settings: String?
    let notes: String?
    let actions: [String]?
}

enum OodiPopMediaKind {
    case image
    case video

    init?(fileURL: URL) {
        guard let type = UTType(filenameExtension: fileURL.pathExtension) else {
            return nil
        }

        if type.conforms(to: .image) {
            self = .image
        } else if type.conforms(to: .movie) || type.conforms(to: .video) || type.conforms(to: .audiovisualContent) {
            self = .video
        } else {
            return nil
        }
    }
}

struct OodiPopDimension: Hashable {
    let width: Int
    let height: Int

    var label: String {
        "\(width)x\(height)"
    }

    init?(rawValue: String?) {
        guard let rawValue else { return nil }

        let normalized = rawValue
            .replacingOccurrences(of: "×", with: "x")
            .replacingOccurrences(of: "X", with: "x")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = normalized.split(separator: "x")
        guard parts.count == 2,
              let width = Int(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
              let height = Int(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)),
              width > 0,
              height > 0 else {
            return nil
        }

        self.width = width
        self.height = height
    }
}

struct OodiPopPreviewItem: Identifiable {
    let spec: OodiPopSpec
    let dimension: OodiPopDimension

    var id: String {
        "\(spec.id)-\(dimension.label)"
    }
}

final class OodiPopPreviewSession: ObservableObject {
    let fileURL: URL
    let mediaKind: OodiPopMediaKind
    let catalog: OodiPopCatalog

    @Published var selectedPlatform: OodiPopPlatform
    @Published var exportingItemID: String?
    @Published var errorMessage: String?

    init(fileURL: URL, mediaKind: OodiPopMediaKind, catalog: OodiPopCatalog) {
        self.fileURL = fileURL
        self.mediaKind = mediaKind
        self.catalog = catalog
        self.selectedPlatform = catalog.platforms.first { platform in
            !Self.previewItems(for: platform, mediaKind: mediaKind).isEmpty
        } ?? catalog.platforms[0]
    }

    var previewItems: [OodiPopPreviewItem] {
        Self.previewItems(for: selectedPlatform, mediaKind: mediaKind)
    }

    private static func previewItems(for platform: OodiPopPlatform, mediaKind: OodiPopMediaKind) -> [OodiPopPreviewItem] {
        platform.items.compactMap { spec in
            guard spec.matches(mediaKind),
                  let dimension = OodiPopDimension(rawValue: spec.dimensions) else {
                return nil
            }

            return OodiPopPreviewItem(spec: spec, dimension: dimension)
        }
    }
}

private extension OodiPopSpec {
    func matches(_ mediaKind: OodiPopMediaKind) -> Bool {
        let normalized = format?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch mediaKind {
        case .image:
            return normalized == nil || normalized == "" || normalized == "image"
        case .video:
            return normalized == nil || normalized == "" || normalized == "video"
        }
    }
}
