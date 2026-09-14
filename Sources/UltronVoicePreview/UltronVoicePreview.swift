import SwiftUI
import UltronCore

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
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        let synthesizer = AppleSpeechSynthesizer()
        self.synthesizer = synthesizer
        _controller = StateObject(wrappedValue: VoiceController(synthesizer: synthesizer))
    }

    var body: some View {
        VStack(spacing: 22) {
            Text("U L T R O N").font(.title).tracking(7)
            Text("VOICE LAB · APPLE NATIVE").font(.caption).foregroundStyle(.secondary)
            TimelineView(.animation(minimumInterval: 1 / 30,
                                    paused: controller.state != .speaking || scenePhase != .active || reduceMotion)) { context in
                let elapsed = context.date.timeIntervalSince(controller.lastWordAt)
                let energy = controller.state == .speaking ? max(controller.speechIntensity, max(0, 1 - elapsed * 3)) : 0
                ZStack {
                    ForEach(0..<4) { index in
                        Circle().stroke(.cyan.opacity(0.2 + Double(index) * 0.15), lineWidth: index == 3 ? 3 : 1)
                            .frame(width: CGFloat(110 + index * 32), height: CGFloat(110 + index * 32))
                            .scaleEffect(reduceMotion ? 1 : 1 + energy * 0.06)
                    }
                    Circle().fill(.cyan.opacity(0.25 + energy * 0.4)).frame(width: 80, height: 80)
                        .blur(radius: 12)
                }.frame(height: 235)
            }
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
