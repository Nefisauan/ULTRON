import SwiftUI
import UltronCore
import UltronUI
import UltronLink

@main
struct UltronPhoneApp: App {
    var body: some Scene { WindowGroup { PhoneDashboard() } }
}

@MainActor
private final class PhoneSession: ObservableObject {
    let voice = VoiceController(synthesizer: AppleSpeechSynthesizer())
    let commands: CommandController
    let link = SecureLink()
    init() {
        let registry = UltronToolRegistry()
        try? registry.register(ShowDashboardModuleTool())
        commands = CommandController(voice: voice, registry: registry)
    }
}

private struct PhoneDashboard: View {
    @StateObject private var session = PhoneSession()
    @State private var input = ""
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("ultron.phone.speakResponses") private var speak = true

    var body: some View {
        NavigationStack {
            PhoneContent(commands: session.commands, voice: session.voice, link: session.link, input: $input, speak: speak)
                .navigationTitle("ULTRON")
                .toolbar { Button("Settings", systemImage: "slider.horizontal.3") { showSettings = true } }
                .sheet(isPresented: $showSettings) {
                    NavigationStack {
                        Form {
                            Section("Voice") { Toggle("Speak responses", isOn: $speak) }
                            PhonePairingSection(link: session.link)
                            Section("Available here") {
                                Text("When connected, commands run on your Mac and results return here. Without a connection, greetings and module selection run locally.")
                            }
                        }.navigationTitle("Settings")
                            .toolbar { Button("Done") { showSettings = false } }
                    }
                }
        }.preferredColorScheme(.dark)
            .onChange(of: scenePhase) {
                if scenePhase == .background { session.commands.stop(); session.link.disconnect() }
            }
    }
}

private struct PhoneContent: View {
    @ObservedObject var commands: CommandController
    @ObservedObject var voice: VoiceController
    @ObservedObject var link: SecureLink
    @ObservedObject private var state: UltronStateMachine
    @Binding var input: String
    let speak: Bool

    init(commands: CommandController, voice: VoiceController, link: SecureLink, input: Binding<String>, speak: Bool) {
        self.commands = commands; self.voice = voice; self.state = voice.stateMachine
        self.link = link
        _input = input; self.speak = speak
    }

    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    UltronCoreView(state: state.state, speechIntensity: voice.speechIntensity, lastWordAt: voice.lastWordAt)
                    Text(state.state.rawValue.uppercased()).font(.caption.monospaced()).foregroundStyle(.cyan)
                    Label(link.status, systemImage: "desktopcomputer").font(.caption)
                    Text(link.isConnected ? "Commands run on your connected Mac." : "Try “Hey Ultron” or “Show Markets”. Connect your Mac in Settings for remote commands.")
                        .font(.callout).foregroundStyle(.secondary)
                    ForEach(commands.conversation) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.role == .user ? "YOU" : "ULTRON").font(.caption2.monospaced()).foregroundStyle(.cyan)
                            Text(entry.text).textSelection(.enabled)
                        }
                    }
                }.padding(.horizontal)
            }
            HStack {
                TextField("Give ULTRON a command…", text: $input).onSubmit(submit)
                    .textInputAutocapitalization(.sentences).submitLabel(.send)
                Button("Send", systemImage: "arrow.up", action: submit)
                    .labelStyle(.iconOnly).disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Stop") { commands.stop() }
            }.padding().background(.white.opacity(0.05))
        }.background(Color(red: 0.025, green: 0.035, blue: 0.052))
    }

    private func submit() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        if link.isConnected {
            commands.remoteExecutor = { [link] text in try await link.request(text) }
        } else { commands.remoteExecutor = nil }
        commands.submit(text, context: .init(dashboard: .init()), speakResponses: speak)
    }
}

private struct PhonePairingSection: View {
    @ObservedObject var link: SecureLink
    @State private var host = ""
    @State private var port = ""
    @State private var key = ""
    @State private var error: String?
    var body: some View {
        Section("Mac connection") {
            Text(link.status)
            if link.isConnected { Button("Disconnect") { link.disconnect() } }
            else {
                Text("On your Mac, choose the iPhone icon and start hosting. Enter its address, port, and private pairing key below. Use the same local network.")
                TextField("Mac address", text: $host).textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField("Port", text: $port).keyboardType(.numberPad)
                SecureField("Pairing key", text: $key).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Connect securely") {
                    guard let port = UInt16(port) else { error = "Enter the port shown on your Mac."; return }
                    do { try link.connect(host: host, port: port, pairingKey: key); key = ""; error = nil }
                    catch { self.error = "Check the address, port, and 64-character pairing key." }
                }
            }
            if let error { Text(error).foregroundStyle(.orange) }
        }
    }
}
