import XCTest
@testable import UltronCore

@MainActor
private final class FakeSpeechSynthesizer: SpeechSynthesizer {
    let capabilities = SpeechCapabilities(supportsStyle: true, supportsOutputProcessing: true, supportsAudioLevel: true)
    let availableVoices: [SpeechVoice] = []
    var callbacks: [(@MainActor (SpeechEvent) -> Void)] = []
    var profile: UltronVoiceProfile?
    func speak(_ text: String, profile: UltronVoiceProfile, onEvent: @escaping @MainActor (SpeechEvent) -> Void) {
        self.profile = profile
        callbacks.append(onEvent)
    }
    func stop() {}
}

final class VoiceTests: XCTestCase {
    func testProfileRoundTrip() throws {
        var profile = UltronVoiceProfile.ultron
        profile.outputProcessing = .subtleMetallic
        XCTAssertEqual(try JSONDecoder().decode(UltronVoiceProfile.self, from: JSONEncoder().encode(profile)), profile)
    }

    func testLifecycleAndStaleCallbacks() async {
        await MainActor.run {
            let fake = FakeSpeechSynthesizer()
            let controller = VoiceController(synthesizer: fake)
            controller.speak("Yes?")
            XCTAssertEqual(fake.profile, .ultron)
            XCTAssertEqual(controller.state, .thinking)
            fake.callbacks[0](.started)
            XCTAssertEqual(controller.state, .speaking)
            fake.callbacks[0](.audioLevel(2))
            XCTAssertEqual(controller.speechIntensity, 1)
            controller.speak("Ready.")
            fake.callbacks[0](.finished)
            XCTAssertEqual(controller.state, .thinking)
            fake.callbacks[1](.started)
            fake.callbacks[1](.finished)
            XCTAssertEqual(controller.state, .idle)
            fake.callbacks[1](.started)
            XCTAssertEqual(controller.state, .idle)
        }
    }

    func testInterruptionAndFailure() async {
        await MainActor.run {
            let fake = FakeSpeechSynthesizer()
            let controller = VoiceController(synthesizer: fake)
            controller.speak("Ready.")
            controller.transition(to: .seeing)
            fake.callbacks[0](.cancelled)
            XCTAssertEqual(controller.state, .seeing)
            controller.speak("Yes?")
            fake.callbacks[1](.failed("Unavailable"))
            XCTAssertEqual(controller.state, .error)
            XCTAssertEqual(controller.errorMessage, "Unavailable")
            controller.stop()
            XCTAssertEqual(controller.state, .idle)
        }
    }

    func testAppleCapabilitiesAndEmptyInput() async {
        await MainActor.run {
            let native = AppleSpeechSynthesizer()
            XCTAssertFalse(native.capabilities.supportsStyle)
            XCTAssertFalse(native.capabilities.supportsOutputProcessing)
            var event: SpeechEvent?
            native.speak("  ", profile: .ultron) { event = $0 }
            XCTAssertEqual(event, .failed("There is no text to speak."))
        }
    }
}
