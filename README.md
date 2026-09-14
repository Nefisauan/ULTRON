# ULTRON

A native personal AI operating layer for macOS and, eventually, iPhone. The current Phase 1 milestone is a local macOS command dashboard with an original animated core and provider-independent speech output. It is not yet a conversational AI agent.

## Current status

| Feature | Status |
| --- | --- |
| macOS dashboard, animated core, typed command input | Working; live UI checked |
| Application state machine and tool registry | Working; tested |
| Open Safari, Xcode, Calculator | Implemented; Calculator live-tested |
| Configurable TradeScale shortcut and HTTP/HTTPS opening | Working; tested with a temporary example URL |
| Show Business, Markets, Projects, Today | Working; all data explicitly sample |
| Local document/folder opening | Implemented; policy unit-tested, native opening not live-tested |
| Native speech, profile, word-timed visualization | Working; start/finish observed, voice quality still needs audition |
| Menu bar actions | Implemented; dedicated status-menu interaction pending |
| Persistent voice preferences and dashboard URL | Implemented; URL save/clear live-tested |
| Neural style, metallic processing, recognition, wake word | Planned |
| Screen capture and vision | Planned; commands return an explicit unavailable message |
| Conversational AI and live dashboard integrations | Planned |
| iPhone application | Planned; shared core and UI type-check for iOS 17+ |

Phase 1 is **not complete**. No Phase 2 AI provider or microphone integration has been started.

## Run on macOS

Requires macOS 14+ and Xcode with Swift 6. No API keys or third-party dependencies are needed.

```sh
./Scripts/build-macos.sh
open .build/app/ULTRON.app
```

This produces an ad-hoc-signed development app. Developer ID distribution, notarization, a production icon, and an Xcode iPhone project remain future work. Alternatively, open `Package.swift` in Xcode, select the `UltronMac` executable and My Mac, and Run.

The independent voice laboratory remains available:

```sh
swift run UltronVoicePreview
```

## Commands

- `Hey Ultron` → “Yes?” (typed greeting; no wake-word listener)
- `Open Safari`, `Open Xcode`, `Open Calculator`
- `Open TradeScale` → opens the URL configured in Settings
- `Open https://example.com`
- `Open File /absolute/path/to/document.pdf`
- `Show Business`, `Show Markets`, `Show Projects`, `Show Today`
- `Look at my screen` → explicit “not implemented” response; no capture occurs

Application launching uses a small bundle-identifier allowlist. Missing or unsupported apps return a useful error. File opening permits ordinary folders, plain text, PDFs, and common image formats; packages, executable files, and special files are rejected. Stop cancels pending coordination and speech, but cannot undo a launch already accepted by macOS.

The menu bar uses the same session as the dashboard. It offers Open ULTRON, Open TradeScale, Show Markets, Stop, Settings, and Quit.

## Configuration and privacy

Settings stores voice selection, rate, pitch, volume, response speech preference, and an optional TradeScale URL in local UserDefaults. Use a non-sensitive dashboard URL without embedded credentials or access tokens. No TradeScale account is connected. The UI does not expose nonfunctional neural style/processing controls.

No microphone, speech-recognition, screen-recording, or Accessibility permission is requested. No cloud AI, analytics, background capture, or command-text logging is implemented. The conversation is in memory and limited to 40 entries. Links opened in the browser naturally use the browser's network and existing account session.

## Architecture and tree

```text
Apps/macOS/Info.plist       Development app metadata
Sources/
  UltronCore/
    Commands/              Parser, intents, asynchronous command coordinator
    Configuration/         Validated dashboard URL
    Dashboard/             Provider protocol and sample modules
    State/                 Shared operation-aware state machine
    Tools/                 Registry, risk gate, safe-tool interfaces, file policy
    Voice/                 Speech protocol, profile, Apple adapter, controller
  UltronUI/                Shared animated SwiftUI core
  UltronMac/               Dashboard, settings, menu bar, local system adapters
  UltronVoicePreview/      Standalone voice laboratory
Tests/UltronCoreTests/     Offline tests and injected fake services
Scripts/build-macos.sh     Build and package a development .app
```

See [architecture](docs/architecture.md), [security](docs/security.md), [permissions](docs/permissions.md), [voice design](docs/voice-architecture.md), [verification](docs/verification.md), and [roadmap](docs/roadmap.md).

## Testing

```sh
swift test
```

The 19 tests cover parser normalization, configuration validation, safe file policy, sample dashboard data, state ownership, registry routing, risk rejection, native speech capabilities, stale callbacks, cancellation, and success/failure speech behavior. No network or system application launch is required by the tests.

Screenshots: the dashboard has been visually inspected; repository screenshots will be added after the visual identity is refined.
