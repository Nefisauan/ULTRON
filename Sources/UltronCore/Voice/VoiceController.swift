import Combine
import Foundation

public enum UltronState: String, Sendable {
    case idle, listening, thinking, seeing, acting, speaking, error
}

/// Commands and AI submit final response text here, without importing AVFoundation.
@MainActor
public final class VoiceController: ObservableObject {
    @Published public private(set) var state: UltronState = .idle
    @Published public private(set) var speechIntensity: Double = 0
    @Published public private(set) var lastWordAt: Date = .distantPast
    @Published public private(set) var errorMessage: String?
    private let synthesizer: any SpeechSynthesizer
    private var requestID = UUID()

    public init(synthesizer: any SpeechSynthesizer) { self.synthesizer = synthesizer }

    public func speak(_ text: String, profile: UltronVoiceProfile = .ultron) {
        let id = UUID()
        requestID = id
        synthesizer.stop()
        state = .thinking
        errorMessage = nil
        speechIntensity = 0
        lastWordAt = .distantPast
        synthesizer.speak(text, profile: profile) { [weak self] event in
            guard let self, self.requestID == id else { return }
            switch event {
            case .started: self.state = .speaking
            case .wordBoundary: self.lastWordAt = Date()
            case .audioLevel(let level):
                self.speechIntensity = level.isFinite ? min(1, max(0, level)) : 0
            case .finished, .cancelled:
                self.state = .idle
                self.speechIntensity = 0
                self.requestID = UUID()
            case .failed(let message):
                self.state = .error
                self.errorMessage = message
                self.speechIntensity = 0
                self.requestID = UUID()
            }
        }
    }

    /// Call before listening, seeing, or executing a new command to prevent stale speech events.
    public func transition(to state: UltronState) {
        requestID = UUID()
        synthesizer.stop()
        speechIntensity = 0
        errorMessage = nil
        self.state = state
    }

    public func stop() { transition(to: .idle) }
}
