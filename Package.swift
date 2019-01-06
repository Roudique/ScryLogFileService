// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScryLogFileService",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "ScryLogFileService",
            targets: ["ScryLogFileService"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/yaslab/CSV.swift.git", from: "2.3.1"),
        .package(url: "https://github.com/johnsundell/files.git", from: "2.2.1"),
        .package(url: "https://github.com/Roudique/ScryLogHTMLParser.git", from: "0.1.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ScryLogFileService",
            dependencies: ["CSV", "Files", "ScryLogHTMLParser"],
            path: "Sources"),
        .testTarget(
            name: "ScryLogFileServiceTests",
            dependencies: ["CSV", "Files", "ScryLogHTMLParser"]),
    ]
)
