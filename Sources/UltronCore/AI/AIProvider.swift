import Foundation

public enum AICapability: String, Codable, Sendable { case chat, vision, toolCalling, streaming, structuredOutput }

public struct AIMessage: Codable, Equatable, Sendable {
    public enum Role: String, Codable, Sendable { case user, assistant }
    public let role: Role
    public let text: String
    public init(role: Role, text: String) { self.role = role; self.text = text }
}

public struct AIRequest: Sendable {
    public let question: String
    public let history: [AIMessage]
    public let page: DashboardPage?
    public init(question: String, history: [AIMessage] = [], page: DashboardPage? = nil) {
        self.question = question; self.history = history; self.page = page
    }
}

public struct AIResponse: Sendable {
    public let text: String
    public let isMock: Bool
    public init(text: String, isMock: Bool = false) { self.text = text; self.isMock = isMock }
}

@MainActor
public protocol AIProvider {
    var name: String { get }
    var capabilities: Set<AICapability> { get }
    func respond(to request: AIRequest) async throws -> AIResponse
}

@MainActor
public struct MockAIProvider: AIProvider {
    public let name = "Development mock"
    public let capabilities: Set<AICapability> = [.chat]
    public init() {}
    public func respond(to request: AIRequest) async throws -> AIResponse {
        try Task.checkCancellation()
        return .init(text: "The development AI pipeline received your question. No live model or tools were used.", isMock: true)
    }
}
