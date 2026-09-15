import SwiftUI
import UltronLink

struct MacPairingView: View {
    @ObservedObject var link: SecureLink
    @State private var revealKey = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Connect your iPhone").font(.title2)
            Text("Hosting lets a device with your pairing key run ULTRON's supported commands and receive their text results. Use the same trusted local network. Hosting is off by default and ends after 30 minutes.")
            Text(link.status).foregroundStyle(.cyan)
            if link.isHosting {
                Text("Mac address: \(Host.current().name ?? ProcessInfo.processInfo.hostName)").textSelection(.enabled)
                if let port = link.port { Text("Port: \(port)").monospacedDigit() }
                Toggle("Show pairing key", isOn: $revealKey)
                if revealKey { Text(link.pairingKey).font(.caption.monospaced()).textSelection(.enabled) }
                Text("Enter this address, port, and key in the iPhone app's Settings. Keep the key private. Stopping hosting revokes this session; starting again generates a new key.").font(.caption).foregroundStyle(.secondary)
                Button("Stop hosting and disconnect", role: .destructive) { link.disconnect(); revealKey = false }
            } else {
                Button("Start local hosting") {
                    do { try link.startHosting(); error = nil }
                    catch { self.error = "Hosting could not start. Check Local Network permission." }
                }
            }
            if let error { Text(error).foregroundStyle(.orange) }
            HStack { Spacer(); Button("Done") { dismiss() } }
        }.padding(24).frame(width: 560)
    }
}
