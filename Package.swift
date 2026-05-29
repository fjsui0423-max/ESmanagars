// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ESmanagers",
    platforms: [
        .iOS(.v18)
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ESmanagers",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            path: "Sources/ESmanagers"
        )
    ]
)
