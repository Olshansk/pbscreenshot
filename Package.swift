// swift-tools-version: 6.0
import PackageDescription

// Only the portable core is built on other hosts until their adapters exist.
var products: [Product] = [.library(name: "PBScreenshotKit", targets: ["PBScreenshotKit"])]
var dependencies: [Package.Dependency] = []
var targets: [Target] = [
    .target(name: "PBScreenshotKit", path: "Sources/Core"),
    .testTarget(name: "CoreTests", dependencies: ["PBScreenshotKit"], path: "Tests/CoreTests"),
]

#if os(macOS)
products += [
    .library(name: "PBScreenshotMacOS", targets: ["PBScreenshotMacOS"]),
    .executable(name: "pbscreenshot", targets: ["pbscreenshot"]),
    .executable(name: "pbscreenshot-agent", targets: ["pbscreenshotAgent"]),
]
dependencies += [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.2.0"),
]
targets += [
    .target(name: "PBScreenshotMacOS", dependencies: ["PBScreenshotKit"], path: "Sources/Platforms/macOS"),
    .executableTarget(
        name: "pbscreenshot",
        dependencies: ["PBScreenshotKit", "PBScreenshotMacOS", .product(name: "ArgumentParser", package: "swift-argument-parser")],
        path: "Sources/CLI/macOS"
    ),
    .executableTarget(
        name: "pbscreenshotAgent",
        dependencies: ["PBScreenshotKit", "PBScreenshotMacOS", .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")],
        path: "Sources/App/macOS"
    ),
    .testTarget(name: "MacOSTests", dependencies: ["PBScreenshotKit", "PBScreenshotMacOS"], path: "Tests/MacOSTests"),
    .testTarget(name: "AppTests", dependencies: ["pbscreenshotAgent"], path: "Tests/AppTests"),
]
#endif

let package = Package(
    name: "pbscreenshot",
    platforms: [.macOS(.v13)],
    products: products,
    dependencies: dependencies,
    targets: targets
)
