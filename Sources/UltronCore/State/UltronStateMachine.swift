import Combine
import Foundation

public enum UltronState: String, CaseIterable, Sendable {
    case idle, listening, thinking, seeing, acting, speaking, error
}

public enum UltronActivity: Sendable {
    case listening, thinking, seeing, acting

    var state: UltronState {
        switch self {
        case .listening: .listening
        case .thinking: .thinking
        case .seeing: .seeing
        case .acting: .acting
        }
    }
}

/// One application state, with operation ownership to reject late asynchronous results.
@MainActor
public final class UltronStateMachine: ObservableObject {
    @Published public private(set) var state: UltronState = .idle
    @Published public private(set) var errorMessage: String?
    public private(set) var operationID: UUID?

    public init() {}

    @discardableResult
    public func begin(_ activity: UltronActivity) -> UUID {
        let id = UUID()
        operationID = id
        errorMessage = nil
        state = activity.state
        return id
    }

    public func owns(_ id: UUID) -> Bool { operationID == id }

    @discardableResult
    public func transition(to next: UltronState, for id: UUID) -> Bool {
        guard owns(id), Self.allows(from: state, to: next) else { return false }
        state = next
        if next == .idle { operationID = nil }
        return true
    }

    public func fail(_ message: String, for id: UUID) {
        guard owns(id) else { return }
        errorMessage = message
        state = .error
        operationID = nil
    }

    public func reset() {
        operationID = nil
        errorMessage = nil
        state = .idle
    }

    public static func allows(from: UltronState, to: UltronState) -> Bool {
        if from == to { return true }
        switch (from, to) {
        case (.idle, .listening), (.idle, .thinking), (.idle, .seeing), (.idle, .acting),
             (.listening, .thinking), (.listening, .idle),
             (.thinking, .seeing), (.thinking, .acting), (.thinking, .speaking), (.thinking, .idle),
             (.seeing, .thinking), (.seeing, .idle),
             (.acting, .thinking), (.acting, .speaking), (.acting, .idle),
             (.speaking, .idle), (.error, .idle): return true
        default: return false
        }
    }
}
