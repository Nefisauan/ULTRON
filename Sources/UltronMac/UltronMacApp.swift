import AppKit
import SwiftUI

@main
struct UltronMacApp: App {
    @StateObject private var session = MacSession()

    var body: some Scene {
        Window("ULTRON", id: "main") {
            DashboardView(session: session)
                .onAppear { NSApp.setActivationPolicy(.regular) }
        }
        .defaultSize(width: 1120, height: 800)
        Settings { UltronSettingsView(preferences: session.preferences, voices: session.synthesizer.availableVoices, permissions: session.permissions) }
        MenuBarExtra("ULTRON", systemImage: "circle.hexagongrid.fill") {
            MenuActions(session: session)
        }
    }
}

private struct MenuActions: View {
    let session: MacSession
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("Open ULTRON") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("Open TradeScale") { session.submit("Open TradeScale") }
        Button("Show Markets") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
            session.submit("Show Markets")
        }
        Button("Analyze Dashboard") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
            session.submit("Analyze my dashboard")
        }
        Button("Look at Screen") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
            session.submit("Look at my screen")
        }
        Button("Stop") { session.commands.stop() }
        Divider()
        SettingsLink()
        Button("Quit ULTRON") {
            session.commands.stop()
            NSApp.terminate(nil)
        }.keyboardShortcut("q")
    }
}
