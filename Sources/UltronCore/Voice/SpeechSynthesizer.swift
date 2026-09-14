import Foundation

public enum SpeechEvent: Equatable, Sendable {
    case started
    /// Timing hint, not a measurement of audio amplitude.
    case wordBoundary
    /// Optional normalized amplitude supplied by future PCM playback adapters.
    case audioLevel(Double)
    case finished
    case cancelled
    case failed(String)
}

@MainActor
public protocol SpeechSynthesizer: AnyObject {
    var capabilities: SpeechCapabilities { get }
    var availableVoices: [SpeechVoice] { get }
    /// A request replaces any previous request. All callbacks run on the main actor.
    func speak(_ text: String, profile: UltronVoiceProfile, onEvent: @escaping @MainActor (SpeechEvent) -> Void)
    func stop()
}
