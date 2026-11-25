import Foundation

/// Loads the bundled word catalog.
enum Catalog {
    enum LoadError: LocalizedError {
        case missingFile
        case empty

        var errorDescription: String? {
            switch self {
            case .missingFile: String(localized: "The word list is missing from the app.")
            case .empty: String(localized: "The word list is empty.")
            }
        }
    }

    private struct File: Decodable {
        let version: Int
        let categories: [Category]
    }

    static func load(from bundle: Bundle = .main) throws -> [Category] {
        guard let url = bundle.url(forResource: "catalog", withExtension: "json") else {
            throw LoadError.missingFile
        }
        let file = try JSONDecoder().decode(File.self, from: Data(contentsOf: url))
        guard !file.categories.isEmpty else { throw LoadError.empty }
        return file.categories
    }
}
