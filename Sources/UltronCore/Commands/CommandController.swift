import Combine
import Foundation
import OSLog

public struct ConversationEntry: Identifiable, Sendable {
    public enum Role: String, Sendable { case user, ultron }
    public let id = UUID()
    public let role: Role
    public let text: String
}

/// Owns command work; speech and the UI share its state machine through the injected voice controller.
@MainActor
public final class CommandController: ObservableObject {
    @Published public private(set) var conversation: [ConversationEntry] = []
    @Published public private(set) var selectedModule: DashboardModuleID = .business
    @Published public private(set) var isExecuting = false
    @Published public private(set) var lastCommand: UltronCommand?
    @Published public private(set) var lastResult: UltronToolResult?
    public let voice: VoiceController
    public let registry: UltronToolRegistry
    public var remoteExecutor: (@MainActor @Sendable (String) async throws -> String)?
    public var stateMachine: UltronStateMachine { voice.stateMachine }
    private let parser = CommandParser()
    private let memory: any ConversationMemory
    private var task: Task<Void, Never>?
    private let logger = Logger(subsystem: "dev.ultron", category: "commands")

    public init(voice: VoiceController, registry: UltronToolRegistry, memory: (any ConversationMemory)? = nil) {
        self.voice = voice
        self.registry = registry
        self.memory = memory ?? InMemoryConversationMemory()
    }

    @discardableResult
    public func submit(_ text: String, context: UltronToolContext,
                       profile: UltronVoiceProfile = .ultron, speakResponses: Bool = true) -> Task<Void, Never> {
        task?.cancel()
        voice.stop()
        let operation = stateMachine.begin(.thinking)
        let command = UltronCommand(text: text)
        lastCommand = command
        lastResult = nil
        isExecuting = true
        let history = memory.messages
        append(.user, text)
        logger.info("Command started") // Never log command text, URLs, or file paths.
        let remoteExecutor = self.remoteExecutor
        let next = Task { [weak self] in
            guard let self else { return }
            do {
                try Task.checkCancellation()
                let result: UltronToolResult
                if let remoteExecutor {
                    result = .init(message: try await remoteExecutor(command.text))
                } else if try parser.parse(command.text) == .greet {
                    result = .init(message: "Yes?")
                } else {
                    let intent = try parser.parse(command.text)
                    let isReading = intent.toolIdentifier == "capture-screen" || intent.toolIdentifier == "read-dashboard"
                    stateMachine.transition(to: isReading ? .seeing : intent.toolIdentifier == "ask-ai" ? .thinking : .acting, for: operation)
                    let toolContext = UltronToolContext(dashboard: context.dashboard, conversation: history) { [weak self] activity in
                        self?.stateMachine.transition(to: activity.state, for: operation)
                    }
                    result = try await registry.execute(intent, context: toolContext)
                }
                try Task.checkCancellation()
                guard stateMachine.owns(operation) else { return }
                lastResult = result
                if let module = result.selectedModule { selectedModule = module }
                append(.ultron, result.message)
                isExecuting = false
                logger.info("Command completed")
                if speakResponses {
                    voice.speak(result.message, profile: profile, operationID: operation)
                } else {
                    stateMachine.transition(to: .idle, for: operation)
                }
            } catch is CancellationError {
                guard stateMachine.owns(operation) else { return }
                isExecuting = false
                stateMachine.reset()
            } catch {
                guard stateMachine.owns(operation) else { return }
                // Unknown provider/system errors can contain private resource identifiers.
                let message = (error as? CommandError)?.errorDescription ?? "The action could not be completed."
                append(.ultron, message)
                isExecuting = false
                stateMachine.fail(message, for: operation)
                logger.error("Command failed")
            }
        }
        task = next
        return next
    }

    public func stop() {
        task?.cancel()
        task = nil
        isExecuting = false
        lastResult = nil
        voice.stop()
    }

    private func append(_ role: ConversationEntry.Role, _ text: String) {
        memory.append(.init(role: role == .user ? .user : .assistant, text: text))
        conversation.append(.init(role: role, text: text))
        if conversation.count > 40 { conversation.removeFirst(conversation.count - 40) }
    }

    public func clearConversation() {
        stop()
        conversation.removeAll()
        memory.clear()
        lastCommand = nil
    }
}
