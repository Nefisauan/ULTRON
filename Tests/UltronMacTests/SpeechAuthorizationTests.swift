import XCTest
@preconcurrency import Speech
@testable import UltronMac

final class SpeechAuthorizationTests: XCTestCase {
    @MainActor
    func testAuthorizationReturnsFromBackgroundQueueToUIActor() async {
        for expected in [SFSpeechRecognizerAuthorizationStatus.authorized, .denied, .restricted] {
            let result = await SpeechAuthorization.request { callback in
                DispatchQueue.global().async { callback(expected) }
            }
            MainActor.assertIsolated()
            XCTAssertEqual(result, expected)
        }
    }
}
