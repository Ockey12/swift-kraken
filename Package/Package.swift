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
            url: "https://github.com/pointfreeco/swift-custom-dump",
            exact: "1.3.3"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies.git",
            exact: "1.9.4"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-identified-collections.git",
            exact: "1.1.1",
        ),
        .package(
            url: "https://github.com/kateinoigakukun/swift-indexstore.git",
            branch: "master",
        ),
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            exact: "601.0.1",
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
            name: "IndexStore",
            dependencies: [
                "Location",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "SwiftIndexStore", package: "swift-indexstore"),
            ],
        ),
        .target(name: "Location"),
        .target(
            name: "SwiftDeclaration",
            dependencies: [
                "IndexStore",
                "UUID",
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
        .target(name: "TestData"),
        .testTarget(
            name: "IndexStoreTest",
            dependencies: [
                "IndexStore",
                "Location",
                "TestData",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ],
            plugins: [
                .plugin(name: "IndexStoreDebugBuildToolPlugin", package: "xcode-indexstore-debug"),
            ],
        ),
        .testTarget(
            name: "VisitorTest",
            dependencies: [
                "IndexStore",
                "Location",
                "SwiftDeclaration",
                "TestData",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        )
    ],
)
