// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ESmanagers",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "ESmanagers",
            path: "Sources/ESmanagers"
        )
    ]
)
