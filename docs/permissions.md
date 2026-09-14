# Permissions and setup

The current app requires no microphone, speech recognition, Screen Recording, Accessibility, or notification permission. Those features are not implemented. Opening a supported file may trigger an ordinary macOS protected-folder access prompt; denying access must not be bypassed. App/URL opening uses NSWorkspace.

To configure TradeScale, open ULTRON Settings and save the dashboard's non-sensitive HTTP/HTTPS URL. Authentication remains in the browser. Clear and save the field to remove the shortcut. Safari, Xcode, or Calculator must be installed to launch them.

Apple voice availability depends on installed system voices. The automatic choice prefers a matching male en-US voice, otherwise the system's language fallback. Add voices through system settings if desired. Voice quality and perceived depth still require a personal audition.

Upcoming screen capture will require an explicit user command, a centralized permission service, and a one-frame in-memory capture pipeline. Microphone and recognition permissions will be introduced only when a real listening feature is ready. Do not pre-request these permissions now.
