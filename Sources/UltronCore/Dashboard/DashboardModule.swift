import Foundation

public enum DashboardModuleID: String, CaseIterable, Identifiable, Sendable {
    case business, markets, projects, today
    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
}

public struct DashboardMetric: Identifiable, Equatable, Sendable {
    public let label: String
    public let value: String
    public var id: String { label }

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

public struct DashboardModule: Identifiable, Equatable, Sendable {
    public let id: DashboardModuleID
    public let subtitle: String
    public let metrics: [DashboardMetric]
    public let isSample: Bool

    public init(id: DashboardModuleID, subtitle: String, metrics: [DashboardMetric], isSample: Bool) {
        self.id = id
        self.subtitle = subtitle
        self.metrics = metrics
        self.isSample = isSample
    }
}

public protocol DashboardProvider: Sendable {
    func modules() async throws -> [DashboardModule]
}

public struct MockDashboardProvider: DashboardProvider {
    public init() {}
    public func modules() async throws -> [DashboardModule] {
        [
            .init(id: .business, subtitle: "Pipeline overview", metrics: [
                .init(label: "Leads", value: "128"), .init(label: "Calls", value: "46"),
                .init(label: "Meetings", value: "12"), .init(label: "Conversion", value: "9.4%")], isSample: true),
            .init(id: .markets, subtitle: "Illustrative snapshot · not live", metrics: [
                .init(label: "NQ", value: "+0.42%"), .init(label: "ES", value: "+0.18%")], isSample: true),
            .init(id: .projects, subtitle: "Example workspace", metrics: [
                .init(label: "TradeScale", value: "Planning"), .init(label: "Anchor", value: "Planning"),
                .init(label: "Outdoor AI", value: "Planning"), .init(label: "ULTRON", value: "Foundation")], isSample: true),
            .init(id: .today, subtitle: "Example priorities", metrics: [
                .init(label: "09:30", value: "Pipeline review"), .init(label: "Priority", value: "Review project milestones")], isSample: true)
        ]
    }
}
