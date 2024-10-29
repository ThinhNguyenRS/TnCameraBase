// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TnCameraBase",
    platforms: [
        .iOS("15.4")
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TnCameraBase",
            targets: ["TnCameraBase"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ThinhNguyenRS/TnIosBase", .upToNextMajor(from: "1.0.2")),
//        .package(url: "https://github.com/finnvoor/Transcoding", .upToNextMajor(from: "0.0.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TnCameraBase",
            dependencies: [
                "TnIosBase",
//                "Transcoding",
            ]
        ),
        .testTarget(
            name: "TnCameraBaseTests",
            dependencies: ["TnCameraBase"]),
    ]
    
)
