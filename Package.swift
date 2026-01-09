// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RecipeMD",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "RecipeMD",
            targets: ["RecipeMD"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "RecipeMD",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Sources/RecipeMD"
        ),
        .testTarget(
            name: "RecipeMDTests",
            dependencies: ["RecipeMD"],
            path: "Tests/RecipeMDTests"
        )
    ]
)
