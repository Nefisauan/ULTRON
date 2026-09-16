import XCTest
@testable import UltronCore

final class SafariFavoritesTests: XCTestCase {
    private func leaf(_ title: String, _ url: String) -> [String: Any] {
        ["URIDictionary": ["title": title], "URLString": url]
    }
    private func data(_ favorites: [[String: Any]]) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: ["Children": [
            ["Title": "BookmarksBar", "Children": favorites],
            ["Title": "BookmarksMenu", "Children": [leaf("Private", "https://example.org")]]
        ]], format: .binary, options: 0)
    }
    func testExactCaseInsensitiveNestedFavoriteAndScope() throws {
        let fixture = try data([["Title": "Work", "Children": [leaf("Reports", "https://example.com/reports")]]])
        XCTAssertEqual(try SafariFavorites.resolve("reports", in: fixture).absoluteString, "https://example.com/reports")
        XCTAssertThrowsError(try SafariFavorites.resolve("Report", in: fixture))
        XCTAssertThrowsError(try SafariFavorites.resolve("Private", in: fixture))
        XCTAssertEqual(try CommandParser().parse("Open Favorite Reports"), .openFavorite("Reports"))
    }
    func testAmbiguousAndUnsafeFavoritesRejected() throws {
        XCTAssertThrowsError(try SafariFavorites.resolve("Reports", in: data([
            leaf("Reports", "https://example.com"), leaf("Reports", "https://example.org")
        ])))
        for url in ["javascript:alert(1)", "file:///tmp/test", "https://user:password@example.com"] {
            XCTAssertThrowsError(try SafariFavorites.resolve("Reports", in: data([leaf("Reports", url)])))
        }
    }
    func testDuplicateURLIsUnambiguousAndMalformedDataRejected() throws {
        let item = leaf("Reports", "https://example.com")
        XCTAssertEqual(try SafariFavorites.resolve("Reports", in: data([item, item])).host, "example.com")
        XCTAssertThrowsError(try SafariFavorites.resolve("Reports", in: Data()))
        XCTAssertThrowsError(try SafariFavorites.resolve("Reports", in: Data(repeating: 0, count: 4_000_001)))
    }
}
