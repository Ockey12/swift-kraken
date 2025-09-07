// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.57.2"),
    ],
    targets: [.target(name: "BuildTools", path: "")],
)
