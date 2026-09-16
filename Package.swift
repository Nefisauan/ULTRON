// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ULTRON",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "UltronCore", targets: ["UltronCore"]),
        .library(name: "UltronUI", targets: ["UltronUI"]),
        .library(name: "UltronLink", targets: ["UltronLink"]),
        .executable(name: "UltronVoicePreview", targets: ["UltronVoicePreview"]),
        .executable(name: "UltronMac", targets: ["UltronMac"])
    ],
    targets: [
        .target(name: "UltronCore"),
        .target(name: "UltronUI", dependencies: ["UltronCore"]),
        .target(name: "UltronLink"),
        .executableTarget(name: "UltronVoicePreview", dependencies: ["UltronCore", "UltronUI"]),
        .executableTarget(name: "UltronMac", dependencies: ["UltronCore", "UltronUI", "UltronLink"]),
        .testTarget(name: "UltronCoreTests", dependencies: ["UltronCore"]),
        .testTarget(name: "UltronMacTests", dependencies: ["UltronMac"]),
        .testTarget(name: "UltronLinkTests", dependencies: ["UltronLink"])
    ],
    swiftLanguageModes: [.v6]
)
