import Combine
import Foundation
import UltronCore

/// Opt-in, bounded foreground/background session. The app must already be running.
@MainActor
final class MacWakeListener: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var status = "Hands-free is off."
    private let input = MacSpeechInput()
    private var loop: Task<Void, Never>?

    func start(state: UltronStateMachine, submit: @escaping @MainActor (String) -> Void) {
        stop()
        isEnabled = true
        status = "Hands-free · say ‘Hey Ultron, open Safari’ · 10-minute session"
        loop = Task { [weak self] in
            guard let self else { return }
            let expires = Date().addingTimeInterval(600)
            var lastText = ""
            var changedAt = Date()
            var started = false
            var followup = WakeFollowupWindow()
            while !Task.isCancelled, isEnabled, Date() < expires {
                // Never interpret ULTRON's own output or interrupt an active operation.
                if state.state != .idle && state.state != .error {
                    input.stop()
                    started = false
                    lastText = ""
                } else {
                    if input.isRecording { followup.microphoneReady(at: Date()) }
                    if input.isActive {
                        status = input.isRecording
                            ? (followup.acceptsCommand(at: Date()) ? "Listening for your command · 12-second follow-up window" : "Listening · say ‘Hey Ultron’ · 10-minute session")
                            : input.status
                    }
                    if started && !input.isActive && !input.canRestart {
                        let failure = input.status
                        stop()
                        status = "Hands-free stopped. \(failure)"
                        return
                    }
                    let text = input.transcript
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    let candidate = WakePhrase.command(in: text) ?? (followup.acceptsCommand(at: Date()) && !trimmed.isEmpty ? trimmed : nil)
                    if text != lastText { lastText = text; changedAt = Date() }
                    if started, let command = candidate,
                       Date().timeIntervalSince(changedAt) >= 1.2 {
                        input.stop()
                        started = false
                        lastText = ""
                        if command == "Hey Ultron" { followup.arm() } else { followup.clear() }
                        status = command == "Hey Ultron" ? "Responding · your follow-up window starts when the microphone is ready" : "Processing your command · microphone paused"
                        submit(command)
                        try? await Task.sleep(for: .milliseconds(500))
                    } else if !input.isActive {
                        // Keep a completed wake utterance long enough to settle before dispatch.
                        if !started || candidate == nil {
                            input.start()
                            started = true
                            lastText = ""
                        }
                    }
                }
                try? await Task.sleep(for: .milliseconds(200))
            }
            if !Task.isCancelled { stop(); status = "Hands-free session ended. Enable it again to continue." }
        }
    }

    func stop() {
        isEnabled = false
        loop?.cancel()
        loop = nil
        input.stop()
        status = "Hands-free is off."
    }
}
