import Foundation

public enum UltronActionRisk: String, CaseIterable, Sendable {
    case readOnly, lowRisk, requiresConfirmation, sensitive, prohibited
    public var allowedInPhaseOne: Bool { self == .readOnly || self == .lowRisk }
}

public struct UltronToolDescriptor: Equatable, Sendable {
    public let identifier: String
    public let description: String
    public let inputRequirements: String
    public let risk: UltronActionRisk

    public init(identifier: String, description: String, inputRequirements: String, risk: UltronActionRisk) {
        self.identifier = identifier
        self.description = description
        self.inputRequirements = inputRequirements
        self.risk = risk
    }
}

public struct UltronToolContext: Sendable {
    public let dashboard: BusinessDashboardConfiguration
    public let conversation: [AIMessage]
    public let onProgress: (@MainActor @Sendable (UltronActivity) -> Void)?
    public init(dashboard: BusinessDashboardConfiguration,
                conversation: [AIMessage] = [],
                onProgress: (@MainActor @Sendable (UltronActivity) -> Void)? = nil) {
        self.dashboard = dashboard
        self.conversation = conversation
        self.onProgress = onProgress
    }
}

public struct UltronToolResult: Equatable, Sendable {
    public let message: String
    public let selectedModule: DashboardModuleID?
    public let pageSnapshot: DashboardPage?

    public init(message: String, selectedModule: DashboardModuleID? = nil, pageSnapshot: DashboardPage? = nil) {
        self.message = message
        self.selectedModule = selectedModule
        self.pageSnapshot = pageSnapshot
    }
}

@MainActor
public protocol UltronTool {
    var descriptor: UltronToolDescriptor { get }
    func execute(_ intent: UltronIntent, context: UltronToolContext) async throws -> UltronToolResult
}

@MainActor
public final class UltronToolRegistry {
    private var tools: [String: any UltronTool] = [:]
    public var descriptors: [UltronToolDescriptor] { tools.values.map(\.descriptor).sorted { $0.identifier < $1.identifier } }

    public init() {}

    public func register(_ tool: any UltronTool) throws {
        guard tools[tool.descriptor.identifier] == nil else {
            throw CommandError.duplicateTool(tool.descriptor.identifier)
        }
        tools[tool.descriptor.identifier] = tool
    }

    public func execute(_ intent: UltronIntent, context: UltronToolContext) async throws -> UltronToolResult {
        try Task.checkCancellation()
        guard let id = intent.toolIdentifier else { throw CommandError.invalidInput }
        guard let tool = tools[id] else { throw CommandError.toolUnavailable(id) }
        guard tool.descriptor.risk.allowedInPhaseOne else { throw CommandError.riskNotAllowed }
        return try await tool.execute(intent, context: context)
    }
}
