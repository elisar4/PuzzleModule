// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PuzzleModule",
    products: [
        .library(
            name: "PuzzleModule",
            targets: ["PuzzleModule"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PuzzleModule",
            dependencies: [],
            path: ".",
            exclude: [
                "Tests",
                "PuzzleModule.podspec"
            ]
        ),
        .testTarget(
            name: "PuzzleModuleTests",
            dependencies: ["PuzzleModule"]
        ),
    ]
)
