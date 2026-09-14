import Foundation

public struct UltronCommand: Identifiable, Sendable {
    public let id: UUID
    public let text: String
    public let createdAt: Date

    public init(text: String) {
        id = UUID()
        self.text = text
        createdAt = Date()
    }
}

public enum UltronIntent: Equatable, Sendable {
    case greet
    case openApplication(String)
    case openDashboard
    case openURL(URL)
    case openFile(URL)
    case showModule(DashboardModuleID)
    case captureScreen

    public var toolIdentifier: String? {
        switch self {
        case .greet: nil
        case .openApplication: "open-application"
        case .openDashboard, .openURL: "open-url"
        case .openFile: "open-file"
        case .showModule: "show-dashboard-module"
        case .captureScreen: "capture-screen"
        }
    }
}

public enum CommandError: LocalizedError, Equatable {
    case empty
    case unsupported
    case invalidURL
    case invalidFilePath
    case dashboardNotConfigured
    case toolUnavailable(String)
    case duplicateTool(String)
    case riskNotAllowed
    case invalidInput
    case applicationNotFound(String)
    case launchFailed
    case fileNotFound
    case unsupportedFile

    public var errorDescription: String? {
        switch self {
        case .empty: "Enter a command first."
        case .unsupported: "That command is not supported yet. Try Open Safari, Open TradeScale, Show Business, or Show Markets."
        case .invalidURL: "Use an HTTP or HTTPS URL with a host and no embedded credentials."
        case .invalidFilePath: "Use an absolute file path after Open File."
        case .dashboardNotConfigured: "Add your TradeScale dashboard URL in Settings first."
        case .toolUnavailable(let id): id == "capture-screen"
            ? "Screen capture is not implemented yet. ULTRON has not captured your screen."
            : "This tool is not available on this device."
        case .duplicateTool(let id): "A tool named \(id) is already registered."
        case .riskNotAllowed: "This action requires a safety workflow that is not enabled in Phase 1."
        case .invalidInput: "The tool received an unsupported input."
        case .applicationNotFound(let name): "\(name) could not be found in ULTRON’s configured applications on this Mac."
        case .launchFailed: "macOS could not open the requested item."
        case .fileNotFound: "That file could not be found on this Mac."
        case .unsupportedFile: "Phase 1 can open folders, plain text, PDF, and common image files. Executables and other file types are not supported."
        }
    }
}
