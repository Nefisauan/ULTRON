# Security model

## Current data flow

Typed text stays in an in-memory conversation limited to 40 entries. A deterministic parser selects vetted local tools. Successful response text may be sent to Apple's installed system voice for playback. The program has no AI/cloud client, analytics, microphone recording, screen capture, or audio-file retention. The system manages its own voice resources.

Commands are never evaluated as shell or AppleScript. Applications resolve through a short allowlist of known bundle identifiers. URL tools accept only HTTP/HTTPS addresses with a host and no embedded credentials; arbitrary application URL schemes are rejected. Opening a URL hands it to the user's browser and may use that browser's existing authenticated session. No credentials are handled by ULTRON.

File paths must be explicit. Native file opening resolves symbolic links and permits ordinary folders and a small set of non-executable regular document/image types. Application packages, executable files, and special files are rejected. This is a conservative development policy, not a replacement for OS access controls or safe document handling by the destination app.

The registry blocks requiresConfirmation, sensitive, and prohibited tools. There is no confirmation implementation pretending to authorize them. No destructive actions, email sending, financial transactions, or unrestricted shell tools are registered.

## Retention and logging

UserDefaults stores voice preferences, a response-speech toggle, and a non-sensitive dashboard URL. Do not place access tokens in URLs. Screenshots, speech audio, and transcripts are not automatically persisted. OSLog records generic command lifecycle events only, without text, URLs, paths, or provider error payloads. In-memory conversation/debug content is visible only within the app UI.

The development app is ad-hoc signed and is not an App Sandbox or notarized distribution build. Ordinary filesystem access is subject to macOS protections. It never requests microphone, Screen Recording, or Accessibility access. Review entitlements and distribution signing separately before release.

## Future boundaries

A future cloud adapter must disclose text/image transmission, store credentials in Keychain, support cancellation, and avoid logging sensitive payloads. Explicit user-triggered vision must capture on demand, retain frames only as long as needed, and never silently upload. Permission handling and confirmation workflows must be centralized before enabling corresponding tools.

The voice identity is original. No actor recordings, reference performances, or cloned voices are included.
