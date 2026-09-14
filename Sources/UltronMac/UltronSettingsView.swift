import SwiftUI
import UltronCore

struct UltronSettingsView: View {
    @ObservedObject var preferences: LocalPreferences
    let voices: [SpeechVoice]
    @State private var dashboardURL = ""
    @State private var status: String?

    var body: some View {
        Form {
            Section("Business") {
                TextField("TradeScale URL", text: $dashboardURL, prompt: Text("https://your-dashboard.example"))
                Text("Stored on this Mac. Use a non-sensitive URL without credentials or access tokens.")
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
            Section("Privacy & devices") {
                Text("Speech uses installed Apple voices. No microphone monitoring, screen capture, or cloud AI is active.")
                Text("Mac ↔ iPhone connection: Not configured.")
                Text("AI, vision, live data, and speech recognition are planned.")
                    .foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).padding().frame(width: 620, height: 650)
            .onAppear { dashboardURL = preferences.dashboard.url?.absoluteString ?? "" }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title).frame(width: 60, alignment: .leading)
            Slider(value: value, in: range)
            Text(value.wrappedValue, format: .number.precision(.fractionLength(2))).monospacedDigit().frame(width: 40)
        }
    }
}
