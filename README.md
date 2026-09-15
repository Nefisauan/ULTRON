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
| On-device English dictation with review before sending | Implemented; live permission/audio test pending |
| Neural style, metallic processing, wake word | Planned |
| On-demand Safari/display capture and vision boundary | Implemented; Screen Recording permission and explicit target selection required; analyzer is a mock |
| Direct Safari page reading | Implemented; reads rendered dashboard text/tables on explicit request |
| Dashboard text analysis | Apple on-device model when available (macOS 26+); exact excerpt and Copy for ChatGPT otherwise |
| Dashboard backend API and general conversational AI | Planned |
| iPhone application | Planned; shared core and UI type-check for iOS 17+ |

Phase 1 is **not complete**. Dashboard reading has a bounded local analysis provider. No paid cloud API is configured. On-device microphone dictation is explicitly user-started; wake-word activation remains planned.

## Run on macOS

Requires macOS 14+ and Xcode 26+ with Swift 6 to build. On-device AI needs macOS 26 and an available Apple Intelligence model; page reading and manual ChatGPT handoff work without it. No API keys or third-party dependencies are needed.

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
- `Open TradeScale` → opens your existing dashboard in Safari using the URL configured in Settings
- `Open https://example.com`
- `Open File /absolute/path/to/document.pdf`
- `Show Business`, `Show Markets`, `Show Projects`, `Show Today`
- `Look at my screen` → asks for Screen Recording permission and a display, then runs the development analyzer
- `Analyze my dashboard`, `What are we seeing?`, `Read my dashboard` → read text from Safari's front tab on the configured dashboard origin; analyze locally when available
- `Capture dashboard` → explicitly select a Safari window for a screenshot; this separate vision path still uses the development mock

Application launching uses a small bundle-identifier allowlist. Missing or unsupported apps return a useful error. File opening permits ordinary folders, plain text, PDFs, and common image formats; packages, executable files, and special files are rejected. Stop cancels pending coordination and speech, but cannot undo a launch already accepted by macOS.

The menu bar uses the same session as the dashboard. It includes Open ULTRON, Open TradeScale, Show Markets, Analyze Dashboard, Look at Screen, Stop, Settings, and Quit.

## Configuration and privacy

Settings stores voice selection, rate, pitch, volume, response speech preference, and an optional TradeScale URL in local UserDefaults. Use a non-sensitive dashboard URL without embedded credentials or access tokens. ULTRON opens your existing dashboard; Safari handles your login. Analysis reads the rendered page on request. It does not access login tokens or the site's private backend APIs.

Direct page reading needs Automation access to Safari and Safari's Allow JavaScript from Apple Events setting. It does not require Screen Recording. Screenshot commands separately request Screen Recording. The microphone button requests Microphone and Speech Recognition permissions; English on-device recognition must be available. Dictation stops after 30 seconds or when finished/cancelled. Review the text and press Return to execute it. No Accessibility permission is requested. Page data stays in memory; only clicking Copy for ChatGPT places it on your clipboard for you to paste manually. ULTRON makes no cloud inference request. The conversation is limited to 40 in-memory entries, and the latest page snapshot is cleared by Stop or a new command.

Bring the correct dashboard tab to the front in Safari before analysis. Hidden content and form fields are excluded. Offscreen rendered text can be included, but iframe/shadow content, canvas charts, other tabs, and off-page data are not read. The local model sees at most 6,000 bytes of text and reports that limit. Treat model conclusions as interpretations to verify against the displayed values.

## Architecture and tree

```text
Apps/macOS/Info.plist       Development app metadata
Sources/
  UltronCore/
    Commands/              Parser, intents, asynchronous command coordinator
    Configuration/         Validated dashboard URL
    Dashboard/             Page reading/analysis interfaces, extraction, and sample modules
    Permissions/           On-demand Screen Recording interface
    Vision/                Separate screenshot and mock vision pipeline
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

The 34 tests cover commands, state/risk boundaries, speech, capture, Safari scope checks, cancellation, and page extraction. Native WebKit fixture tests verify hidden/form exclusions and table extraction without opening your dashboard. They need a macOS session able to launch WebKit's helper processes; a restrictive command sandbox may block them.

Screenshots: the dashboard has been visually inspected; repository screenshots will be added after the visual identity is refined.
