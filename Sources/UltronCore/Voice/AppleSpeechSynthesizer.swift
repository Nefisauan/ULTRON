import AVFoundation

@MainActor
public final class AppleSpeechSynthesizer: NSObject, SpeechSynthesizer, AVSpeechSynthesizerDelegate {
    private let engine = AVSpeechSynthesizer()
    private var current: AVSpeechUtterance?
    private var callback: (@MainActor (SpeechEvent) -> Void)?

    public let capabilities = SpeechCapabilities(
        supportsStyle: false, supportsOutputProcessing: false, supportsAudioLevel: false)

    public var availableVoices: [SpeechVoice] {
        AVSpeechSynthesisVoice.speechVoices().map {
            SpeechVoice(id: $0.identifier, name: $0.name, language: $0.language)
        }.sorted { $0.name < $1.name }
    }

    public override init() {
        super.init()
        engine.delegate = self
    }

    public func speak(_ text: String, profile: UltronVoiceProfile,
                      onEvent: @escaping @MainActor (SpeechEvent) -> Void) {
        stop()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onEvent(.failed("There is no text to speak."))
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let preferred = profile.voiceIdentifier.flatMap { AVSpeechSynthesisVoice(identifier: $0) }
        let male = voices.first { $0.language == profile.language && $0.gender == .male }
        guard let voice = preferred ?? male ?? AVSpeechSynthesisVoice(language: profile.language) else {
            onEvent(.failed("No installed voice supports \(profile.language)."))
            return
        }
        utterance.voice = voice
        utterance.rate = Float(clamp(profile.speakingRate, 0.5, 1.5, fallback: 0.88)) * AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = Float(clamp(profile.pitch, 0.5, 2, fallback: 0.82))
        utterance.volume = Float(clamp(profile.volume, 0, 1, fallback: 0.9))
        current = utterance
        callback = onEvent
        engine.speak(utterance)
    }

    public func stop() {
        let previous = callback
        current = nil
        callback = nil
        engine.stopSpeaking(at: .immediate)
        previous?(.cancelled)
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        forward(.started, id: ObjectIdentifier(utterance))
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                  willSpeakRangeOfSpeechString characterRange: NSRange,
                                  utterance: AVSpeechUtterance) {
        forward(.wordBoundary, id: ObjectIdentifier(utterance))
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        forward(.finished, id: ObjectIdentifier(utterance))
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        forward(.cancelled, id: ObjectIdentifier(utterance))
    }

    nonisolated private func forward(_ event: SpeechEvent, id: ObjectIdentifier) {
        Task { @MainActor [weak self] in
            guard let self, let current = self.current, ObjectIdentifier(current) == id else { return }
            let previous = self.callback
            if event == .finished || event == .cancelled {
                self.current = nil
                self.callback = nil
            }
            previous?(event)
        }
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double, fallback: Double) -> Double {
        value.isFinite ? min(upper, max(lower, value)) : fallback
    }
}
