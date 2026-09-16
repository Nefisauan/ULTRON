import Foundation

/// A follow-up starts when the microphone is ready after the greeting, not while speech is playing.
public struct WakeFollowupWindow: Sendable {
    private var pending = false
    private var deadline: Date?
    public init() {}

    public mutating func arm() { pending = true; deadline = nil }
    public mutating func microphoneReady(at now: Date) {
        guard pending else { return }
        pending = false
        deadline = now.addingTimeInterval(12)
    }
    public func acceptsCommand(at now: Date) -> Bool {
        guard let deadline else { return false }
        return now < deadline
    }
    public mutating func clear() { pending = false; deadline = nil }
}
