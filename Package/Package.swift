// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Package",
    products: [
        .library(
            name: "Package",
            targets: ["Package"]),
    ],
    targets: [
        .target(
            name: "Package"),
        .testTarget(
            name: "PackageTests",
            dependencies: ["Package"]
        ),
    ]
)
