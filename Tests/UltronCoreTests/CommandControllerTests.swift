import XCTest
@testable import UltronCore

@MainActor
private final class RecordingSpeech: SpeechSynthesizer {
    let capabilities = SpeechCapabilities(supportsStyle: false, supportsOutputProcessing: false, supportsAudioLevel: false)
    let availableVoices: [SpeechVoice] = []
    var texts: [String] = []
    var callback: (@MainActor (SpeechEvent) -> Void)?
    func speak(_ text: String, profile: UltronVoiceProfile, onEvent: @escaping @MainActor (SpeechEvent) -> Void) {
        texts.append(text)
        callback = onEvent
    }
    func stop() { callback = nil }
}

@MainActor
private final class DelayedApplicationController: ApplicationController {
    let events = AsyncStream<Void>.makeStream()
    var continuation: CheckedContinuation<Void, Never>?
    func openApplication(named name: String) async throws {
        await withCheckedContinuation {
            continuation = $0
            events.continuation.yield(())
        }
    }
    func finish() { continuation?.resume(); continuation = nil }
}

final class CommandControllerTests: XCTestCase {
    @MainActor
    func testClearConversationCancelsPendingWorkAndErasesMemory() async throws {
        let system = DelayedApplicationController()
        let memory = InMemoryConversationMemory()
        let registry = UltronToolRegistry()
        try registry.register(OpenApplicationTool(controller: system))
        let controller = CommandController(voice: VoiceController(synthesizer: RecordingSpeech()), registry: registry, memory: memory)
        var events = system.events.stream.makeAsyncIterator()
        let work = controller.submit("Open Safari", context: .init(dashboard: .init()))
        await events.next()
        controller.clearConversation()
        system.finish()
        await work.value
        XCTAssertTrue(memory.messages.isEmpty)
        XCTAssertTrue(controller.conversation.isEmpty)
        XCTAssertNil(controller.lastCommand)
        XCTAssertNil(controller.lastResult)
        XCTAssertEqual(controller.stateMachine.state, .idle)
    }

    @MainActor
    func testRemoteExecutorIsExplicitAndNeverFallsBackToLocalOnFailure() async throws {
        let speech = RecordingSpeech()
        let controller = CommandController(voice: VoiceController(synthesizer: speech), registry: UltronToolRegistry())
        controller.remoteExecutor = { _ in "Remote response" }
        await controller.submit("Hey Ultron", context: .init(dashboard: .init()), speakResponses: false).value
        XCTAssertEqual(controller.lastResult?.message, "Remote response")
        controller.remoteExecutor = { _ in throw CommandError.launchFailed }
        await controller.submit("Hey Ultron", context: .init(dashboard: .init()), speakResponses: false).value
        XCTAssertNil(controller.lastResult)
        XCTAssertEqual(controller.stateMachine.state, .error)
        XCTAssertFalse(controller.conversation.contains { $0.text == "Yes?" })
    }

    @MainActor
    func testSuccessfulActionSpeaksOnlyAfterToolReturns() async throws {
        let system = DelayedApplicationController()
        let speech = RecordingSpeech()
        let registry = UltronToolRegistry()
        try registry.register(OpenApplicationTool(controller: system))
        let controller = CommandController(voice: VoiceController(synthesizer: speech), registry: registry)
        var events = system.events.stream.makeAsyncIterator()
        let work = controller.submit("Open Safari", context: .init(dashboard: .init()))
        await events.next()
        XCTAssertEqual(controller.stateMachine.state, .acting)
        XCTAssertTrue(speech.texts.isEmpty)
        system.finish()
        await work.value
        XCTAssertEqual(speech.texts, ["Opening Safari now."])
        XCTAssertEqual(controller.stateMachine.state, .thinking)
        speech.callback?(.started)
        XCTAssertEqual(controller.stateMachine.state, .speaking)
        speech.callback?(.finished)
        XCTAssertEqual(controller.stateMachine.state, .idle)
    }

    @MainActor
    func testReplacementSuppressesLateToolResult() async throws {
        let system = DelayedApplicationController()
        let speech = RecordingSpeech()
        let registry = UltronToolRegistry()
        try registry.register(OpenApplicationTool(controller: system))
        let controller = CommandController(voice: VoiceController(synthesizer: speech), registry: registry)
        var events = system.events.stream.makeAsyncIterator()
        let old = controller.submit("Open Safari", context: .init(dashboard: .init()))
        await events.next()
        await controller.submit("Hey Ultron", context: .init(dashboard: .init())).value
        system.finish()
        await old.value
        XCTAssertEqual(speech.texts, ["Yes?"])
        XCTAssertEqual(controller.lastResult?.message, "Yes?")
        XCTAssertFalse(controller.conversation.contains { $0.text == "Opening Safari now." })
    }

    @MainActor
    func testFailedActionNeverSpeaksSuccessAndNextCommandRecovers() async throws {
        let system = RecordingSystemController()
        system.failure = .applicationNotFound("Xcode")
        let speech = RecordingSpeech()
        let registry = UltronToolRegistry()
        try registry.register(OpenApplicationTool(controller: system))
        try registry.register(ShowDashboardModuleTool())
        let controller = CommandController(voice: VoiceController(synthesizer: speech), registry: registry)
        await controller.submit("Open Xcode", context: .init(dashboard: .init())).value
        XCTAssertEqual(controller.stateMachine.state, .error)
        XCTAssertTrue(speech.texts.isEmpty)
        XCTAssertNil(controller.lastResult)
        await controller.submit("Show Markets", context: .init(dashboard: .init()), speakResponses: false).value
        XCTAssertEqual(controller.selectedModule, .markets)
        XCTAssertEqual(controller.stateMachine.state, .idle)
        XCTAssertNil(controller.stateMachine.errorMessage)
    }

    @MainActor
    func testStopRejectsPendingCompletion() async throws {
        let system = DelayedApplicationController()
        let speech = RecordingSpeech()
        let registry = UltronToolRegistry()
        try registry.register(OpenApplicationTool(controller: system))
        let controller = CommandController(voice: VoiceController(synthesizer: speech), registry: registry)
        var events = system.events.stream.makeAsyncIterator()
        let work = controller.submit("Open Safari", context: .init(dashboard: .init()))
        await events.next()
        controller.stop()
        system.finish()
        await work.value
        XCTAssertEqual(controller.stateMachine.state, .idle)
        XCTAssertTrue(speech.texts.isEmpty)
        XCTAssertFalse(controller.isExecuting)
    }
}
