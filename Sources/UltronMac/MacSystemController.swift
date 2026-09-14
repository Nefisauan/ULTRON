import AppKit
import UltronCore

@MainActor
final class MacSystemController: ApplicationController, ResourceOpener {
    private let applications: [String: String] = [
        "safari": "com.apple.Safari",
        "xcode": "com.apple.dt.Xcode",
        "calculator": "com.apple.calculator"
    ]

    func openApplication(named name: String) async throws {
        try Task.checkCancellation()
        guard let identifier = applications[name.lowercased()],
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) else {
            throw CommandError.applicationNotFound(name)
        }
        do {
            _ = try await NSWorkspace.shared.openApplication(at: url, configuration: .init())
        } catch { throw CommandError.launchFailed }
    }

    func openURL(_ url: URL) async throws {
        try Task.checkCancellation()
        let validated = try BusinessDashboardConfiguration.validate(url.absoluteString)
        guard NSWorkspace.shared.open(validated) else { throw CommandError.launchFailed }
    }

    func openFile(_ url: URL) async throws {
        try Task.checkCancellation()
        guard url.isFileURL else { throw CommandError.invalidInput }
        let resolved = url.resolvingSymlinksInPath().standardizedFileURL
        var directory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: resolved.path, isDirectory: &directory) else {
            throw CommandError.fileNotFound
        }
        let isPackage = NSWorkspace.shared.isFilePackage(atPath: resolved.path)
        let values = try? resolved.resourceValues(forKeys: [.isRegularFileKey])
        guard FileOpeningPolicy.allows(pathExtension: resolved.pathExtension,
                                       isDirectory: directory.boolValue, isPackage: isPackage,
                                       isExecutable: FileManager.default.isExecutableFile(atPath: resolved.path),
                                       isRegularFile: values?.isRegularFile == true) else {
            throw CommandError.unsupportedFile
        }
        guard NSWorkspace.shared.open(resolved) else { throw CommandError.launchFailed }
    }
}
