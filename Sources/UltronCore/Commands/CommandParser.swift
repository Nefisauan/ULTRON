import Foundation

/// Deterministic, anchored commands. No substring guessing, shell evaluation, or model-selected actions.
public struct CommandParser: Sendable {
    private static let exact: [String: UltronIntent] = [
        "hey ultron": .greet, "hello": .greet, "hi": .greet,
        "open tradescale": .openDashboard, "open dashboard": .openDashboard,
        "open my dashboard": .openDashboard, "open my business dashboard": .openDashboard,
        "show business": .showModule(.business), "show markets": .showModule(.markets),
        "show projects": .showModule(.projects), "show today": .showModule(.today),
        "look at my screen": .captureScreen, "look at this": .captureScreen,
        "what are we seeing": .analyzeDashboard, "analyze this": .analyzeDashboard,
        "read my dashboard": .analyzeDashboard, "read dashboard": .analyzeDashboard,
        "capture dashboard": .captureDashboard, "screenshot dashboard": .captureDashboard,
        "analyze dashboard": .analyzeDashboard, "analyze my dashboard": .analyzeDashboard,
        "analyze my business dashboard": .analyzeDashboard, "analyze tradescale": .analyzeDashboard
    ]

    public init() {}

    public func parse(_ text: String) throws -> UltronIntent {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CommandError.empty }
        let normalized = trimmed.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let key = normalized.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".?!"))
        if let intent = Self.exact[key] { return intent }
        for prefix in ["analyze ", "read page "] where normalized.lowercased().hasPrefix(prefix) {
            let target = String(normalized.dropFirst(prefix.count))
            return .analyzePage(try BusinessDashboardConfiguration.validate(target))
        }
        // Preserve spaces and case within user paths and URLs.
        if trimmed.lowercased().hasPrefix("open file ") {
            let path = String(trimmed.dropFirst(10)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard path.hasPrefix("/"), !path.contains("\0") else { throw CommandError.invalidFilePath }
            return .openFile(URL(fileURLWithPath: path))
        }
        if normalized.lowercased().hasPrefix("open ") {
            let target = String(normalized.dropFirst(5))
            if target.contains(":") { return .openURL(try BusinessDashboardConfiguration.validate(target)) }
            guard !target.contains("/"), !target.contains("\\"), !target.contains(";") else {
                throw CommandError.unsupported
            }
            return .openApplication(target.trimmingCharacters(in: CharacterSet(charactersIn: ".?!")))
        }
        throw CommandError.unsupported
    }
}
