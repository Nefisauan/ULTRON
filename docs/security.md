# Security model

## Current data flow

Typed text stays in an in-memory conversation limited to 40 entries. A deterministic parser selects vetted local tools. Responses may use Apple's native voice. Dashboard analysis reads bounded page text into an on-device, tool-free Foundation Models session when available. The program has no cloud inference client, analytics, or audio-file retention. User-started microphone dictation is limited to 30 seconds and requires on-device recognition support; recognized text is reviewed before execution. Explicit screenshot commands remain separate and never upload their frames.

User command text is never evaluated as shell or AppleScript. A fixed AppleScript sends a fixed read-only JavaScript extractor to Safari's front tab. The extractor checks the configured origin before touching page text, skips form fields/hidden content, and never reads cookies, storage, or network responses. The decoder checks origin and size again. URL queries/fragments are omitted from the retained source URL. Output travels through a bounded pipe; stderr is discarded, not logged. Apple Events has an 8-second timeout and the process a 12-second timeout. Stop cancels process work and suppresses stale results.

Applications resolve by bundle identifier or exact name in standard Applications directories. Duplicate matches are rejected. No command arguments or shell evaluation are supported. URL tools accept only HTTP/HTTPS addresses with a host and no embedded credentials. Opening a URL explicitly hands it to Safari and may use Safari's existing authenticated session. No credentials are handled by ULTRON. An explicit Analyze URL request sets that request's allowed origin without changing future requests.

Optional hands-free sessions use on-device transcription in 30-second segments for at most ten minutes, including in the background. Leading wake phrases or a twelve-second follow-up window dispatch commands through the existing registry. Recognition pauses during speech/work and stops on errors. The mode is disabled by default and never persisted. Stop cancels it. Microphone/Speech Recognition permissions are requested when the user enables either voice-input mode.

Optional local hosting uses Network.framework TLS-PSK (TLS 1.2, AES-128-GCM/SHA-256) with a fresh random 256-bit session key. It is off by default, expires after 30 minutes, and is stopped by Mac Stop or Quit. Keys are displayed only on request and never logged or persisted. Key possession authorizes commands and text-result access; the UI explains this before hosting. The listener can bind available interfaces, so use a trusted local network; no public port forwarding or discovery is configured. One peer, one active request, bounded frames, duplicate request rejection, handshake/response deadlines, and cancellation are enforced. No plaintext fallback is configured. This PSK cipher does not provide forward secrecy; keys are ephemeral per hosting session. Device-to-device acceptance testing remains pending. Pairing keys must be kept private, including if users copy them to the clipboard.

Remote text follows the same parser/tool registry as local commands. The Mac rejects work while busy. Phone responses are text only; raw page snapshots and audio files are not transferred. iPhone backgrounding disconnects, and transport failures never silently run a remote command locally.

File paths must be explicit. Native file opening resolves symbolic links and permits ordinary folders and a small set of non-executable regular document/image types. Application packages, executable files, and special files are rejected. This is a conservative development policy, not a replacement for OS access controls or safe document handling by the destination app.

The registry blocks requiresConfirmation, sensitive, and prohibited tools. There is no confirmation implementation pretending to authorize them. No destructive actions, email sending, financial transactions, or unrestricted shell tools are registered.

## Retention and logging

UserDefaults stores voice preferences, a response-speech toggle, and a non-sensitive dashboard URL. Screenshots, speech audio, and transcripts are not automatically persisted. The latest text snapshot stays in memory until a new command or Stop; response excerpts remain within the 40-entry conversation. Copy for ChatGPT explicitly writes a bounded prompt to the system clipboard, which may be available to other apps or Universal Clipboard. It does not submit anything. OSLog contains only generic lifecycle events.

The development app is ad-hoc signed and is not an App Sandbox or notarized distribution build. It requests Safari Automation for page reading, Screen Recording only for explicit screenshots, Microphone/Speech Recognition only after enabling a voice-input mode, and Local Network access for an explicitly started connection. It never requests Accessibility access. Review entitlements and distribution signing before release.

Page text is untrusted. The model is instructed to treat it as data and has no tools to execute page instructions. It cannot operate the Mac or reach external services. Local output can still be mistaken; exact page text remains reviewable. No browser permissions or paid services are silently enabled.

## Future boundaries

A future cloud adapter must disclose text/image transmission, store credentials in Keychain, support cancellation, and avoid logging sensitive payloads. Explicit user-triggered vision must capture on demand, retain frames only as long as needed, and never silently upload. Permission handling and confirmation workflows must be centralized before enabling corresponding tools.

The voice identity is original. No actor recordings, reference performances, or cloned voices are included.
