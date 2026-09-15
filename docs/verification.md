# Verification — September 14, 2026

## Holographic core — September 15, 2026

- Replaced the solid orb with a native Canvas wire sphere, four segmented orbital bands, instrument graduations, contextual labels, and a speech envelope driven by native word timing.
- Reduced Motion pauses orbital movement and suppresses speech expansion. Background scenes pause the animation timeline; errors use a static amber indicator.
- macOS package build and ad-hoc signature validation passed. Version 0.5.0 was installed and relaunched. A screenshot verified the holographic layout, readable command controls, and orbital core. Shared UI iOS 17 simulator type-check passed.

## Explicit speech input — September 15, 2026

- Added user-started on-device English dictation, permission explanations, text review before execution, a 30-second recording deadline, and cancellation guards for delayed callbacks. No wake-word listener or cloud fallback.
- Full existing regression suite: **34 tests, 0 failures**. These tests cover core command and speech-output behavior, not live microphone transcription.
- Live microphone button entered the permission/listening flow; Stop returned the app to idle before recording. No permission was granted automatically. Actual transcription, device changes, and permission-denial behavior remain manual acceptance checks.

## Safari page reading and local analysis (0.4.0)

- Full Swift test suite: **34 tests, 0 failures**, including Safari script compilation and rendered WebKit fixtures for hidden/private/form text exclusion, tables, and origin checks. Native helper tests require running outside the command sandbox.
- macOS app packaging and ad-hoc signature verification passed. Updated app installed locally and relaunched; saved dashboard configuration survived.
- Shared core Swift 6 type-check for the arm64 iOS 17 simulator passed using the installed iOS 26.2 SDK.
- Live settings report that Apple's on-device model is ready on this Mac.
- Live `Analyze my dashboard` reached Safari and reported its disabled JavaScript-from-Apple-Events setting with actionable instructions. No permission was changed automatically. End-to-end dashboard interpretation remains pending that user-controlled setting.
- No cloud API or paid provider was configured. Copy for ChatGPT is a manual clipboard handoff; it does not submit data.
- The user previously confirmed successful screen capture. That separate path still uses the development vision analyzer.

The following records describe earlier milestones.

## Automated

- Swift 6 macOS debug build: core, shared UI, voice laboratory, and macOS app passed.
- XCTest: **19 tests, 0 failures**. Parser/configuration validation, file policy, sample provider, state transitions and operation ownership, registry/risk gates, speech lifecycle, and cancellation/replacement behavior.
- Shared core module emission and shared SwiftUI type-check for arm64 iOS 17 simulator using the installed iOS 26.2 SDK: passed. This is not an iPhone app build or simulator launch.
- Development app packaging script: passed; ad-hoc signature verified.
- Bundle plist and shell script syntax: passed.
- Swift source warnings: none. Restricted-environment SwiftPM cache notices remain environmental.
- Whitespace and basic source scans for private-key/API-key patterns: clean. No network dependencies, credentials, or build artifacts are intended for Git.

## Live macOS smoke tests

- App launched; dashboard, original animated core, command input, sample cards, and settings rendered.
- `Show Markets` selected Markets and displayed the sample-data response.
- Native playback emitted speaking state and returned to idle on completion.
- `Open Calculator` returned success and Calculator's window was confirmed.
- `Open TradeScale` without configuration showed an actionable Settings error.
- Settings rejected a file URL, saved `https://example.com`, and the configured dashboard command returned success after the native browser-opening request. No real TradeScale account was used or verified.
- Temporary example URL was cleared and saved after the test.
- Vision boundary tests cover denied permission, cancellation, one-frame capture ownership, analyzer isolation, Safari-window intent routing, and empty-frame rejection. Live permission/capture should be tested on the user's Mac because this environment has no reason to grant Screen Recording automatically.
- The final packaged app was relaunched successfully. Dashboard accessibility labels were checked after removing repeated child labels.

## Still pending

- Audible voice identity/quality judgment, headphones/output-route checks, and interruption timing under load.
- Native Safari/Xcode and file-opening smoke tests; menu-bar-extra interaction; persisted voice-setting restart tests.
- Performance measurement and full accessibility review.
- iPhone shell/simulator launch, a live Screen Recording permission/capture run, actual dashboard interpretation, and the rest of Phase 1 acceptance.

## Restricted-environment commands

The default build first encountered sandbox restrictions when launching the GUI. Launching the development app outside the command sandbox succeeded. No app permission prompts were bypassed.

```sh
CLANG_MODULE_CACHE_PATH=/tmp/ultron-clang-cache swift test --disable-sandbox --cache-path /tmp/ultron-swift-cache --scratch-path /tmp/ultron-voice-build
ULTRON_BUILD_DIR=/tmp/ultron-voice-build ULTRON_DISABLE_BUILD_SANDBOX=1 ./Scripts/build-macos.sh
```

On a normal development machine, use `swift test` and `./Scripts/build-macos.sh`. The build-sandbox override is for the build process only and does not change macOS app permissions.

## Safari preference follow-up

Web opening now targets Safari explicitly using its bundle identifier. The updated macOS build and all 19 tests pass. The user's existing dashboard URL was saved only in local preferences and verified after app restart; it is not included in repository files. The dashboard itself was not inspected or analyzed during this configuration change. The Safari-specific opening path has compiled but has not received a separate live navigation test.
