import Foundation

/// An original AI identity; never a request to imitate an actor or fictional performance.
public struct UltronVoiceProfile: Codable, Equatable, Sendable {
    public var voiceIdentifier: String?
    public var language: String
    /// Relative speed: 1 is the provider's default.
    public var speakingRate: Double
    /// Relative pitch: 1 is unmodified.
    public var pitch: Double
    public var volume: Double
    public var style: String
    public var outputProcessing: OutputProcessing

    public enum OutputProcessing: String, Codable, Sendable {
        case none, subtleMetallic
    }

    public init(voiceIdentifier: String? = nil, language: String = "en-US",
                speakingRate: Double = 0.88, pitch: Double = 0.82, volume: Double = 0.9,
                style: String = "Calm, authoritative, intelligent; deliberate, concise delivery with subtle dry personality.",
                outputProcessing: OutputProcessing = .none) {
        self.voiceIdentifier = voiceIdentifier
        self.language = language
        self.speakingRate = speakingRate
        self.pitch = pitch
        self.volume = volume
        self.style = style
        self.outputProcessing = outputProcessing
    }

    public static let ultron = UltronVoiceProfile()
}

public struct SpeechVoice: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let language: String

    public init(id: String, name: String, language: String) {
        self.id = id
        self.name = name
        self.language = language
    }
}

public struct SpeechCapabilities: Sendable {
    public let supportsStyle: Bool
    public let supportsOutputProcessing: Bool
    public let supportsAudioLevel: Bool
    public init(supportsStyle: Bool, supportsOutputProcessing: Bool, supportsAudioLevel: Bool) {
        self.supportsStyle = supportsStyle
        self.supportsOutputProcessing = supportsOutputProcessing
        self.supportsAudioLevel = supportsAudioLevel
    }
}
