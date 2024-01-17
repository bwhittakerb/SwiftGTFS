// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGTFS",
    products: [
        // Define a library product that other packages can depend on.
        .library(
            name: "SwiftGTFS",
            targets: ["SwiftGTFS"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", .upToNextMajor(from: "0.14.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target( // Changed from .executableTarget to .target to create a library
            name: "SwiftGTFS",
            dependencies: [.product(name: "SQLite", package: "SQLite.swift"),],
            path: "./Sources"
        ),
        .testTarget(
            name: "SwiftGTFSTests",
            dependencies: ["SwiftGTFS"],
            path: "Tests/SwiftGTFSTests"
        ),
       
    ]
)
