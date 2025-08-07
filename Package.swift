// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "",
    products: [
        .executable(
            name: "TestSwift",
            targets: ["TestSwift"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TestSwift"),
        .testTarget(
            name: "TestSwiftTest",
            dependencies: ["TestSwift"]
        ),
    ]
)
