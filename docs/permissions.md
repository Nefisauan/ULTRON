# Permissions and setup

The current app requires no microphone, speech recognition, Accessibility, or notification permission. Screen Recording is requested only after an explicit `Look at my screen` or `Analyze my dashboard` command. Opening a supported file may trigger an ordinary macOS protected-folder access prompt; denying access must not be bypassed. App/URL opening uses NSWorkspace.

To configure TradeScale, open ULTRON Settings and save the dashboard's non-sensitive HTTP/HTTPS URL. The existing dashboard opens in Safari, where authentication remains. Safari must be installed; ULTRON does not silently fall back to a different browser. Clear and save the field to remove the shortcut. Safari, Xcode, or Calculator must be installed to launch them.

Apple voice availability depends on installed system voices. The automatic choice prefers a matching male en-US voice, otherwise the system's language fallback. Add voices through system settings if desired. Voice quality and perceived depth still require a personal audition.

Screen capture uses a centralized permission service and one-frame in-memory pipeline. For a display request, select a display. For dashboard analysis, open the dashboard in a visible Safari window and select that window. The current analyzer is a mock and does not interpret business data. Microphone and recognition permissions will be introduced only when a real listening feature is ready. Do not pre-request these permissions now.
