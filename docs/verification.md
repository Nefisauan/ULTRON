# Verification — September 13, 2026

- macOS Swift 6 debug build, including the SwiftUI executable: passed.
- XCTest: 4 tests, 0 failures. Covers profile round-trip, lifecycle, replacement/stale callbacks, interruption, failure recovery, Apple capability reporting, and empty text handling.
- Shared core type-check against arm64 iOS 17 simulator target with installed iOS 26.2 SDK: passed. This is not an iPhone app build or simulator launch.
- No Swift source warnings after correcting delegate actor isolation.
- Basic source scan for API-key/private-key patterns: no matches. No external dependencies or credentials are included.
- Audible voice quality, actual playback callback timing, and rendered UI: manual verification pending.

The restricted environment prevents default SwiftPM cache writes. Successful command:

```sh
CLANG_MODULE_CACHE_PATH=/tmp/ultron-clang-cache swift test --disable-sandbox --cache-path /tmp/ultron-swift-cache --scratch-path /tmp/ultron-voice-build
```

On a normal development machine, `swift test` should suffice.

## Manual review

Run the preview, select a male voice, and audition “Yes?” and “Opening it now.” Verify rate, pitch, volume, Stop mid-sentence, and replacing an active utterance. Confirm the core enters speaking when playback starts and returns to idle on completion. Try Reduce Motion and backgrounding the window. Voice settings currently last for the session only.

The preview does not open TradeScale or listen for “Hey Ultron.” Those examples are voice audition text until command routing and wake-word support are built.
