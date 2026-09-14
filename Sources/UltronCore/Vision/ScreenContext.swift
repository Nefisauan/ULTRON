import Foundation

public enum ScreenCaptureTarget: Sendable {
    case display, safariWindow
}

/// Ephemeral frame data. Never add this to conversation history, logs, or preferences.
public struct ScreenContext: Sendable {
    public let imageData: Data
    public let metadata: Metadata

    public struct Metadata: Equatable, Sendable {
        public let timestamp: Date
        public let displayIdentifier: UInt32?
        public let application: String?
        public let windowTitle: String?
        public let width: Int
        public let height: Int

        public init(timestamp: Date = Date(), displayIdentifier: UInt32? = nil,
                    application: String? = nil, windowTitle: String? = nil, width: Int, height: Int) {
            self.timestamp = timestamp
            self.displayIdentifier = displayIdentifier
            self.application = application
            self.windowTitle = windowTitle
            self.width = width
            self.height = height
        }
    }

    public init(imageData: Data, metadata: Metadata) throws {
        guard !imageData.isEmpty, metadata.width > 0, metadata.height > 0 else {
            throw CommandError.captureFailed
        }
        self.imageData = imageData
        self.metadata = metadata
    }
}

@MainActor
public protocol ScreenCapturer {
    func capture(_ target: ScreenCaptureTarget) async throws -> ScreenContext
}
