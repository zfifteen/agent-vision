// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "codex-vision",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodexVision", targets: ["CodexVision"]),
        .library(name: "CodexVisionCore", targets: ["CodexVisionCore"])
    ],
    targets: [
        .executableTarget(
            name: "CodexVision",
            dependencies: ["CodexVisionCore"]
        ),
        .target(
            name: "CodexVisionCore"
        ),
        .testTarget(
            name: "CodexVisionTests",
            dependencies: ["CodexVisionCore"]
        )
    ]
)
