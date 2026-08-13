// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "pbscreenshot",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "PBScreenshotKit", targets: ["PBScreenshotKit"]),
        .executable(name: "pbscreenshot", targets: ["pbscreenshot"]),
        .executable(name: "pbscreenshot-agent", targets: ["pbscreenshotAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.2.0"),
    ],
    targets: [
        .target(name: "PBScreenshotKit"),
        .executableTarget(
            name: "pbscreenshot",
            dependencies: [
                "PBScreenshotKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "pbscreenshotAgent",
            dependencies: [
                "PBScreenshotKit",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ]
        ),
        .testTarget(name: "PBScreenshotKitTests", dependencies: ["PBScreenshotKit"]),
    ]
)
