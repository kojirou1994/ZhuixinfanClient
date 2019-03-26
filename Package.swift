// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "ZhuixinfanRSS",
    products: [
        .executable(name: "ZhuixinfanRSS", targets: ["ZhuixinfanRSS"])
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura", .upToNextMinor(from: "2.6.2")),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger", from: "1.8.0"),
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-ORM", from: "0.5.1"),
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL", from: "2.1.0"),
        .package(url: "https://github.com/kojirou1994/Kwift", .branch("master"))
    ],
    targets: [
        .target(
            name: "ZhuixinfanRSS",
            dependencies: [
                "Kwift",
                "SwiftKueryORM",
                "SwiftKueryPostgreSQL",
                "Kitura",
                "HeliumLogger"
            ])
    ]
)
