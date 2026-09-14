# Original voice identity

Target a deep adult male voice with calm authority, intelligence, restrained confidence, deliberate pacing, concise responses, cinematic presence, and subtle dry personality. This is an original identity: never clone or imitate James Spader or Marvel's Ultron performance. Lower pitch is an approximation, not a guarantee of a particular timbre.

`UltronVoiceProfile` stores voice identifier, language, relative rate, pitch multiplier, volume, style direction, and output processing preference. Apple supports the first five; arbitrary style and metallic processing are unsupported and explicitly reported by capabilities. The adapter clamps numeric values, handles non-finite input, and falls back from an unavailable voice identifier to an installed language voice. It does not add pretend audio effects.

The app injects a `SpeechSynthesizer` into `VoiceController`. Future command and AI coordinators deliver final response text to `speak`. Voice direction does not rewrite content: concision and dry personality belong in future response generation. Never speak a success response before a tool actually succeeds.

Native delegate events are forwarded to the main actor. Start enters speaking, word boundaries pulse the core, and completion or cancellation returns to idle. A request token prevents superseded callbacks from corrupting state. Commands call `transition(to:)` to cancel speech before listening, seeing, thinking, or acting. Empty input produces a useful error. The voice controller and command coordinator share an operation-aware UltronStateMachine. Both the dashboard and menu bar use the same application session.

The reusable core in the dashboard and voice lab uses a decaying word-boundary envelope, not audio amplitude. Its timeline runs at a reduced 15 Hz while idle, uses 30 Hz for activity, pauses while inactive or in error, and respects Reduce Motion. Native speaking/idle transitions were observed in the live UI; perceived timing and voice quality still need an audible review. AVSpeechSynthesizer's direct playback has no measured PCM level in this implementation.

## Neural provider replacement

Implement the same protocol and inject the adapter at app composition. Keep credentials in Keychain and make any cloud text transfer explicit. Emit started only when playback starts, finished only after playback drains, and cancelled when stopped. Marshal callbacks to the main actor. Cancellation must stop both generation and audio playback. Report transport, decoding, and playback errors through failed. No command or AI implementation should import the provider SDK.

For supported providers, translate profile style and processing into actual synthesis/playback controls. PCM playback can emit normalized RMS levels via audioLevel at a bounded rate (approximately 30 Hz). A future audio engine may implement subtle EQ/resonance/metallic processing; it must report the capability only when it actually works. Handle audio session interruptions and route changes when integrating the iPhone app.

## Future interaction

Local wake word → listening → recognized command → acting → verified tool result → spoken response. Explicit screen requests enter seeing, then thinking, then speak the analysis. Typed commands and safe local opening tools are implemented. Wake-word detection, microphone capture, and vision remain planned.
