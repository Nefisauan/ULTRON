import SwiftUI
import UltronCore

struct UltronSettingsView: View {
    @ObservedObject var preferences: LocalPreferences
    let voices: [SpeechVoice]
    @ObservedObject var permissions: MacPermissionService
    @State private var dashboardURL = ""
    @State private var status: String?

    var body: some View {
        Form {
            Section("Business") {
                TextField("TradeScale URL", text: $dashboardURL, prompt: Text("https://your-dashboard.example"))
                Text("Your existing dashboard opens in Safari. Stored on this Mac; omit credentials and access tokens.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Save dashboard URL") {
                    do {
                        try preferences.saveDashboard(dashboardURL)
                        status = dashboardURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Dashboard shortcut cleared." : "Dashboard URL saved."
                    } catch { status = error.localizedDescription }
                }
                if let status { Text(status).font(.caption) }
                if let warning = preferences.configurationWarning { Text(warning).foregroundStyle(.orange) }
            }
            Section("Voice") {
                Toggle("Speak successful responses", isOn: $preferences.speakResponses)
                Picker("Voice", selection: $preferences.voiceProfile.voiceIdentifier) {
                    Text("Automatic · prefer male voice").tag(String?.none)
                    if let id = preferences.voiceProfile.voiceIdentifier, !voices.contains(where: { $0.id == id }) {
                        Text("Saved voice unavailable · using fallback").tag(Optional(id))
                    }
                    ForEach(voices) { voice in
                        Text("\(voice.name) · \(voice.language)").tag(Optional(voice.id))
                    }
                }
                slider("Rate", value: $preferences.voiceProfile.speakingRate, range: 0.5...1.5)
                slider("Pitch", value: $preferences.voiceProfile.pitch, range: 0.5...2)
                slider("Volume", value: $preferences.voiceProfile.volume, range: 0...1)
                Text("Original voice direction. Neural style and metallic processing are planned. Changes apply to the next response.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Dashboard reading") {
                Text("“Analyze my dashboard” reads rendered text from the front Safari tab on your configured dashboard's site.")
                Text(OnDeviceDashboardAnalyzer.availabilityDescription).font(.caption)
                Text("No paid API is configured. Analysis uses Apple's on-device model when available. Otherwise, review the page text and copy it into your existing ChatGPT account.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Requires permission to automate Safari and Safari's Develop → Allow JavaScript from Apple Events setting. ULTRON does not change these permissions automatically.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Optional screen capture") {
                Text("Screen Recording: \(permissions.status == .granted ? "Granted" : "Not granted")")
                Button("Refresh permission status") { permissions.refresh() }
                Text("Use “Capture dashboard” to select a Safari window, or “Look at my screen” for a display. This separate capture path still uses a mock vision analyzer. Normal dashboard analysis reads page text instead.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Privacy & devices") {
                Text("Speech uses installed Apple voices. The microphone button starts on-device English dictation for review. Enable Hey Ultron starts an optional 10-minute hands-free session, including while the app is in the background. Wake commands execute through the same restricted tool registry. Stop ends both microphone modes. No cloud AI is configured.")
                Text("Use the iPhone icon in the main window to start an encrypted local connection. Hosting is off by default.")
                Text("Hands-free requires this app to be running. It cannot launch a closed app or wake a sleeping Mac. Clap activation and live AI vision are not implemented.")
                    .foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).padding().frame(width: 620, height: 650)
            .onAppear {
                dashboardURL = preferences.dashboard.url?.absoluteString ?? ""
                permissions.refresh()
            }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title).frame(width: 60, alignment: .leading)
            Slider(value: value, in: range)
            Text(value.wrappedValue, format: .number.precision(.fractionLength(2))).monospacedDigit().frame(width: 40)
        }
    }
}
