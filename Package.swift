// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZhuixinfanClient",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url:"https://github.com/PerfectlySoft/Perfect-MySQL.git", from: "2.0.0"),
        .package(url: "https://github.com/swift-server/http.git", from: "0.1.0"),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger", from: "1.7.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ZhuixinfanClient",
            dependencies: ["MySQL", "HTTP", "HeliumLogger"])
    ]
)
