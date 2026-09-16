# Access and voice controls — 0.6.0

ULTRON acts on explicit requests through its tool registry. It does not have unrestricted control of every application. No arbitrary shell, destructive operations, message sending, purchases, or credential extraction is implemented.

## Mac requests

- `Open Notes`, `Open Slack`, or another exact installed application name. Searches Applications, System Applications, and your Applications folder. Duplicate names require a bundle identifier. Opening an app does not give ULTRON access to its contents.
- `Open https://example.com` opens Safari using your existing browser session.
- `Analyze https://example.com` reads bounded rendered text from Safari's front tab only when its origin matches the explicit URL. It does not navigate or inspect other tabs. `Analyze my dashboard` uses the saved dashboard origin.
- `Open File /absolute/path/to/document.pdf` opens a supported document or folder. File interpretation and arbitrary app UI control are not implemented.

## Voice

The microphone button starts English on-device dictation for up to 30 seconds. Review the text and press Return to execute it.

`Enable Hey Ultron` starts an opt-in session lasting at most ten minutes. Say `Hey Ultron, open Safari` in one utterance. A leading wake phrase is required, followed by a 1.2-second stable transcription interval. `Hey Ultron` alone returns `Yes?` and permits a follow-up command for twelve seconds. Recognition pauses during command work and spoken responses. Errors end the session without a cloud fallback. This uses speech transcription rather than a dedicated low-power wake-word model; accuracy and latency need live testing.

Hands-free can use the microphone in the background while ULTRON is running. It cannot launch a closed app or wake a sleeping Mac. It never starts automatically on launch. Stop disables both microphone modes. Mac permissions remain required. There is no clap detector.

Unlike reviewed dictation, hands-free commands execute automatically through the same deterministic parser and risk-gated registry. They cannot bypass unsupported or higher-risk actions. Audio is not saved.

## iPhone

Open `ULTRON.xcodeproj`, select `UltronPhone`, and choose an iPhone simulator. The project is generated with `python3 Scripts/generate-ios-project.py` without external dependencies. Physical-device installation requires your Apple signing team.

The companion shares the animated core, parser, and native speech. Greetings and module selection work locally. An optional encrypted connection can send typed commands to your Mac and speak the returned text on iPhone. Only the Mac's existing supported tools can execute. This does not mirror the desktop or synchronize files.

On Mac, click the iPhone icon and choose Start local hosting. Enter the displayed Mac address, port, and private 64-character pairing key in iPhone Settings. Keep the key private; do not post it in chat. Use the same trusted local network and approve Local Network access if macOS/iOS asks. Hosting lasts at most 30 minutes and accepts one device at a time. Anyone with the key and network reachability can run supported commands and receive results during that session. Stopping hosting revokes it; the next session generates a fresh random key. No keys are persisted. The iPhone disconnects when backgrounded.

The channel uses Apple's Network framework with TLS 1.2 and an authenticated PSK AES-GCM cipher. There is no plaintext fallback or cloud relay. Connection, cancellation, incorrect-key rejection, and command-size bounds are tested on loopback; physical iPhone operation and OS Local Network permission flows still require acceptance testing. Mac Stop also disconnects the remote session. Cancelling a command cannot undo an already-opened app or URL.

The local dashboard model now selects short observations that must match the extracted text verbatim. Unsupported generated claims are discarded; if no observation validates, the original page excerpt is shown. This is a grounded page review, not an assessment of charts or trends. Copy for ChatGPT remains available for deeper analysis.

## Safari favorites

Use `Open Favorite [exact saved title]` to open an HTTP(S) favorite in Safari. Matching ignores case and searches the standard Safari Favorites (`BookmarksBar`) folder and its subfolders. Other bookmarks and browsing history are not searched. Duplicate titles with distinct URLs are rejected; use an explicit URL or rename them in Safari.

The Mac reads its local bookmark plist only for this command, with bounded input and traversal. It does not persist or upload the bookmark collection. macOS privacy restrictions may deny this read; the command then explains that you can use the web URL instead. Custom Favorites folders and Safari profile-specific bookmark stores are not supported. This integration uses Safari's local data format and may need adaptation if Apple changes it. Live access on the user's Safari profile remains unverified.

## Live hands-free acceptance sequence

1. Enable Hey Ultron in the running Mac app. Approve Microphone and Speech Recognition if you want to allow recording. Wait for the status to say Listening.
2. Say “Hey Ultron,” then wait for “Yes?” and the listening status. Say “Open TradeScale.” The 12-second follow-up window begins when the microphone is recording after the reply, not during speech or permission setup.
3. After the action finishes, say “Hey Ultron, analyze my dashboard.” Confirm the selected Safari tab is the dashboard.
4. During speech, click Stop or press Escape. Confirm playback stops and Hands-free is off. Spoken interruption during ULTRON playback is not supported because recognition is paused to avoid self-triggering.
5. Enable again, say “Hey Ultron,” wait more than 12 seconds after listening resumes, then say a command without the wake phrase. It must not run. Repeat with the wake phrase to confirm recovery.

Record recognition mistakes, missed wakes, accidental activation, and response delay. No passing live-audio result is assumed from automated tests. The app must be running; clap activation and waking a sleeping Mac are not implemented.

## Dashboard follow-up questions

After `Analyze my dashboard`, ask `What does that mean?` or `Ask what information is missing from this reading?`. The local model receives up to 4,000 UTF-8 bytes of saved page text with its timestamp. It does not reread Safari. The saved page remains available only for consecutive questions, for five minutes, and is erased by Clear Conversation. Conversation messages may still contain earlier quoted observations until cleared.

Follow-up answers are model interpretations, not the source-verified excerpts returned by the initial reader. Check their claims against the page; charts, causes, and trends may be unavailable. No cloud provider is configured.
