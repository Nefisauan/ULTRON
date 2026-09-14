#if os(macOS)
import AppKit
import WebKit
import XCTest
@testable import UltronCore

@MainActor
private final class FixtureNavigation: NSObject, WKNavigationDelegate {
    let loaded: XCTestExpectation
    init(loaded: XCTestExpectation) { self.loaded = loaded }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { loaded.fulfill() }
}

final class SafariExtractionTests: XCTestCase {
    @MainActor
    func testAppleScriptCompilesWithoutExecutingIt() async throws {
        let source = try SafariPageExtraction.appleScript(configuredURL: URL(string: "https://example.com")!)
        let script = try XCTUnwrap(NSAppleScript(source: source))
        var error: NSDictionary?
        XCTAssertTrue(script.compileAndReturnError(&error), "AppleScript syntax failed: \(error?[NSAppleScript.errorNumber] ?? "unknown")")
    }

    @MainActor
    func testExtractionUsesRenderedTextAndRejectsHiddenOrFormContent() async throws {
        let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 700))
        let loaded = expectation(description: "Fixture loaded")
        let delegate = FixtureNavigation(loaded: loaded)
        view.navigationDelegate = delegate
        view.loadHTMLString("""
        <html><head><title>Fixture</title><style>.secret {display:none}</style></head><body>
        <h1>Sales dashboard</h1><p>Leads: 128</p><p class="secret">HIDDEN_SECRET</p>
        <div style="opacity:0"><span>TRANSPARENT_SECRET</span></div>
        <textarea>TEXTAREA_SECRET</textarea><input type="password" value="PASSWORD_SECRET">
        <div contenteditable="true">EDITABLE_SECRET</div><span aria-hidden="true">ARIA_SECRET</span>
        <div data-private>PRIVATE_SECRET</div><table><tr><th>Meetings</th><td>12</td></tr></table>
        <canvas></canvas></body></html>
        """, baseURL: nil)
        await fulfillment(of: [loaded], timeout: 15)
        let originResult = try await view.evaluateJavaScript("location.origin")
        let origin = try XCTUnwrap(originResult as? String)
        let rawResult = try await view.evaluateJavaScript(SafariPageExtraction.javascript(expectedOrigin: origin))
        let raw = try XCTUnwrap(rawResult as? String)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any])
        let text = try XCTUnwrap(object["text"] as? String)
        XCTAssertTrue(text.contains("Leads: 128"))
        XCTAssertFalse(text.contains("SECRET"))
        XCTAssertEqual(object["tables"] as? [[[String]]], [[["Meetings", "12"]]])
        XCTAssertEqual(object["hasVisualContent"] as? Bool, true)
        let mismatchResult = try await view.evaluateJavaScript(SafariPageExtraction.javascript(expectedOrigin: "https://different.test"))
        let mismatch = try XCTUnwrap(mismatchResult as? String)
        XCTAssertEqual(mismatch, #"{"error":"wrongPage"}"#)
    }
}
#endif
