import Foundation

/// Reads Safari's bookmark export structure without retaining browsing data.
public enum SafariFavorites {
    public static func resolve(_ name: String, in data: Data) throws -> URL {
        guard data.count <= 4_000_000,
              let root = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let children = root["Children"] as? [[String: Any]] else { throw CommandError.favoritesUnavailable }
        let folders = children.filter { ($0["Title"] as? String) == "BookmarksBar" }
        var matches = Set<URL>()
        var visited = 0
        func walk(_ nodes: [[String: Any]], depth: Int) throws {
            guard depth < 20 else { throw CommandError.favoritesUnavailable }
            for node in nodes {
                visited += 1
                guard visited <= 10_000 else { throw CommandError.favoritesUnavailable }
                if let uri = node["URIDictionary"] as? [String: Any],
                   let title = uri["title"] as? String,
                   title.caseInsensitiveCompare(name) == .orderedSame,
                   let raw = node["URLString"] as? String {
                    matches.insert(try BusinessDashboardConfiguration.validate(raw))
                }
                if let nested = node["Children"] as? [[String: Any]] { try walk(nested, depth: depth + 1) }
            }
        }
        try walk(folders, depth: 0)
        guard matches.count <= 1 else { throw CommandError.ambiguousFavorite }
        guard let url = matches.first else { throw CommandError.favoriteNotFound }
        return url
    }
}

@MainActor
public protocol FavoriteOpener {
    func openFavorite(named name: String) async throws
}

@MainActor
public struct OpenFavoriteTool: UltronTool {
    public let descriptor = UltronToolDescriptor(identifier: "open-favorite", description: "Open an exact Safari favorite by name.", inputRequirements: "Favorite title", risk: .lowRisk)
    private let opener: any FavoriteOpener
    public init(opener: any FavoriteOpener) { self.opener = opener }
    public func execute(_ intent: UltronIntent, context: UltronToolContext) async throws -> UltronToolResult {
        guard case .openFavorite(let name) = intent else { throw CommandError.invalidInput }
        try await opener.openFavorite(named: name)
        return .init(message: "Opening your Safari favorite now.")
    }
}
