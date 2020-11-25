// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "Kyu",
    platforms: [
        .iOS("13.0"),
        .macOS("11.0")
    ],
    products: [
        .library(
            name: "Kyu",
            targets: ["Kyu"]),
    ],
    targets: [
        .target(
            name: "Kyu",
            path: "Kyu"),
        .testTarget(
            name: "KyuTests",
            dependencies: ["Kyu"],
            path: "KyuTests"),
    ]
)
