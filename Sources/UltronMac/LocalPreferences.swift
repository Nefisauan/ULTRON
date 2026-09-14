import Combine
import Foundation
import UltronCore

@MainActor
final class LocalPreferences: ObservableObject {
    private let defaults: UserDefaults
    @Published var voiceProfile: UltronVoiceProfile {
        didSet { if let data = try? JSONEncoder().encode(voiceProfile) { defaults.set(data, forKey: "ultron.voiceProfile") } }
    }
    @Published var speakResponses: Bool {
        didSet { defaults.set(speakResponses, forKey: "ultron.speakResponses") }
    }
    @Published private(set) var dashboard: BusinessDashboardConfiguration
    @Published private(set) var configurationWarning: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        voiceProfile = defaults.data(forKey: "ultron.voiceProfile")
            .flatMap { try? JSONDecoder().decode(UltronVoiceProfile.self, from: $0) } ?? .ultron
        speakResponses = defaults.object(forKey: "ultron.speakResponses") as? Bool ?? true
        do {
            dashboard = try BusinessDashboardConfiguration(urlString: defaults.string(forKey: "ultron.tradeScaleURL") ?? "")
        } catch {
            dashboard = BusinessDashboardConfiguration()
            configurationWarning = "The saved dashboard URL is invalid. Replace it in Settings."
        }
    }

    func saveDashboard(_ text: String) throws {
        let next = try BusinessDashboardConfiguration(urlString: text)
        defaults.set(next.url?.absoluteString, forKey: "ultron.tradeScaleURL")
        dashboard = next
        configurationWarning = nil
    }
}
