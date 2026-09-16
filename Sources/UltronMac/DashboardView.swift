import SwiftUI
import UltronCore
import UltronUI
import UltronLink

struct DashboardView: View {
    @ObservedObject var session: MacSession
    @ObservedObject private var commands: CommandController
    @ObservedObject private var voice: VoiceController
    @ObservedObject private var speechInput: MacSpeechInput
    @ObservedObject private var wakeListener: MacWakeListener
    @ObservedObject private var link: SecureLink
    @Environment(\.scenePhase) private var scenePhase
    @State private var listeningOperation: UUID?
    @ObservedObject private var stateMachine: UltronStateMachine
    @State private var input = ""
    @State private var showDeveloper = false
    @State private var showPageReview = false
    @State private var showPairing = false

    init(session: MacSession) {
        self.session = session
        commands = session.commands
        voice = session.voice
        speechInput = session.speechInput
        wakeListener = session.wakeListener
        link = session.link
        stateMachine = session.voice.stateMachine
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(.white.opacity(0.06))
            HStack(alignment: .top, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WORKSPACE").font(.caption2.monospaced()).tracking(3).foregroundStyle(.secondary)
                    ForEach(session.modules) { module in
                        Button { session.submit("Show \(module.id.title)") } label: {
                            moduleCard(module)
                        }.buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                    Text("LOCAL FOUNDATION\nDashboard values are sample data.")
                        .font(.caption2).foregroundStyle(.secondary).lineSpacing(4)
                }.frame(width: 245)
                VStack(spacing: 0) {
                    HStack {
                        Label("APPLE NATIVE VOICE", systemImage: "waveform").font(.caption2.monospaced()).foregroundStyle(.secondary)
                        Spacer()
                        Text("ON DEMAND").font(.caption2.monospaced()).foregroundStyle(.cyan.opacity(0.7))
                    }
                    UltronCoreView(state: stateMachine.state, speechIntensity: voice.speechIntensity, lastWordAt: voice.lastWordAt)
                    Text(stateMachine.state.rawValue.uppercased()).font(.caption.monospaced()).tracking(4).foregroundStyle(stateMachine.state == .error ? .orange : .cyan)
                    Text(statusText).font(.callout).foregroundStyle(.secondary).padding(.top, 10)
                    conversation.padding(.top, 22)
                }.frame(maxWidth: .infinity)
            }.padding(28)
            if let error = session.setupError { Text(error).foregroundStyle(.orange).padding(.horizontal) }
            if showDeveloper { developerPanel }
            if commands.lastResult?.pageSnapshot != nil {
                Button("Review Page Text / Copy for ChatGPT") { showPageReview = true }.padding(.bottom, 10)
            }
            commandBar
        }
        .frame(minWidth: 940, minHeight: 790)
        .background(Color(red: 0.025, green: 0.035, blue: 0.052))
        .preferredColorScheme(.dark)
        .task { await session.loadDashboard() }
        .onChange(of: speechInput.transcript) { input = speechInput.transcript }
        .onChange(of: speechInput.isActive) {
            if speechInput.isActive {
                commands.stop()
                listeningOperation = stateMachine.begin(.listening)
            } else if let operation = listeningOperation {
                stateMachine.transition(to: .idle, for: operation)
                listeningOperation = nil
            }
        }
        .onChange(of: scenePhase) { if scenePhase == .background { speechInput.stop() } }
        .onDisappear { speechInput.stop() }
        .sheet(isPresented: $showPageReview) {
            if let page = commands.lastResult?.pageSnapshot { DashboardPageReview(page: page) }
            else { Text("This reading has been cleared. Read the dashboard again.").padding() }
        }
        .sheet(isPresented: $showPairing) { MacPairingView(link: session.link) }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("ULTRON").font(.system(size: 25, weight: .light, design: .monospaced)).tracking(7)
                Text("PERSONAL OPERATING LAYER").font(.system(size: 9, design: .monospaced)).tracking(2).foregroundStyle(.secondary)
            }
            Spacer()
            Label(link.isHosting ? "HOSTING" : "LOCAL", systemImage: "circle.fill").font(.caption2.monospaced()).foregroundStyle(.cyan)
            Button { showPairing = true } label: { Image(systemName: "iphone") }.help("Connect iPhone")
            Button { showDeveloper.toggle() } label: { Image(systemName: "terminal") }.help("Developer details")
            Button { commands.clearConversation() } label: { Image(systemName: "text.badge.xmark") }.help("Clear conversation and short-term memory")
            SettingsLink { Image(systemName: "slider.horizontal.3") }.help("Settings")
        }.buttonStyle(.plain).padding(.horizontal, 30).padding(.vertical, 24)
    }

    private var statusText: String {
        switch stateMachine.state {
        case .idle: "Ready when you are."
        case .thinking: "Interpreting your command."
        case .acting: "Executing your request."
        case .speaking: "Responding."
        case .error: stateMachine.errorMessage ?? "The request could not be completed."
        case .seeing: "Reading the requested context."
        case .listening: "Listening."
        }
    }

    private func moduleCard(_ module: DashboardModule) -> some View {
        let selected = commands.selectedModule == module.id
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(module.id.title.uppercased()).font(.caption.monospaced()).tracking(1)
                Spacer()
                if module.isSample { Text("SAMPLE").font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary) }
            }
            if selected {
                Text(module.subtitle).font(.caption).foregroundStyle(.secondary)
                ForEach(module.metrics) { metric in
                    HStack {
                        Text(metric.label).foregroundStyle(.secondary)
                        Spacer()
                        Text(metric.value)
                    }.font(.caption)
                }
            }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.cyan.opacity(0.07) : Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).stroke(selected ? .cyan.opacity(0.35) : .white.opacity(0.08), lineWidth: 1) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(module.id.title), \(selected ? "selected" : "select module"), sample data")
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if commands.conversation.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("A direct line to your workspace.").foregroundStyle(.primary)
                            Text("Try “Hey Ultron”, “Open Safari”, or “Show Markets”.\nType a command or use the microphone, then review and send. Dashboard analysis reads Safari page text.")
                                .foregroundStyle(.secondary)
                        }.font(.callout).padding(18)
                    }
                    ForEach(commands.conversation) { entry in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(entry.role == .user ? "YOU" : "ULTRON")
                                .font(.system(size: 9, design: .monospaced)).tracking(2).foregroundStyle(entry.role == .user ? Color.secondary : .cyan)
                            Text(entry.text).font(.callout).textSelection(.enabled)
                        }.frame(maxWidth: .infinity, alignment: .leading).id(entry.id)
                    }
                }.padding(16)
            }
            .onChange(of: commands.conversation.last?.id) {
                if let id = commands.conversation.last?.id { proxy.scrollTo(id, anchor: .bottom) }
            }
        }.frame(minHeight: 100, maxHeight: .infinity)
            .background(.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.07), lineWidth: 1) }
    }

    private var commandBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "chevron.right").foregroundStyle(.cyan)
                TextField("Give ULTRON a command…", text: $input).textFieldStyle(.plain).onSubmit(submit)
                    .accessibilityLabel("Command")
                Button {
                    wakeListener.stop()
                    if speechInput.isActive { speechInput.stop() }
                    else { speechInput.start() }
                } label: { Image(systemName: speechInput.isActive ? "mic.fill" : "mic") }
                    .foregroundStyle(speechInput.isActive ? .orange : .cyan)
                    .accessibilityLabel(speechInput.isActive ? "Finish dictation" : "Dictate command")
                    .help("On-device English dictation. Review the text before sending.")
                Button("Stop") { link.disconnect(); wakeListener.stop(); speechInput.stop(); commands.stop() }.keyboardShortcut(.escape, modifiers: [])
                Button { submit() } label: { Image(systemName: "arrow.up") }
                    .buttonStyle(.borderedProminent).tint(.cyan).disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Run command")
            }.padding(15).background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            if !speechInput.status.isEmpty {
                Text(speechInput.status).font(.caption).foregroundStyle(speechInput.isActive ? .cyan : .secondary)
            }
            HStack {
                Button(wakeListener.isEnabled ? "Disable Hey Ultron" : "Enable Hey Ultron") { session.toggleHandsFree() }
                Text(wakeListener.status).font(.caption2).foregroundStyle(wakeListener.isEnabled ? .cyan : .secondary)
            }
            Text("Open TradeScale · Analyze my dashboard · Show Business / Markets / Projects / Today")
                .font(.caption2).foregroundStyle(.secondary)
        }.padding(.horizontal, 28).padding(.bottom, 22)
    }

    private var developerPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STATE: \(stateMachine.state.rawValue) · Speech: Apple native · Analysis: Apple on-device / page excerpt").font(.caption.monospaced())
            Text("Build \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "development")").font(.caption2.monospaced())
            Text("Tools: \(commands.registry.descriptors.map(\.identifier).joined(separator: ", "))").font(.caption2.monospaced())
            Text("Voice pulses use word timing. Microphone use requires dictation or an enabled Hey Ultron session. Screen Recording is requested only for explicit capture.").font(.caption2).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 28).padding(.bottom, 12)
    }

    private func submit() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let text = input
        input = ""
        session.submit(text)
    }
}
