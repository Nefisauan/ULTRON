import AppKit
import SwiftUI
import UltronCore

struct DashboardPageReview: View {
    let page: DashboardPage
    @State private var copied = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Dashboard page text").font(.title2)
            Text("\(page.url.host ?? "Safari") · \(page.capturedAt.formatted())").font(.caption).foregroundStyle(.secondary)
            Text("Rendered text and tables from your Safari tab. Form fields and hidden content are excluded. Canvas charts, frames, and data on other pages may be missing.")
                .font(.callout).foregroundStyle(.secondary)
            if page.truncated { Text("This reading was shortened to fit the extraction limit.").foregroundStyle(.orange) }
            ScrollView {
                Text(page.text).font(.body.monospaced()).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                Button(copied ? "Copied" : "Copy for ChatGPT") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(page.chatGPTPrompt, forType: .string)
                    copied = true
                }
                Text("Copies only. Paste into your existing ChatGPT account to request cloud analysis.")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Done") { dismiss() }
            }
        }.padding(24).frame(width: 740, height: 590)
    }
}
