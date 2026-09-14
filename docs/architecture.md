# Phase 1 command foundation

The macOS app composes native adapters, the tool registry, preferences, speech, and dashboard provider in `MacSession`. One session is shared by the window and menu bar. Views render state and submit text; they do not launch apps directly.

## Command flow

Text → `UltronCommand` → deterministic `CommandParser` → `UltronIntent` → `UltronToolRegistry` risk check → `UltronTool.execute` → result → conversation and optional speech.

Greetings return locally without a tool. Unknown commands produce a useful error; no AI behavior is simulated. Each tool declares an identifier, description, required input, and risk. Only readOnly and lowRisk tools can execute. Other risk categories are modeled but blocked until a proper confirmation/authorization workflow exists. Registration rejects duplicate identifiers. Tools validate their input again rather than relying exclusively on the parser.

`ApplicationController` and `ResourceOpener` isolate AppKit from shared logic. The Mac implementation uses NSWorkspace and known application bundle IDs, never a shell, AppleScript, or mouse automation. Future action preference remains direct API → URL scheme → constrained native/CLI integration → justified AppleScript → Accessibility → visual automation as a last resort. Future implementations must preserve the registry safety boundary.

## State and concurrency

`UltronStateMachine` owns idle, listening, thinking, seeing, acting, speaking, and error. Each new operation receives a UUID. Transitions and failures from superseded operations are ignored; terminal transitions release ownership. The allowed transition graph is tested. New commands cancel the previous Task and speech before beginning a new operation.

The command coordinator owns command work and a bounded in-memory conversation. The voice controller shares the same state machine and begins speaking only on a native playback start callback. A separate speech request token rejects replaced utterances. Spoken success text is submitted only after a tool returns successfully. Unexpected underlying errors are sanitized before display; expected typed errors remain actionable.

Stop cannot roll back an NSWorkspace launch that has already been accepted. It cancels the remaining coordinator work and prevents stale success speech. A future remote/long-running adapter must implement cancellation and bounded timeouts at its own transport boundary.

## Dashboard and preferences

`DashboardProvider` is independent of views. Its current implementation returns four explicitly marked sample modules. Business/market-specific provider models can be introduced when their integration contracts are defined. No live prices, account metrics, or personal calendar data are implied.

Voice and dashboard preferences persist in UserDefaults. The conversation does not persist. The shared profile and speech protocol remain independent of Apple synthesis, and public voice/dashboard models can be constructed by adapters in other modules.

## Platform status

The Swift package contains a shared core, reusable SwiftUI core, macOS app executable, and voice lab. The packaging script adds bundle metadata and ad-hoc signs the development app. It does not produce a distribution release or an iPhone app. Shared core and UI compile against the installed iOS simulator SDK; an iOS shell and proper Xcode project are still upcoming.
