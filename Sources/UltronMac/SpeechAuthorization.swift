@preconcurrency import Speech

/// Speech can deliver authorization on a background queue. Never inherit UI actor isolation here.
enum SpeechAuthorization {
    static func request(
        using register: @Sendable (@escaping @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void) -> Void = {
            SFSpeechRecognizer.requestAuthorization($0)
        }
    ) async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            register { @Sendable status in
                continuation.resume(returning: status)
            }
        }
    }
}
