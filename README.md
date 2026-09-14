# ULTRON voice foundation

An original, calm, authoritative AI voice identity for ULTRON. This repository currently contains the voice subsystem and a macOS voice preview, not the complete Phase 1 assistant described in the project brief.

| Feature | Status |
| --- | --- |
| Provider-independent speech interface and Codable profile | Working |
| Apple native synthesis; voice, rate, pitch, volume controls | Implemented; audible review pending |
| Speech lifecycle and word-timed core visualization | Implemented; visual review pending |
| Neural TTS, metallic processing, style control | Planned |
| Wake word, recognition, commands, dashboard, screen vision | Planned |
| iPhone application | Planned; shared core supports iOS 17+ |

## Run

Requires Xcode with Swift 6 and macOS 14+. Open `Package.swift` in Xcode, select UltronVoicePreview and My Mac, then Run. Or use:

```sh
swift run UltronVoicePreview
swift test
```

Choose an installed voice and press Speak. Automatic selection prefers an installed male voice matching en-US, falling back to the language default. Availability and perceived depth vary by device. Controls apply to the next utterance and are session-only. Profile serialization is available for a future preferences store.

No API keys, microphone, speech recognition, screen recording, or Accessibility permissions are required. Installed system voices are used; additional voices may require download through macOS settings.

## Structure

- `Sources/UltronCore/Voice`: profile, protocol, native adapter, controller/state
- `Sources/UltronVoicePreview`: SwiftUI demonstration and configuration
- `Tests/UltronCoreTests`: provider-independent lifecycle and profile coverage
- `docs`: voice architecture, security, verification, and roadmap

Screenshots: pending visual review.

See [voice architecture](docs/voice-architecture.md) and [verification](docs/verification.md).
