import Foundation

@MainActor
public protocol ApplicationController {
    func openApplication(named name: String) async throws
}

@MainActor
public protocol ResourceOpener {
    func openURL(_ url: URL) async throws
    func openFile(_ url: URL) async throws
}

@MainActor
public struct OpenApplicationTool: UltronTool {
    public let descriptor = UltronToolDescriptor(identifier: "open-application", description: "Open a configured application.", inputRequirements: "Application name", risk: .lowRisk)
    private let controller: any ApplicationController
    public init(controller: any ApplicationController) { self.controller = controller }
    public func execute(_ intent: UltronIntent, context: UltronToolContext) async throws -> UltronToolResult {
        guard case .openApplication(let name) = intent else { throw CommandError.invalidInput }
        try await controller.openApplication(named: name)
        return .init(message: "Opening \(name) now.")
    }
}

@MainActor
public struct OpenURLTool: UltronTool {
    public let descriptor = UltronToolDescriptor(identifier: "open-url", description: "Open an HTTP or HTTPS address in the configured browser.", inputRequirements: "Web URL or configured dashboard", risk: .lowRisk)
    private let opener: any ResourceOpener
    public init(opener: any ResourceOpener) { self.opener = opener }
    public func execute(_ intent: UltronIntent, context: UltronToolContext) async throws -> UltronToolResult {
        let url: URL
        switch intent {
        case .openDashboard:
            guard let configured = context.dashboard.url else { throw CommandError.dashboardNotConfigured }
            url = configured
        case .openURL(let input): url = try BusinessDashboardConfiguration.validate(input.absoluteString)
        default: throw CommandError.invalidInput
        }
        try await opener.openURL(url)
        return .init(message: "Opening it now.")
    }
}

@MainActor
public struct OpenFileTool: UltronTool {
    public let descriptor = UltronToolDescriptor(identifier: "open-file", description: "Open a supported local document or folder.", inputRequirements: "Explicit absolute file URL", risk: .lowRisk)
    private let opener: any ResourceOpener
    public init(opener: any ResourceOpener) { self.opener = opener }
    public func execute(_ intent: UltronIntent, context: UltronToolContext) async throws -> UltronToolResult {
        guard case .openFile(let url) = intent, url.isFileURL else { throw CommandError.invalidInput }
        try await opener.openFile(url)
        return .init(message: "Opening the file now.")
    }
}

@MainActor
public struct ShowDashboardModuleTool: UltronTool {
    public let descriptor = UltronToolDescriptor(identifier: "show-dashboard-module", description: "Select a dashboard module.", inputRequirements: "Business, Markets, Projects, or Today", risk: .readOnly)
    public init() {}
    public func execute(_ intent: UltronIntent, context: UltronToolContext) async throws -> UltronToolResult {
        guard case .showModule(let module) = intent else { throw CommandError.invalidInput }
        return .init(message: "Showing \(module.title). These are sample data.", selectedModule: module)
    }
}
