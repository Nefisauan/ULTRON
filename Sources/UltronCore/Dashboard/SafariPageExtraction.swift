import Foundation

/// Fixed, read-only JavaScript. No page navigation, form values, cookies, storage, or network access.
public enum SafariPageExtraction {
    public static func appleScript(configuredURL: URL) throws -> String {
        let javascript = try javascript(expectedOrigin: DashboardPageScope.origin(of: configuredURL))
        let literal = javascript.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return #"""
        with timeout of 8 seconds
            try
                tell application id "com.apple.Safari"
                    if (count of windows) is 0 then return "{\"error\":\"noWindow\"}"
                    return do JavaScript "\#(literal)" in current tab of front window
                end tell
            on error messageText number errorNumber
                return "{\"errorNumber\":" & errorNumber & "}"
            end try
        end timeout
        """#
    }

    public static func javascript(expectedOrigin: String) throws -> String {
        let origin = String(decoding: try JSONEncoder().encode(expectedOrigin), as: UTF8.self)
        return script.replacingOccurrences(of: "__EXPECTED_ORIGIN__", with: origin)
    }

    public static func decode(_ data: Data, configuredURL: URL) throws -> DashboardPage {
        guard data.count <= 256_000 else { throw CommandError.pageTooLarge }
        let payload: Payload
        do { payload = try JSONDecoder().decode(Payload.self, from: data) }
        catch { throw CommandError.safariReadFailed }
        if let error = payload.error {
            switch error {
            case "wrongPage": throw CommandError.wrongSafariPage
            case "noWindow": throw CommandError.safariWindowUnavailable
            default: throw CommandError.safariReadFailed
            }
        }
        if let number = payload.errorNumber {
            if number == -1743 { throw CommandError.safariAutomationRequired }
            if number == -1712 { throw CommandError.safariReadTimedOut }
            throw CommandError.safariJavaScriptRequired
        }
        guard let rawURL = payload.url, let url = URL(string: rawURL), let text = payload.text else {
            throw CommandError.safariReadFailed
        }
        try DashboardPageScope.validate(url, against: configuredURL)
        return try DashboardPage(title: payload.title ?? "Dashboard", url: url, text: text,
            headings: payload.headings ?? [], tables: payload.tables ?? [], truncated: payload.truncated ?? false,
            hasVisualContent: payload.hasVisualContent ?? false)
    }

    private struct Payload: Decodable {
        let error: String?
        let errorNumber: Int?
        let title: String?
        let url: String?
        let text: String?
        let headings: [String]?
        let tables: [[[String]]]?
        let truncated: Bool?
        let hasVisualContent: Bool?
    }

    private static let script = #"""
    (() => {
      if (location.origin !== __EXPECTED_ORIGIN__) return JSON.stringify({error: 'wrongPage'});
      const deadline = Date.now() + 1500;
      const blocked = 'script,style,noscript,template,input,textarea,select,[contenteditable],[hidden],[aria-hidden="true"],[data-private]';
      const visible = el => {
        if (!el || el.closest(blocked)) return false;
        for (let p = el; p; p = p.parentElement) {
          if (Date.now() > deadline) return false;
          const style = getComputedStyle(p);
          if (style.display === 'none' || style.visibility === 'hidden' || style.visibility === 'collapse' || Number(style.opacity) === 0) return false;
        }
        return el.getClientRects().length > 0;
      };
      let truncated = false;
      let visits = 0;
      const readText = (root, limit) => {
        if (!root || !visible(root)) return '';
        const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
        let text = '', node;
        while ((node = walker.nextNode())) {
          if (++visits > 30000 || Date.now() > deadline) { truncated = true; break; }
          if (!visible(node.parentElement)) continue;
          const part = node.textContent.replace(/\s+/g, ' ').trim();
          if (!part) continue;
          const extra = (text ? '\n' : '') + part;
          if (text.length + extra.length > limit) { text += extra.slice(0, limit - text.length); truncated = true; break; }
          text += extra;
        }
        return text;
      };
      const text = readText(document.body, 16000);
      let remaining = 16000;
      const readStructured = el => {
        if (remaining <= 0) { truncated = true; return ''; }
        const value = readText(el, Math.min(200, remaining));
        remaining -= value.length;
        return value;
      };
      const headings = [];
      for (const h of document.querySelectorAll('h1,h2,h3,h4,h5,h6')) {
        if (headings.length >= 40 || visits > 30000 || Date.now() > deadline) { truncated = true; break; }
        if (visible(h)) headings.push(readStructured(h));
      }
      const tables = [];
      for (const table of document.querySelectorAll('table')) {
        if (tables.length >= 8 || visits > 30000 || Date.now() > deadline) { truncated = true; break; }
        if (!visible(table)) continue;
        const rows = [];
        for (const row of Array.from(table.rows).slice(0, 50)) {
          if (!visible(row)) continue;
          rows.push(Array.from(row.cells).slice(0, 12).map(readStructured));
          if (row.cells.length > 12) truncated = true;
        }
        if (table.rows.length > 50) truncated = true;
        tables.push(rows);
      }
      const hasVisualContent = !!document.querySelector('canvas,svg,iframe');
      return JSON.stringify({title: document.title.slice(0, 200), url: location.origin + location.pathname,
        text, headings, tables, truncated, hasVisualContent});
    })()
    """#
}
