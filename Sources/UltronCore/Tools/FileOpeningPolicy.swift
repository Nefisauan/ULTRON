import Foundation

/// Conservative Phase 1 policy, independent of filesystem access for testing.
public enum FileOpeningPolicy {
    public static func allows(pathExtension: String, isDirectory: Bool,
                              isPackage: Bool, isExecutable: Bool, isRegularFile: Bool) -> Bool {
        guard !isPackage else { return false }
        if isDirectory { return true }
        let extensions: Set<String> = ["txt", "md", "pdf", "png", "jpg", "jpeg", "gif", "heic"]
        return isRegularFile && !isExecutable && extensions.contains(pathExtension.lowercased())
    }
}
