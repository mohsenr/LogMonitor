// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LogMonitor",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "LogMonitor",
            targets: ["LogMonitor"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/zuhlke/Support.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "LogMonitor",
            dependencies: [
                "Support",
            ]
        ),
    ]
)
