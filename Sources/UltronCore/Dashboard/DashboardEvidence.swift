import Foundation

/// Generated observations must be actual source excerpts, not model-authored metric claims.
public enum DashboardEvidence {
    public static func verified(_ candidates: [String], in source: String) -> [String] {
        func normalized(_ text: String) -> String { text.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
        let source = normalized(source)
        var accepted: [String] = []
        for candidate in candidates {
            let quote = normalized(candidate)
            guard (3...240).contains(quote.count), quote.contains(where: \.isNumber),
                  quote.contains(where: \.isLetter), source.contains(quote), !accepted.contains(quote) else { continue }
            accepted.append(quote)
            if accepted.count == 3 { break }
        }
        return accepted
    }
}
