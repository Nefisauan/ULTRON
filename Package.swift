// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ULTRON",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "UltronCore", targets: ["UltronCore"]),
        .library(name: "UltronUI", targets: ["UltronUI"]),
        .executable(name: "UltronVoicePreview", targets: ["UltronVoicePreview"]),
        .executable(name: "UltronMac", targets: ["UltronMac"])
    ],
    targets: [
        .target(name: "UltronCore"),
        .target(name: "UltronUI", dependencies: ["UltronCore"]),
        .executableTarget(name: "UltronVoicePreview", dependencies: ["UltronCore", "UltronUI"]),
        .executableTarget(name: "UltronMac", dependencies: ["UltronCore", "UltronUI"]),
        .testTarget(name: "UltronCoreTests", dependencies: ["UltronCore"])
    ],
    swiftLanguageModes: [.v6]
)
