import XCTest
@testable import UltronCore

final class CommandParserTests: XCTestCase {
    private let parser = CommandParser()

    func testExactCommandsAndNormalization() throws {
        XCTAssertEqual(try parser.parse("  HEY   ULTRON.\n"), .greet)
        XCTAssertEqual(try parser.parse("Show Markets"), .showModule(.markets))
        XCTAssertEqual(try parser.parse("show business"), .showModule(.business))
        XCTAssertEqual(try parser.parse("Open TradeScale"), .openDashboard)
        XCTAssertEqual(try parser.parse("Open Xcode"), .openApplication("Xcode"))
        XCTAssertEqual(try parser.parse("What are we seeing?"), .analyzeDashboard)
    }

    func testPathsAndURLsPreserveCaseAndContent() throws {
        XCTAssertEqual(try parser.parse("Analyze https://example.com/Reports"),
                       .analyzePage(URL(string: "https://example.com/Reports")!))
        XCTAssertThrowsError(try parser.parse("Analyze file:///etc/passwd"))
        XCTAssertEqual(try parser.parse("Open Slack"), .openApplication("Slack"))
        XCTAssertEqual(try parser.parse("Open Notes."), .openApplication("Notes"))
        XCTAssertEqual(try parser.parse("Open https://example.com/Account?tab=Leads"),
                       .openURL(URL(string: "https://example.com/Account?tab=Leads")!))
        XCTAssertEqual(try parser.parse("Open File /tmp/My  Notes.txt"),
                       .openFile(URL(fileURLWithPath: "/tmp/My  Notes.txt")))
    }

    func testRejectsUnsupportedAndAmbiguousCommands() {
        for text in ["", "please maybe open safari", "delete files", "open Safari; rm -rf /", "open file relative.txt"] {
            XCTAssertThrowsError(try parser.parse(text), text)
        }
    }

    func testURLValidationAtConfigurationBoundary() throws {
        XCTAssertNil(BusinessDashboardConfiguration().url)
        XCTAssertNil(try BusinessDashboardConfiguration(urlString: " \n").url)
        XCTAssertEqual(try BusinessDashboardConfiguration(urlString: " https://example.com/dashboard ").url?.host, "example.com")
        for value in ["javascript:alert(1)", "file:///tmp/test", "https://user:password@example.com", "https:///", "https://example.com/a b", "example.com", "mailto:a@example.com"] {
            XCTAssertThrowsError(try BusinessDashboardConfiguration(urlString: value), value)
        }
    }

    func testFileOpeningPolicyRejectsExecutablesPackagesAndSpecialFiles() {
        XCTAssertTrue(FileOpeningPolicy.allows(pathExtension: "PDF", isDirectory: false, isPackage: false, isExecutable: false, isRegularFile: true))
        XCTAssertTrue(FileOpeningPolicy.allows(pathExtension: "", isDirectory: true, isPackage: false, isExecutable: true, isRegularFile: false))
        XCTAssertFalse(FileOpeningPolicy.allows(pathExtension: "app", isDirectory: true, isPackage: true, isExecutable: true, isRegularFile: false))
        XCTAssertFalse(FileOpeningPolicy.allows(pathExtension: "txt", isDirectory: false, isPackage: false, isExecutable: true, isRegularFile: true))
        XCTAssertFalse(FileOpeningPolicy.allows(pathExtension: "txt", isDirectory: false, isPackage: false, isExecutable: false, isRegularFile: false))
        XCTAssertFalse(FileOpeningPolicy.allows(pathExtension: "command", isDirectory: false, isPackage: false, isExecutable: false, isRegularFile: true))
    }

    func testDashboardProviderIsExplicitlySampleData() async throws {
        let modules = try await MockDashboardProvider().modules()
        XCTAssertEqual(Set(modules.map(\.id)), Set(DashboardModuleID.allCases))
        XCTAssertTrue(modules.allSatisfy { $0.isSample && !$0.metrics.isEmpty })
    }
}
