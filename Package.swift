// swift-tools-version:5.10

import PackageDescription

let package = Package(
        name: "SectionsTableView",
        platforms: [
            .iOS(.v14),
        ],
        products: [
            .library(
                    name: "SectionsTableView",
                    targets: ["SectionsTableView"]),
        ],
        dependencies: [
            .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
            .package(url: "https://github.com/sunimp/UIExtensions.git", .upToNextMajor(from: "1.0.0")),
            .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.54.6"),
        ],
        targets: [
            .target(
                    name: "SectionsTableView",
                    dependencies: [
                        "SnapKit",
                        "UIExtensions",
                    ]
            )
        ]
)
