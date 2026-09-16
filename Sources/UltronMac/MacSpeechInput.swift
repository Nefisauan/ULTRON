import AVFoundation
import Combine
import Foundation
@preconcurrency import Speech

/// User-started dictation only. Audio is never saved or sent to a cloud recognizer.
@MainActor
final class MacSpeechInput: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var isRecording = false
    @Published private(set) var transcript = ""
    @Published private(set) var status = ""
    private(set) var canRestart = false
    private var generation = UUID()
    private var engine: AVAudioEngine?
    private var recognition: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var startup: Task<Void, Never>?
    private var deadline: Task<Void, Never>?

    func start() {
        stop()
        transcript = ""
        status = "Waiting for microphone permission…"
        isActive = true
        let id = generation
        deadline = Task { [weak self] in
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled, let self, self.generation == id else { return }
            self.finish("Voice startup timed out. Check microphone and speech permissions in System Settings, then retry.")
        }
        startup = Task { [weak self] in
            guard let self else { return }
            let microphone = await AVCaptureDevice.requestAccess(for: .audio)
            guard generation == id else { return }
            guard microphone else { finish("Enable ULTRON in System Settings → Privacy & Security → Microphone."); return }
            status = "Waiting for speech recognition permission…"
            let speech = await SpeechAuthorization.request()
            guard generation == id else { return }
            guard speech == .authorized else { finish("Enable ULTRON in System Settings → Privacy & Security → Speech Recognition."); return }
            guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
                  recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
                finish("On-device English speech recognition is unavailable. You can still type your command.")
                return
            }
            let engine = AVAudioEngine()
            self.recognizer = recognizer
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = true
            request.contextualStrings = ["Ultron", "TradeScale", "Safari", "Analyze my dashboard"]
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                finish("No working microphone input was found."); return
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { @Sendable buffer, _ in
                request.append(buffer)
            }
            self.engine = engine
            self.request = request
            recognition = recognizer.recognitionTask(with: request) { @Sendable [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let finished = result?.isFinal == true
                let failed = error != nil
                Task { @MainActor [weak self] in
                    guard let self, self.generation == id else { return }
                    if let text { self.transcript = text }
                    if failed { self.finish("Dictation ended. Review the text or try again.") }
                    else if finished { self.finish("Review your command, then press Return.", restartable: true) }
                }
            }
            do {
                engine.prepare()
                try engine.start()
                isRecording = true
                status = "Listening on device · tap microphone to finish · 30-second limit"
                deadline?.cancel()
                deadline = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(30))
                    guard !Task.isCancelled, let self, self.generation == id else { return }
                    self.finish("Recording stopped after 30 seconds. Review your command.", restartable: true)
                }
            } catch { finish("The microphone could not start. Check your input device and retry.") }
        }
    }

    func stop() { finish(isActive ? "Review your command, then press Return." : "") }

    private func finish(_ message: String, restartable: Bool = false) {
        canRestart = restartable
        generation = UUID() // Reject delayed permission/recognition callbacks.
        startup?.cancel()
        startup = nil
        deadline?.cancel()
        deadline = nil
        engine?.stop()
        engine?.inputNode.removeTap(onBus: 0)
        engine = nil
        request?.endAudio()
        recognition?.cancel()
        recognition = nil
        recognizer = nil
        request = nil
        isActive = false
        isRecording = false
        status = message
    }
}
