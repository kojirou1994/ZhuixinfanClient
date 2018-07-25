// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "ZhuixinfanRSS",
    products: [
        .executable(name: "ZhuixinfanRSS", targets: ["ZhuixinfanRSS"])
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura", .upToNextMinor(from: "2.4.0")),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger", from: "1.7.0"),
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-ORM.git", from: "0.3.0"),
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL.git", from: "1.2.0"),
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
