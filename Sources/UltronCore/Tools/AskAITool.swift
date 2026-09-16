@MainActor
public struct AskAITool: UltronTool {
    public let descriptor = UltronToolDescriptor(identifier: "ask-ai", description: "Answer a question using bounded conversation context. This tool cannot perform computer actions.", inputRequirements: "A question", risk: .readOnly)
    private let provider: any AIProvider
    public init(provider: any AIProvider) { self.provider = provider }
    public func execute(_ intent: UltronIntent, context: UltronToolContext) async throws -> UltronToolResult {
        guard case .ask(let question) = intent, !question.isEmpty, question.utf8.count <= 4000,
              provider.capabilities.contains(.chat) else { throw CommandError.invalidInput }
        try Task.checkCancellation()
        context.onProgress?(.thinking)
        let response = try await provider.respond(to: .init(question: question, history: context.conversation))
        try Task.checkCancellation()
        guard !response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw CommandError.aiUnavailable }
        return .init(message: (response.isMock ? "Development mock: " : "AI reply — no actions executed:\n") + String(response.text.prefix(6000)))
    }
}
