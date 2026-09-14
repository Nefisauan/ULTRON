import XCTest
@testable import UltronCore

@MainActor
private final class TestPermissions: PermissionService {
    var screenRecordingStatus: PermissionStatus = .notGranted
    var requestedStatus: PermissionStatus = .notGranted
    var requests = 0
    func requestScreenRecording() -> PermissionStatus {
        requests += 1
        screenRecordingStatus = requestedStatus
        return screenRecordingStatus
    }
}

@MainActor
private final class TestCapturer: ScreenCapturer {
    var targets: [ScreenCaptureTarget] = []
    var failure: CommandError?
    func capture(_ target: ScreenCaptureTarget) async throws -> ScreenContext {
        targets.append(target)
        if let failure { throw failure }
        return try ScreenContext(imageData: Data([1]), metadata: .init(application: "Safari", width: 100, height: 100))
    }
}

private actor TestAnalyzer: VisionAnalyzer {
    private(set) var calls = 0
    func analyze(_ context: ScreenContext) async throws -> VisionAnalysis {
        calls += 1
        return .init(summary: "Mock response", isMock: true)
    }
}

final class VisionTests: XCTestCase {
    func testScreenContextRejectsEmptyFrames() throws {
        XCTAssertThrowsError(try ScreenContext(imageData: Data(), metadata: .init(width: 100, height: 100)))
        XCTAssertThrowsError(try ScreenContext(imageData: Data([1]), metadata: .init(width: 0, height: 100)))
        let metadata = ScreenContext.Metadata(displayIdentifier: 7, application: "Safari", windowTitle: "Example", width: 640, height: 480)
        XCTAssertEqual(try ScreenContext(imageData: Data([1]), metadata: metadata).metadata, metadata)
    }

    func testMockDoesNotClaimToUnderstandImage() async throws {
        let frame = try ScreenContext(imageData: Data([1]), metadata: .init(width: 1, height: 1))
        let result = try await MockVisionAnalyzer().analyze(frame)
        XCTAssertTrue(result.isMock)
        XCTAssertTrue(result.summary.contains("no live vision provider"))
        XCTAssertTrue(result.summary.contains("not analyzed"))
    }

    @MainActor
    func testDeniedPermissionNeverCapturesOrAnalyzes() async throws {
        let permissions = TestPermissions()
        let capture = TestCapturer()
        let analyzer = TestAnalyzer()
        let tool = CaptureScreenTool(permissions: permissions, capturer: capture, analyzer: analyzer)
        do {
            _ = try await tool.execute(.captureScreen, context: .init(dashboard: .init()))
            XCTFail("Permission denial was ignored")
        } catch { XCTAssertEqual(error as? CommandError, .screenPermissionRequired) }
        XCTAssertEqual(permissions.requests, 1)
        XCTAssertTrue(capture.targets.isEmpty)
        let calls = await analyzer.calls
        XCTAssertEqual(calls, 0)
    }

    @MainActor
    func testGrantedPermissionCapturesOnceAndReportsThinking() async throws {
        let permissions = TestPermissions()
        permissions.screenRecordingStatus = .granted
        let capture = TestCapturer()
        let analyzer = TestAnalyzer()
        let tool = CaptureScreenTool(permissions: permissions, capturer: capture, analyzer: analyzer)
        var progress: UltronState?
        let result = try await tool.execute(.captureDashboard, context: .init(dashboard: .init()) { progress = $0.state })
        XCTAssertEqual(permissions.requests, 0)
        XCTAssertEqual(capture.targets.count, 1)
        if case .safariWindow = capture.targets[0] {} else { XCTFail("Wrong capture scope") }
        XCTAssertEqual(progress, .thinking)
        XCTAssertEqual(result.message, "Mock response")
        let calls = await analyzer.calls
        XCTAssertEqual(calls, 1)
    }

    @MainActor
    func testFailedCaptureDoesNotAnalyze() async throws {
        let permissions = TestPermissions()
        permissions.requestedStatus = .granted
        let capture = TestCapturer()
        capture.failure = .captureFailed
        let analyzer = TestAnalyzer()
        let tool = CaptureScreenTool(permissions: permissions, capturer: capture, analyzer: analyzer)
        do {
            _ = try await tool.execute(.captureScreen, context: .init(dashboard: .init()))
            XCTFail("Capture failure ignored")
        } catch { XCTAssertEqual(error as? CommandError, .captureFailed) }
        let calls = await analyzer.calls
        XCTAssertEqual(calls, 0)
    }

    @MainActor
    func testCancelledRequestNeverAsksPermission() async {
        let permissions = TestPermissions()
        let capture = TestCapturer()
        let tool = CaptureScreenTool(permissions: permissions, capturer: capture, analyzer: MockVisionAnalyzer())
        let task = Task {
            do {
                _ = try await tool.execute(.captureScreen, context: .init(dashboard: .init()))
                XCTFail("Cancelled request executed")
            } catch { XCTAssertTrue(error is CancellationError) }
        }
        task.cancel()
        await task.value
        XCTAssertEqual(permissions.requests, 0)
        XCTAssertTrue(capture.targets.isEmpty)
    }

    func testDashboardAnalysisIsAnExplicitIntent() throws {
        XCTAssertEqual(try CommandParser().parse("Analyze my dashboard"), .analyzeDashboard)
        XCTAssertEqual(try CommandParser().parse("Analyze TradeScale"), .analyzeDashboard)
        XCTAssertEqual(try CommandParser().parse("Analyze this"), .analyzeDashboard)
        XCTAssertEqual(try CommandParser().parse("Open TradeScale"), .openDashboard)
    }
}
