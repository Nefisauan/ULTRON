import XCTest
@testable import UltronCore

final class WakePhraseTests: XCTestCase {
    func testRequiresLeadingCompleteWakePhrase() {
        XCTAssertEqual(WakePhrase.command(in: "Hey Ultron, Open Safari"), "Open Safari")
        XCTAssertEqual(WakePhrase.command(in: " HEY ULTRON! "), "Hey Ultron")
        XCTAssertNil(WakePhrase.command(in: "She said hey Ultron open Safari"))
        XCTAssertNil(WakePhrase.command(in: "Hey Ultronish open Safari"))
        XCTAssertNil(WakePhrase.command(in: "Open Safari"))
    }
}
