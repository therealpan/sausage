// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClaudeMeter",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ClaudeMeter",
            path: "Sources/ClaudeMeter",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
