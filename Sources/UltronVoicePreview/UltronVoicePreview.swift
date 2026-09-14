import SwiftUI
import UltronCore
import UltronUI

@main
struct UltronVoicePreview: App {
    var body: some Scene {
        WindowGroup { VoicePreview() }
    }
}

@MainActor
struct VoicePreview: View {
    private let synthesizer: AppleSpeechSynthesizer
    @StateObject private var controller: VoiceController
    @State private var profile = UltronVoiceProfile.ultron
    @State private var text = "Yes? Systems are ready."

    init() {
        let synthesizer = AppleSpeechSynthesizer()
        self.synthesizer = synthesizer
        _controller = StateObject(wrappedValue: VoiceController(synthesizer: synthesizer))
    }

    var body: some View {
        VStack(spacing: 22) {
            Text("U L T R O N").font(.title).tracking(7)
            Text("VOICE LAB · APPLE NATIVE").font(.caption).foregroundStyle(.secondary)
            UltronCoreView(state: controller.state, speechIntensity: controller.speechIntensity,
                           lastWordAt: controller.lastWordAt)
            Text(controller.state.rawValue.uppercased()).font(.caption.monospaced()).foregroundStyle(.cyan)
            TextField("Preview text", text: $text).textFieldStyle(.roundedBorder)
            Picker("Voice", selection: $profile.voiceIdentifier) {
                Text("Automatic · prefer installed male voice").tag(String?.none)
                ForEach(synthesizer.availableVoices) { voice in
                    Text("\(voice.name) · \(voice.language)").tag(Optional(voice.id))
                }
            }
            parameter("Rate", value: $profile.speakingRate, range: 0.5...1.5)
            parameter("Pitch", value: $profile.pitch, range: 0.5...2)
            parameter("Volume", value: $profile.volume, range: 0...1)
            HStack {
                Button("Speak") { controller.speak(text, profile: profile) }.keyboardShortcut(.return)
                Button("Stop") { controller.stop() }
            }
            if let error = controller.errorMessage { Text(error).foregroundStyle(.red) }
            Text("Original voice direction. Native voices approximate the target identity.\nStyle and metallic processing require a future provider. Core pulses follow word timing, not measured audio.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(32).frame(minWidth: 560, minHeight: 650)
        .background(Color(red: 0.025, green: 0.035, blue: 0.065))
        .preferredColorScheme(.dark)
        .onDisappear { controller.stop() }
    }

    private func parameter(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title).frame(width: 60, alignment: .leading)
            Slider(value: value, in: range)
            Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
                .monospacedDigit().frame(width: 45)
        }
    }
}
