# Voice security

Speech synthesis uses Apple's installed system voices. This code has no cloud client, credentials, analytics, microphone recording, screen capture, or file persistence. It does not log speech contents. The preview speaks only after the user presses Speak. Stop cancels current playback. The system may manage its own voice resources.

A future cloud adapter must disclose transmission of response text, use securely stored credentials, and support cancellation. Voice profile preferences may be persisted locally, but audio and conversation retention require separate explicit design. No actor recordings, reference performances, or cloned voices are included.
