@MainActor
public struct CaptureScreenTool: UltronTool {
    public let descriptor = UltronToolDescriptor(
        identifier: "capture-screen", description: "Capture one user-selected display or Safari window and pass it to the local development analyzer.",
        inputRequirements: "Explicit screen or dashboard analysis request; Screen Recording permission and target selection", risk: .readOnly)
    private let permissions: any PermissionService
    private let capturer: any ScreenCapturer
    private let analyzer: any VisionAnalyzer

    public init(permissions: any PermissionService, capturer: any ScreenCapturer, analyzer: any VisionAnalyzer) {
        self.permissions = permissions
        self.capturer = capturer
        self.analyzer = analyzer
    }

    public func execute(_ intent: UltronIntent, context: UltronToolContext) async throws -> UltronToolResult {
        let target: ScreenCaptureTarget
        switch intent {
        case .captureScreen: target = .display
        case .analyzeDashboard: target = .safariWindow
        default: throw CommandError.invalidInput
        }
        try Task.checkCancellation()
        if permissions.screenRecordingStatus != .granted {
            guard permissions.requestScreenRecording() == .granted else { throw CommandError.screenPermissionRequired }
        }
        try Task.checkCancellation()
        // Retained only for this call; no frame is included in the returned result.
        let frame = try await capturer.capture(target)
        try Task.checkCancellation()
        context.onProgress?(.thinking)
        let analysis = try await analyzer.analyze(frame)
        try Task.checkCancellation()
        return .init(message: analysis.summary)
    }
}
