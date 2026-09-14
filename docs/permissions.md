# Permissions and setup

The current app requires no microphone, speech recognition, Accessibility, or notification permission. Screen Recording is requested only after `Look at my screen` or `Capture dashboard`. Normal dashboard analysis reads Safari page text and does not use Screen Recording. Opening a supported file may trigger an ordinary macOS protected-folder access prompt; denying access must not be bypassed. App/URL opening uses NSWorkspace.

To configure TradeScale, open ULTRON Settings and save the dashboard's non-sensitive HTTP/HTTPS URL. The existing dashboard opens in Safari, where authentication remains. Safari must be installed; ULTRON does not silently fall back to a different browser. Clear and save the field to remove the shortcut. Safari, Xcode, or Calculator must be installed to launch them.

Apple voice availability depends on installed system voices. The automatic choice prefers a matching male en-US voice, otherwise the system's language fallback. Add voices through system settings if desired. Voice quality and perceived depth still require a personal audition.

For page reading, allow ULTRON to control Safari when macOS asks (or use System Settings → Privacy & Security → Automation). In Safari Settings → Advanced, enable features for web developers; then choose Develop → Allow JavaScript from Apple Events. These permissions let an authorized local app run JavaScript in Safari. ULTRON uses a fixed read-only extractor scoped to your configured site's origin. It does not change the settings itself. Keep your dashboard tab in front in Safari and retry `Analyze my dashboard` after setup.

On-device analysis requires an Apple Intelligence-capable Mac, macOS 26+, and an available system model. Settings reports availability. If it is unavailable, the app shows an exact page excerpt and provides Review Page Text → Copy for ChatGPT. This copies a prompt; it does not send or submit it. A separate paid API is not configured.

The optional screen pipeline remains one-frame and in-memory. Its analyzer is still a mock. Page text can be analyzed by the separate local model; screenshot pixels cannot yet be interpreted by that model.
