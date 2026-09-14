// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ULTRON",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "UltronCore", targets: ["UltronCore"]),
        .executable(name: "UltronVoicePreview", targets: ["UltronVoicePreview"])
    ],
    targets: [
        .target(name: "UltronCore"),
        .executableTarget(name: "UltronVoicePreview", dependencies: ["UltronCore"]),
        .testTarget(name: "UltronCoreTests", dependencies: ["UltronCore"])
    ],
    swiftLanguageModes: [.v6]
)
