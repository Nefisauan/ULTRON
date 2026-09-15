import Foundation

@MainActor
public struct ReadDashboardTool: UltronTool {
    public let descriptor = UltronToolDescriptor(identifier: "read-dashboard", description: "Read rendered text and tables from the configured dashboard in Safari, then analyze locally when available.", inputRequirements: "Explicit dashboard analysis request; matching front Safari tab", risk: .readOnly)
    private let reader: any DashboardPageReader
    private let analyzer: any DashboardTextAnalyzer

    public init(reader: any DashboardPageReader, analyzer: any DashboardTextAnalyzer) {
        self.reader = reader
        self.analyzer = analyzer
    }

    public func execute(_ intent: UltronIntent, context: UltronToolContext) async throws -> UltronToolResult {
        let url: Foundation.URL
        switch intent {
        case .analyzeDashboard:
            guard let configured = context.dashboard.url else { throw CommandError.dashboardNotConfigured }
            url = configured
        case .analyzePage(let requested): url = try BusinessDashboardConfiguration.validate(requested.absoluteString)
        default: throw CommandError.invalidInput
        }
        try Task.checkCancellation()
        let page = try await reader.read(configuredURL: url)
        try Task.checkCancellation()
        try DashboardPageScope.validate(page.url, against: url)
        context.onProgress?(.thinking)
        let analysis = try await analyzer.analyze(page)
        try Task.checkCancellation()
        return .init(message: analysis.message, pageSnapshot: page)
    }
}
