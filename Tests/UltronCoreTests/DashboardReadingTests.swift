import XCTest
@testable import UltronCore

@MainActor
private final class FixturePageReader: DashboardPageReader {
    var calls = 0
    var failure: CommandError?
    var pageURL = URL(string: "https://example.com/dashboard")!
    func read(configuredURL: URL) async throws -> DashboardPage {
        calls += 1
        if let failure { throw failure }
        return try DashboardPage(title: "Pipeline", url: pageURL, text: "Leads\n128\nMeetings\n12")
    }
}

@MainActor
private final class FixturePageAnalyzer: DashboardTextAnalyzer {
    var calls = 0
    func analyze(_ page: DashboardPage) async throws -> DashboardTextAnalysis {
        calls += 1
        return .init(message: "Observed 128 leads and 12 meetings in the excerpt.")
    }
}

final class DashboardReadingTests: XCTestCase {
    func testSameOriginAndSanitizedURLs() throws {
        let configured = URL(string: "https://example.com")!
        try DashboardPageScope.validate(URL(string: "https://EXAMPLE.com:443/reports?a=b")!, against: configured)
        for value in ["http://example.com", "https://example.com:444", "https://example.com.evil.test", "https://other.example.com"] {
            XCTAssertThrowsError(try DashboardPageScope.validate(URL(string: value)!, against: configured))
        }
        let page = try DashboardPage(title: "Example", url: URL(string: "https://example.com/reports?private=value#section")!, text: "Revenue 12")
        XCTAssertEqual(page.url.absoluteString, "https://example.com/reports")
        XCTAssertFalse(page.chatGPTPrompt.contains("private=value"))
    }

    func testDecodeRejectsOversizedEmptyAndWrongOriginData() throws {
        let expected = URL(string: "https://example.com")!
        let valid = Data(#"{"url":"https://example.com","text":"Leads 128","tables":[[["Leads","128"]]]}"#.utf8)
        XCTAssertEqual(try SafariPageExtraction.decode(valid, configuredURL: expected).text, "Leads 128")
        for value in [#"{"url":"https://evil.test","text":"secret"}"#, #"{"url":"https://example.com","text":" "}"#, "not JSON"] {
            XCTAssertThrowsError(try SafariPageExtraction.decode(Data(value.utf8), configuredURL: expected))
        }
        XCTAssertThrowsError(try SafariPageExtraction.decode(Data(repeating: 32, count: 256_001), configuredURL: expected))
    }

    func testSafariPermissionAndTimeoutErrorsAreActionable() {
        let expected = URL(string: "https://example.com")!
        for (payload, error) in [(#"{"errorNumber":-1743}"#, CommandError.safariAutomationRequired),
                                  (#"{"errorNumber":-1712}"#, .safariReadTimedOut),
                                  (#"{"errorNumber":-10000}"#, .safariJavaScriptRequired)] {
            XCTAssertThrowsError(try SafariPageExtraction.decode(Data(payload.utf8), configuredURL: expected)) {
                XCTAssertEqual($0 as? CommandError, error)
            }
        }
    }

    @MainActor
    func testReadAndAnalyzeWithoutAnyCaptureService() async throws {
        let reader = FixturePageReader()
        let analyzer = FixturePageAnalyzer()
        let registry = UltronToolRegistry()
        try registry.register(ReadDashboardTool(reader: reader, analyzer: analyzer))
        var stage: UltronState?
        let result = try await registry.execute(.analyzeDashboard, context: .init(dashboard: try .init(urlString: "https://example.com")) { stage = $0.state })
        XCTAssertEqual(reader.calls, 1)
        XCTAssertEqual(analyzer.calls, 1)
        XCTAssertEqual(stage, .thinking)
        XCTAssertEqual(result.pageSnapshot?.text, "Leads\n128\nMeetings\n12")
        XCTAssertEqual(try CommandParser().parse("What are we seeing?"), .analyzeDashboard)
        XCTAssertEqual(try CommandParser().parse("Capture dashboard"), .captureDashboard)
        XCTAssertEqual(UltronIntent.analyzeDashboard.toolIdentifier, "read-dashboard")
    }

    @MainActor
    func testMissingConfigurationAndWrongPageNeverReachAnalyzer() async throws {
        let reader = FixturePageReader()
        let analyzer = FixturePageAnalyzer()
        let tool = ReadDashboardTool(reader: reader, analyzer: analyzer)
        do { _ = try await tool.execute(.analyzeDashboard, context: .init(dashboard: .init())); XCTFail() }
        catch { XCTAssertEqual(error as? CommandError, .dashboardNotConfigured) }
        XCTAssertEqual(reader.calls, 0)
        reader.pageURL = URL(string: "https://other.test")!
        do { _ = try await tool.execute(.analyzeDashboard, context: .init(dashboard: try .init(urlString: "https://example.com"))); XCTFail() }
        catch { XCTAssertEqual(error as? CommandError, .wrongSafariPage) }
        XCTAssertEqual(analyzer.calls, 0)
    }

    @MainActor
    func testCancelledReadDoesNotStartBrowserWork() async throws {
        let reader = FixturePageReader()
        let tool = ReadDashboardTool(reader: reader, analyzer: FixturePageAnalyzer())
        let context = UltronToolContext(dashboard: try .init(urlString: "https://example.com"))
        let task = Task {
            do { _ = try await tool.execute(.analyzeDashboard, context: context); XCTFail() }
            catch { XCTAssertTrue(error is CancellationError) }
        }
        task.cancel()
        await task.value
        XCTAssertEqual(reader.calls, 0)
    }
}
