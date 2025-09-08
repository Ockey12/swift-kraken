// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Package",
    products: [
        .library(
            name: "App",
            targets: ["App"],
        ),
    ],
    targets: [
        .target(name: "App"),
        .testTarget(name: "EmptyTest"),
    ],
)
