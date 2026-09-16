import Foundation

@MainActor
public protocol ConversationMemory {
    var messages: [AIMessage] { get }
    func append(_ message: AIMessage)
    func clear()
}

/// Ephemeral, bounded history. An alternative store can be injected without changing command execution.
@MainActor
public final class InMemoryConversationMemory: ConversationMemory {
    public private(set) var messages: [AIMessage] = []
    private let capacity: Int
    public init(capacity: Int = 12) { self.capacity = min(40, max(1, capacity)) }
    public func append(_ message: AIMessage) {
        messages.append(.init(role: message.role, text: String(message.text.prefix(1500))))
        if messages.count > capacity { messages.removeFirst(messages.count - capacity) }
    }
    public func clear() { messages.removeAll() }
}
