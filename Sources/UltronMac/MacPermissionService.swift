import Combine
import CoreGraphics
import UltronCore

@MainActor
final class MacPermissionService: ObservableObject, PermissionService {
    @Published private(set) var status: PermissionStatus = .notGranted
    var screenRecordingStatus: PermissionStatus {
        CGPreflightScreenCaptureAccess() ? .granted : .notGranted
    }

    func refresh() { status = screenRecordingStatus }

    func requestScreenRecording() -> PermissionStatus {
        if screenRecordingStatus != .granted { _ = CGRequestScreenCaptureAccess() }
        refresh()
        return status
    }
}
