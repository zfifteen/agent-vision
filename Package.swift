// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "agent-vision",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AgentVision", targets: ["AgentVision"]),
        .library(name: "AgentVisionCore", targets: ["AgentVisionCore"])
    ],
    targets: [
        .executableTarget(
            name: "AgentVision",
            dependencies: ["AgentVisionCore"],
            exclude: ["Info.plist"],
            linkerSettings: [
                // Embed camera usage metadata in the standalone CLI binary launched inside AgentVision.app.
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/AgentVision/Info.plist"
                ])
            ]
        ),
        .target(
            name: "AgentVisionCore"
        ),
        .testTarget(
            name: "AgentVisionTests",
            dependencies: ["AgentVisionCore"]
        )
    ]
)
