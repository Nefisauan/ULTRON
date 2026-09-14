import AppKit
import ImageIO
import ScreenCaptureKit
import UltronCore

@MainActor
final class MacScreenCapturer: ScreenCapturer {
    func capture(_ target: ScreenCaptureTarget) async throws -> ScreenContext {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
            try Task.checkCancellation()
            let filter: SCContentFilter
            let width: Int
            let height: Int
            let displayID: UInt32?
            let application: String?
            let title: String?
            switch target {
            case .display:
                let displays = content.displays.sorted { $0.displayID < $1.displayID }
                guard !displays.isEmpty else { throw CommandError.captureUnavailable }
                let labels = displays.map { "Display \($0.displayID) · \($0.width) × \($0.height)" }
                let index = try await choose(labels, explanation: "Choose a display. ULTRON will capture one frame of the entire display, excluding its own windows. Other visible apps may be included. The frame stays in memory and is discarded after the local mock analyzer returns; no data is analyzed or uploaded.")
                let display = displays[index]
                let ownApps = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
                filter = SCContentFilter(display: display, excludingApplications: ownApps, exceptingWindows: [])
                width = display.width
                height = display.height
                displayID = display.displayID
                application = nil
                title = nil
            case .safariWindow:
                let windows = content.windows.filter {
                    $0.owningApplication?.bundleIdentifier == "com.apple.Safari" && $0.windowLayer == 0 && $0.frame.width > 1 && $0.frame.height > 1
                }.sorted { $0.windowID < $1.windowID }
                guard !windows.isEmpty else { throw CommandError.safariWindowUnavailable }
                let index = try await choose(windows.map { $0.title ?? "Safari window \($0.windowID)" }, explanation: "Select the Safari window displaying your dashboard. ULTRON will capture that window once. This development analyzer does not interpret business data or upload the image. Choose Cancel if the window contains information you do not want captured.")
                let window = windows[index]
                filter = SCContentFilter(desktopIndependentWindow: window)
                width = Int(window.frame.width * 2)
                height = Int(window.frame.height * 2)
                displayID = nil
                application = "Safari"
                title = window.title
            }
            try Task.checkCancellation()
            let configuration = SCStreamConfiguration()
            let scale = min(1, 2560.0 / Double(max(width, height)))
            configuration.width = max(1, Int(Double(width) * scale))
            configuration.height = max(1, Int(Double(height) * scale))
            configuration.showsCursor = false
            configuration.capturesAudio = false
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
            try Task.checkCancellation()
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else {
                throw CommandError.captureFailed
            }
            CGImageDestinationAddImage(destination, image, nil)
            guard CGImageDestinationFinalize(destination) else { throw CommandError.captureFailed }
            return try ScreenContext(imageData: data as Data, metadata: .init(displayIdentifier: displayID,
                application: application, windowTitle: title, width: image.width, height: image.height))
        } catch is CancellationError { throw CancellationError() }
        catch let error as CommandError { throw error }
        catch { throw CommandError.captureFailed }
    }

    private func choose(_ options: [String], explanation: String) async throws -> Int {
        try Task.checkCancellation()
        let alert = NSAlert()
        alert.messageText = "Capture one frame"
        alert.informativeText = explanation
        alert.addButton(withTitle: "Capture")
        alert.addButton(withTitle: "Cancel")
        let picker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 420, height: 28))
        picker.addItems(withTitles: options)
        alert.accessoryView = picker
        guard let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey }) else {
            throw CommandError.captureUnavailable
        }
        let dialog = CaptureSelectionDialog(alert: alert, parent: window)
        let response = await withTaskCancellationHandler {
            await alert.beginSheetModal(for: window)
        } onCancel: {
            Task { @MainActor in dialog.cancel() }
        }
        try Task.checkCancellation()
        guard response == .alertFirstButtonReturn, options.indices.contains(picker.indexOfSelectedItem) else {
            throw CancellationError()
        }
        return picker.indexOfSelectedItem
    }
}

/// A main-actor wrapper keeps AppKit objects out of Sendable cancellation closures.
@MainActor
private final class CaptureSelectionDialog {
    let alert: NSAlert
    let parent: NSWindow
    init(alert: NSAlert, parent: NSWindow) {
        self.alert = alert
        self.parent = parent
    }
    func cancel() {
        if alert.window.sheetParent != nil {
            parent.endSheet(alert.window, returnCode: .abort)
        }
    }
}
