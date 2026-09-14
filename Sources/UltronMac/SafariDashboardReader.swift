import Foundation
import UltronCore

@MainActor
final class SafariDashboardReader: DashboardPageReader {
    func read(configuredURL: URL) async throws -> DashboardPage {
        let script = try SafariPageExtraction.appleScript(configuredURL: configuredURL)
        let job = SafariReadJob()
        let output = try await withTaskCancellationHandler {
            try await Task.detached { try job.run(script) }.value
        } onCancel: { job.cancel() }
        try Task.checkCancellation()
        return try SafariPageExtraction.decode(output, configuredURL: configuredURL)
    }
}

/// All process/cancellation state is protected by the lock. No stdout/stderr is logged or saved.
private final class SafariReadJob: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var cancelled = false
    private var timedOut = false

    func cancel(timeout: Bool = false) {
        lock.lock()
        defer { lock.unlock() }
        guard process != nil || !timeout else { return }
        cancelled = true
        timedOut = timeout
        if let process, process.isRunning { process.terminate() }
    }

    func run(_ script: String) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        lock.lock()
        if cancelled { lock.unlock(); throw CancellationError() }
        self.process = process
        do { try process.run() }
        catch { self.process = nil; lock.unlock(); throw CommandError.safariReadFailed }
        lock.unlock()
        defer {
            lock.lock()
            self.process = nil
            if process.isRunning { process.terminate() }
            lock.unlock()
            try? pipe.fileHandleForReading.close()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 12) { [weak self] in self?.cancel(timeout: true) }
        var output = Data()
        while let chunk = try pipe.fileHandleForReading.read(upToCount: 8192), !chunk.isEmpty {
            output.append(chunk)
            if output.count > 256_000 {
                cancel()
                process.waitUntilExit()
                throw CommandError.pageTooLarge
            }
        }
        process.waitUntilExit()
        lock.lock()
        let didCancel = cancelled
        let didTimeOut = timedOut
        self.process = nil
        lock.unlock()
        if didTimeOut { throw CommandError.safariReadTimedOut }
        if didCancel { throw CancellationError() }
        guard process.terminationStatus == 0 else { throw CommandError.safariReadFailed }
        return output
    }
}
