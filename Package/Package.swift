// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Package",
    platforms: [.macOS(.v15)],
    products: [
        .library(
            name: "App",
            targets: ["App"],
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/kateinoigakukun/swift-indexstore.git",
            branch: "master",
        ),
        .package(
            url: "https://github.com/p-x9/xcode-indexstore-debug.git",
            exact: "0.2.0",
        ),
    ],
    targets: [
        .target(
            name: "App",
        ),
        .target(
            name: "Declaration",
        ),
        .target(
            name: "IndexStore",
            dependencies: [
                "Declaration",
                .product(name: "SwiftIndexStore", package: "swift-indexstore"),
            ],
        ),
        .target(name: "TestData"),
        .testTarget(
            name: "IndexStoreTest",
            dependencies: [
                "Declaration",
                "IndexStore",
                "TestData",
            ],
            plugins: [
                .plugin(name: "IndexStoreDebugBuildToolPlugin", package: "xcode-indexstore-debug"),
            ],
        ),
    ],
)
