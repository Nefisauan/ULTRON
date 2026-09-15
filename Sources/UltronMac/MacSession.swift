import Combine
import UltronCore
import UltronLink

@MainActor
final class MacSession: ObservableObject {
    let preferences = LocalPreferences()
    let permissions = MacPermissionService()
    let synthesizer = AppleSpeechSynthesizer()
    let speechInput = MacSpeechInput()
    let wakeListener = MacWakeListener()
    let link = SecureLink()
    let voice: VoiceController
    let commands: CommandController
    @Published private(set) var modules: [DashboardModule] = []
    @Published private(set) var setupError: String?
    private let dashboardProvider: any DashboardProvider = MockDashboardProvider()

    init() {
        voice = VoiceController(synthesizer: synthesizer)
        let registry = UltronToolRegistry()
        let system = MacSystemController()
        commands = CommandController(voice: voice, registry: registry)
        do {
            try registry.register(OpenApplicationTool(controller: system))
            try registry.register(OpenURLTool(opener: system))
            try registry.register(OpenFileTool(opener: system))
            try registry.register(ShowDashboardModuleTool())
            try registry.register(ReadDashboardTool(reader: SafariDashboardReader(), analyzer: OnDeviceDashboardAnalyzer()))
            try registry.register(CaptureScreenTool(permissions: permissions, capturer: MacScreenCapturer(), analyzer: MockVisionAnalyzer()))
        } catch {
            setupError = "Tool registration failed. Restart ULTRON."
        }
        link.handleCommand = { [weak self] text in
            guard let self else { throw LinkError.unavailable }
            guard !self.commands.isExecuting, self.voice.stateMachine.state != .speaking,
                  !self.speechInput.isActive else { return "The Mac is busy. Try again shortly." }
            let work = self.commands.submit(text, context: .init(dashboard: self.preferences.dashboard),
                                            profile: self.preferences.voiceProfile, speakResponses: false)
            let id = self.commands.lastCommand?.id
            return try await withTaskCancellationHandler {
                await work.value
                try Task.checkCancellation()
                guard self.commands.lastCommand?.id == id else { throw CancellationError() }
                return self.commands.conversation.last?.text ?? "The command ended without a response."
            } onCancel: {
                Task { @MainActor [weak self] in
                    guard let self, self.commands.lastCommand?.id == id else { return }
                    self.commands.stop()
                }
            }
        }
    }

    func loadDashboard() async {
        guard modules.isEmpty else { return }
        do { modules = try await dashboardProvider.modules() }
        catch { setupError = "Dashboard data could not be loaded." }
    }

    func submit(_ text: String) {
        speechInput.stop()
        commands.submit(text, context: .init(dashboard: preferences.dashboard),
                        profile: preferences.voiceProfile, speakResponses: preferences.speakResponses)
    }

    func toggleHandsFree() {
        speechInput.stop()
        commands.stop()
        if wakeListener.isEnabled { wakeListener.stop() }
        else { wakeListener.start(state: voice.stateMachine) { [weak self] in self?.submit($0) } }
    }
}
