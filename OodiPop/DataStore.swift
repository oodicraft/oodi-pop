import Foundation
import Combine

final class OodiPopStore: ObservableObject {
    @Published var catalog: OodiPopCatalog?
    @Published var selectedPlatform: OodiPopPlatform?
    @Published var searchText: String = ""

    init() {
        load()
    }

    func load() {
        guard let url = Bundle.main.url(forResource: "oodipop-catalog", withExtension: "json") else {
            print("oodipop-catalog.json not found")
            return
        }

        do {
            let jsonData = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(OodiPopCatalog.self, from: jsonData)

            DispatchQueue.main.async {
                self.catalog = decoded
                self.selectedPlatform = decoded.platforms.first
            }
        } catch {
            print("Failed to decode JSON:", error)
        }
    }

    var filteredItems: [OodiPopSpec] {
        guard let selectedPlatform else { return [] }

        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !keyword.isEmpty else {
            return selectedPlatform.items
        }

        return selectedPlatform.items.filter { item in
            [
                item.title,
                item.dimensions,
                item.aspectRatio,
                item.format,
                item.fileType,
                item.fileSize,
                item.settings,
                item.notes
            ]
            .compactMap { $0 }
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(keyword)
        }
    }
}
