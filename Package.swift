// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacServerMonitor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacServerMonitor",
            targets: ["MacServerMonitor"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacServerMonitor",
            path: "MacServerMonitor",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags(["-framework", "SwiftUI", "-framework", "AppKit", "-framework", "Network"])
            ]
        )
    ]
)
