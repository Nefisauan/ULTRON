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
        let identifier = applications[name.lowercased()] ?? name
        let url: URL?
        if let known = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) {
            url = known
        } else {
            let roots = [URL(fileURLWithPath: "/Applications"), URL(fileURLWithPath: "/System/Applications"),
                         FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
            var matches = Set<URL>()
            for root in roots {
                guard let items = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
                while let candidate = items.nextObject() as? URL {
                    guard candidate.pathExtension.lowercased() == "app" else { continue }
                    let bundle = Bundle(url: candidate)
                    let names = [candidate.deletingPathExtension().lastPathComponent,
                                 bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
                                 bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String].compactMap { $0 }
                    if names.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
                        matches.insert(candidate.resolvingSymlinksInPath())
                    }
                }
            }
            guard matches.count <= 1 else { throw CommandError.ambiguousApplication }
            url = matches.first
        }
        guard let url else {
            throw CommandError.applicationNotFound(name)
        }
        do {
            _ = try await NSWorkspace.shared.openApplication(at: url, configuration: .init())
        } catch { throw CommandError.launchFailed }
    }

    func openURL(_ url: URL) async throws {
        try Task.checkCancellation()
        let validated = try BusinessDashboardConfiguration.validate(url.absoluteString)
        guard let safari = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") else {
            throw CommandError.applicationNotFound("Safari")
        }
        do {
            _ = try await NSWorkspace.shared.open([validated], withApplicationAt: safari, configuration: .init())
        } catch { throw CommandError.launchFailed }
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
