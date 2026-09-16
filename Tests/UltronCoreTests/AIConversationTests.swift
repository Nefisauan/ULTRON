import XCTest
@testable import UltronCore

@MainActor
private final class QuestionProvider: AIProvider {
    let name = "Test"
    let capabilities: Set<AICapability> = [.chat]
    var requests: [AIRequest] = []
    func respond(to request: AIRequest) async throws -> AIResponse {
        requests.append(request)
        return .init(text: "Test answer")
    }
}

final class AIConversationTests: XCTestCase {
    func testQuestionsDoNotReplaceExplicitActions() throws {
        let parser = CommandParser()
        XCTAssertEqual(try parser.parse("What are we seeing?"), .analyzeDashboard)
        XCTAssertEqual(try parser.parse("Open Calculator"), .openApplication("Calculator"))
        XCTAssertEqual(try parser.parse("How does memory work?"), .ask("How does memory work?"))
        XCTAssertEqual(try parser.parse("Ask summarize our conversation"), .ask("summarize our conversation"))
        XCTAssertThrowsError(try parser.parse("delete all files"))
    }

    @MainActor
    func testMemoryIsBoundedAndCanBeErased() {
        let memory = InMemoryConversationMemory(capacity: 2)
        memory.append(.init(role: .user, text: "First"))
        memory.append(.init(role: .assistant, text: "Second"))
        memory.append(.init(role: .user, text: String(repeating: "a", count: 2000)))
        XCTAssertEqual(memory.messages.count, 2)
        XCTAssertEqual(memory.messages.first?.text, "Second")
        XCTAssertEqual(memory.messages.last?.text.count, 1500)
        memory.clear()
        XCTAssertTrue(memory.messages.isEmpty)
    }

    @MainActor
    func testQuestionToolPassesHistoryAndRejectsOversizedInput() async throws {
        let provider = QuestionProvider()
        let tool = AskAITool(provider: provider)
        let history = [AIMessage(role: .user, text: "Previous question")]
        let context = UltronToolContext(dashboard: .init(), conversation: history)
        let result = try await tool.execute(.ask("Explain that"), context: context)
        XCTAssertTrue(result.message.contains("no actions executed"))
        XCTAssertEqual(provider.requests.first?.history, history)
        do {
            _ = try await tool.execute(.ask(String(repeating: "a", count: 4001)), context: context)
            XCTFail("Oversized question accepted")
        } catch { XCTAssertEqual(provider.requests.count, 1) }
        let mock = try await AskAITool(provider: MockAIProvider()).execute(.ask("Hello"), context: context)
        XCTAssertTrue(mock.message.hasPrefix("Development mock:"))
    }
}
