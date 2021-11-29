// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SectionsTableView",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "SectionsTableView",
            targets: ["SectionsTableView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/horizontalsystems/UIExtensions.git", .upToNextMajor(from: "1.1.1")),
        .package(url: "https://github.com/SnapKit/SnapKit.git", .upToNextMajor(from: "5.0.1")),
    ],
    targets: [
        .target(
            name: "SectionsTableView",
            dependencies: ["UIExtensions", "SnapKit"]
        )
    ]
)
