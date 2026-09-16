import XCTest
@testable import UltronCore

final class WakeFollowupWindowTests: XCTestCase {
    func testGreetingAndPermissionDelayDoNotConsumeListeningWindow() {
        var window = WakeFollowupWindow()
        let start = Date(timeIntervalSince1970: 100)
        window.arm()
        XCTAssertFalse(window.acceptsCommand(at: start))
        let ready = start.addingTimeInterval(30)
        XCTAssertFalse(window.acceptsCommand(at: ready))
        window.microphoneReady(at: ready)
        XCTAssertTrue(window.acceptsCommand(at: ready.addingTimeInterval(11.9)))
        XCTAssertFalse(window.acceptsCommand(at: ready.addingTimeInterval(12)))
    }
    func testPollingDoesNotExtendDeadlineAndClearRevokesWindow() {
        var window = WakeFollowupWindow()
        let now = Date(timeIntervalSince1970: 100)
        window.arm()
        window.microphoneReady(at: now)
        window.microphoneReady(at: now.addingTimeInterval(10))
        XCTAssertFalse(window.acceptsCommand(at: now.addingTimeInterval(13)))
        window.arm()
        window.clear()
        window.microphoneReady(at: now)
        XCTAssertFalse(window.acceptsCommand(at: now))
    }
}
