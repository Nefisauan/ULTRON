public struct VisionAnalysis: Equatable, Sendable {
    public let summary: String
    public let isMock: Bool
    public init(summary: String, isMock: Bool) {
        self.summary = summary
        self.isMock = isMock
    }
}

public protocol VisionAnalyzer: Sendable {
    func analyze(_ context: ScreenContext) async throws -> VisionAnalysis
}

public struct MockVisionAnalyzer: VisionAnalyzer {
    public init() {}
    public func analyze(_ context: ScreenContext) async throws -> VisionAnalysis {
        try Task.checkCancellation()
        return .init(summary: "Screen capture succeeded. This is the development vision pipeline; no live vision provider is configured. I have not analyzed your dashboard data.", isMock: true)
    }
}
