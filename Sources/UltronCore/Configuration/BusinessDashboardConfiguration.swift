import Foundation

public struct BusinessDashboardConfiguration: Equatable, Sendable {
    public let url: URL?

    public init() { url = nil }

    public init(urlString: String) throws {
        let value = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        url = value.isEmpty ? nil : try Self.validate(value)
    }

    public static func validate(_ text: String) throws -> URL {
        guard !text.contains(where: { $0.isWhitespace || $0.isNewline }),
              let parts = URLComponents(string: text),
              let scheme = parts.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil,
              let url = parts.url else { throw CommandError.invalidURL }
        return url
    }
}
