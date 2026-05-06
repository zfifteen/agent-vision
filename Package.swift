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
            dependencies: ["CodexVisionCore"],
            exclude: ["Info.plist"],
            linkerSettings: [
                // Embed camera usage metadata in the standalone CLI binary launched inside CodexVision.app.
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/CodexVision/Info.plist"
                ])
            ]
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
