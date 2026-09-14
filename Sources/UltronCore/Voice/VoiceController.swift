import Combine
import Foundation

/// Commands and AI submit final response text here, without importing AVFoundation.
@MainActor
public final class VoiceController: ObservableObject {
    public let stateMachine: UltronStateMachine
    public var state: UltronState { stateMachine.state }
    public var errorMessage: String? { stateMachine.errorMessage }
    @Published public private(set) var speechIntensity: Double = 0
    @Published public private(set) var lastWordAt: Date = .distantPast
    private let synthesizer: any SpeechSynthesizer
    private var requestID = UUID()
    private var observation: AnyCancellable?

    public init(synthesizer: any SpeechSynthesizer, stateMachine: UltronStateMachine? = nil) {
        self.synthesizer = synthesizer
        self.stateMachine = stateMachine ?? UltronStateMachine()
        observation = self.stateMachine.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }

    public func speak(_ text: String, profile: UltronVoiceProfile = .ultron, operationID: UUID? = nil) {
        if let operationID, !stateMachine.owns(operationID) { return }
        let id = UUID()
        requestID = id
        synthesizer.stop()
        let operation = operationID ?? stateMachine.begin(.thinking)
        guard stateMachine.transition(to: .thinking, for: operation) else { return }
        speechIntensity = 0
        lastWordAt = .distantPast
        synthesizer.speak(text, profile: profile) { [weak self] event in
            guard let self, self.requestID == id, self.stateMachine.owns(operation) else { return }
            switch event {
            case .started: self.stateMachine.transition(to: .speaking, for: operation)
            case .wordBoundary: self.lastWordAt = Date()
            case .audioLevel(let level):
                self.speechIntensity = level.isFinite ? min(1, max(0, level)) : 0
            case .finished, .cancelled:
                self.stateMachine.transition(to: .idle, for: operation)
                self.speechIntensity = 0
                self.requestID = UUID()
            case .failed(let message):
                self.stateMachine.fail(message, for: operation)
                self.speechIntensity = 0
                self.requestID = UUID()
            }
        }
    }

    /// Compatibility for the voice lab. Coordinators begin owned operations on the shared state machine.
    public func transition(to state: UltronState) {
        stop()
        switch state {
        case .idle: break
        case .listening: stateMachine.begin(.listening)
        case .thinking: stateMachine.begin(.thinking)
        case .seeing: stateMachine.begin(.seeing)
        case .acting: stateMachine.begin(.acting)
        case .speaking, .error: break // Require actual playback or a concrete failure.
        }
    }

    public func stop() {
        requestID = UUID()
        synthesizer.stop()
        speechIntensity = 0
        stateMachine.reset()
    }
}
