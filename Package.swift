// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sausage",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Sausage",
            path: "Sources/Sausage",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
