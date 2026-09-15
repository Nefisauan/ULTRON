import XCTest
@testable import UltronLink

final class SecureLinkTests: XCTestCase {
    func testPairingKeyFormat() throws {
        XCTAssertEqual(try SecureLink.keyData(String(repeating: "ab", count: 32)).count, 32)
        for value in ["123456", String(repeating: "g", count: 64), String(repeating: "a", count: 63)] {
            XCTAssertThrowsError(try SecureLink.keyData(value))
        }
    }

    @MainActor
    func testAuthenticatedLoopbackAndCancellation() async throws {
        let host = SecureLink()
        let client = SecureLink()
        defer { client.disconnect(); host.disconnect() }
        host.handleCommand = { text in "Received: \(text)" }
        try host.startHosting()
        for _ in 0..<100 where host.port == nil { try await Task.sleep(for: .milliseconds(50)) }
        let port = try XCTUnwrap(host.port)
        try client.connect(host: "127.0.0.1", port: port, pairingKey: host.pairingKey)
        for _ in 0..<200 where !client.isConnected || !host.isConnected { try await Task.sleep(for: .milliseconds(50)) }
        XCTAssertTrue(client.isConnected)
        XCTAssertTrue(host.isConnected)
        guard client.isConnected else { return }
        let result = try await client.request("Hello")
        XCTAssertEqual(result, "Received: Hello")
        do { _ = try await client.request(String(repeating: "a", count: 2001)); XCTFail("Oversized command accepted") } catch {}
        let cancelled = expectation(description: "Host work cancelled")
        host.handleCommand = { _ in
            do { try await Task.sleep(for: .seconds(60)); return "Late" }
            catch { cancelled.fulfill(); throw error }
        }
        let request = Task { try await client.request("Wait") }
        try await Task.sleep(for: .milliseconds(100))
        do { _ = try await client.request("Concurrent"); XCTFail("Concurrent request accepted") } catch {}
        request.cancel()
        do { _ = try await request.value; XCTFail("Cancellation must propagate") }
        catch { XCTAssertTrue(error is CancellationError) }
        await fulfillment(of: [cancelled], timeout: 2)
        host.disconnect()
        XCTAssertTrue(host.pairingKey.isEmpty)
    }

    @MainActor
    func testWrongPairingKeyCannotDispatchCommands() async throws {
        let host = SecureLink()
        let client = SecureLink()
        defer { client.disconnect(); host.disconnect() }
        var received = false
        host.handleCommand = { _ in received = true; return "unexpected" }
        try host.startHosting()
        for _ in 0..<100 where host.port == nil { try await Task.sleep(for: .milliseconds(50)) }
        try client.connect(host: "127.0.0.1", port: try XCTUnwrap(host.port), pairingKey: String(repeating: "01", count: 32))
        try await Task.sleep(for: .seconds(2))
        XCTAssertFalse(client.isConnected)
        do { _ = try await client.request("Hello"); XCTFail() } catch {}
        XCTAssertFalse(received)
    }
}
