import XCTest
@testable import UltronCore

final class StateMachineTests: XCTestCase {
    @MainActor
    func testScreenAnalysisAndSpeechLifecycle() async {
        let state = UltronStateMachine()
        let id = state.begin(.seeing)
        XCTAssertEqual(state.state, .seeing)
        XCTAssertTrue(state.transition(to: .thinking, for: id))
        XCTAssertTrue(state.transition(to: .speaking, for: id))
        XCTAssertTrue(state.transition(to: .idle, for: id))
        XCTAssertNil(state.operationID)
        XCTAssertFalse(state.transition(to: .speaking, for: id))
    }

    @MainActor
    func testNewOperationsRejectStaleFailuresAndTransitions() async {
        let state = UltronStateMachine()
        let old = state.begin(.acting)
        let current = state.begin(.listening)
        state.fail("Old error", for: old)
        XCTAssertFalse(state.transition(to: .idle, for: old))
        XCTAssertEqual(state.state, .listening)
        XCTAssertNil(state.errorMessage)
        XCTAssertFalse(state.transition(to: .speaking, for: current))
        XCTAssertTrue(state.transition(to: .thinking, for: current))
        state.fail("Permission denied", for: current)
        XCTAssertEqual(state.state, .error)
        XCTAssertEqual(state.errorMessage, "Permission denied")
        _ = state.begin(.thinking)
        XCTAssertNil(state.errorMessage)
        state.reset()
        XCTAssertEqual(state.state, .idle)
        XCTAssertNil(state.operationID)
    }
}
