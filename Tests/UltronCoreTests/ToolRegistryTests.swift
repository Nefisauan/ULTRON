import XCTest
@testable import UltronCore

@MainActor
final class RecordingSystemController: ApplicationController, ResourceOpener {
    var applications: [String] = []
    var urls: [URL] = []
    var files: [URL] = []
    var failure: CommandError?
    func openApplication(named name: String) async throws {
        if let failure { throw failure }
        applications.append(name)
    }
    func openURL(_ url: URL) async throws { urls.append(url) }
    func openFile(_ url: URL) async throws { files.append(url) }
}

@MainActor
private final class RiskyTool: UltronTool {
    let descriptor: UltronToolDescriptor
    var executions = 0
    init(risk: UltronActionRisk) {
        descriptor = .init(identifier: "open-application", description: "Test tool", inputRequirements: "Application", risk: risk)
    }
    func execute(_ intent: UltronIntent, context: UltronToolContext) async throws -> UltronToolResult {
        executions += 1
        return .init(message: "Should not run")
    }
}

final class ToolRegistryTests: XCTestCase {
    @MainActor
    func testRoutingAndDuplicateRegistration() async throws {
        let system = RecordingSystemController()
        let registry = UltronToolRegistry()
        let app = OpenApplicationTool(controller: system)
        try registry.register(app)
        try registry.register(OpenURLTool(opener: system))
        try registry.register(OpenFileTool(opener: system))
        try registry.register(ShowDashboardModuleTool())
        XCTAssertThrowsError(try registry.register(app))
        let context = UltronToolContext(dashboard: try .init(urlString: "https://example.com/dashboard"))
        _ = try await registry.execute(.openApplication("Safari"), context: context)
        _ = try await registry.execute(.openDashboard, context: context)
        _ = try await registry.execute(.openFile(URL(fileURLWithPath: "/tmp/notes.txt")), context: context)
        let shown = try await registry.execute(.showModule(.markets), context: context)
        XCTAssertEqual(system.applications, ["Safari"])
        XCTAssertEqual(system.urls, [URL(string: "https://example.com/dashboard")!])
        XCTAssertEqual(system.files.count, 1)
        XCTAssertEqual(shown.selectedModule, .markets)
        XCTAssertEqual(registry.descriptors.count, 4)
    }

    @MainActor
    func testRiskGatePreventsExecution() async throws {
        for risk in [UltronActionRisk.requiresConfirmation, .sensitive, .prohibited] {
            let registry = UltronToolRegistry()
            let tool = RiskyTool(risk: risk)
            try registry.register(tool)
            do {
                _ = try await registry.execute(.openApplication("Safari"), context: .init(dashboard: .init()))
                XCTFail("Unsafe tool ran")
            } catch { XCTAssertEqual(error as? CommandError, .riskNotAllowed) }
            XCTAssertEqual(tool.executions, 0)
        }
        XCTAssertTrue(UltronActionRisk.readOnly.allowedInPhaseOne)
        XCTAssertTrue(UltronActionRisk.lowRisk.allowedInPhaseOne)
    }

    @MainActor
    func testMissingConfigurationAndDirectURLValidation() async throws {
        let system = RecordingSystemController()
        let tool = OpenURLTool(opener: system)
        let context = UltronToolContext(dashboard: .init())
        for intent in [UltronIntent.openDashboard, .openURL(URL(string: "file:///tmp/test")!)] {
            do { _ = try await tool.execute(intent, context: context); XCTFail("Invalid URL accepted") }
            catch { XCTAssertTrue(error is CommandError) }
        }
        XCTAssertTrue(system.urls.isEmpty)
        do {
            _ = try await UltronToolRegistry().execute(.captureScreen, context: context)
            XCTFail("Unregistered tool ran")
        } catch { XCTAssertEqual(error as? CommandError, .toolUnavailable("capture-screen")) }
    }
}
