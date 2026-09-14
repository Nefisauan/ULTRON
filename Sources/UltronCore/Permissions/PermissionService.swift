public enum PermissionStatus: String, Sendable {
    case granted, notGranted
}

/// Request methods must only be called in response to an explicit user action.
@MainActor
public protocol PermissionService {
    var screenRecordingStatus: PermissionStatus { get }
    func requestScreenRecording() -> PermissionStatus
}
