import Combine
import UltronCore

@MainActor
final class MacSession: ObservableObject {
    let preferences = LocalPreferences()
    let synthesizer = AppleSpeechSynthesizer()
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
        } catch {
            setupError = "Tool registration failed. Restart ULTRON."
        }
    }

    func loadDashboard() async {
        guard modules.isEmpty else { return }
        do { modules = try await dashboardProvider.modules() }
        catch { setupError = "Dashboard data could not be loaded." }
    }

    func submit(_ text: String) {
        commands.submit(text, context: .init(dashboard: preferences.dashboard),
                        profile: preferences.voiceProfile, speakResponses: preferences.speakResponses)
    }
}
