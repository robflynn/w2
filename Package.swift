// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "webster",
    dependencies: [
        .package(url: "https://github.com/freshOS/then.git", from: "4.2.0")        
    ],
    targets: [
        .target(
            name: "webster",
            dependencies: [
                "then"
            ]),
        .testTarget(
            name: "websterTests",
            dependencies: ["webster"]),
    ]
)
