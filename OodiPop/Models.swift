import Foundation

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
