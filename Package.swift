// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PlutusFinancialReportSlicer",
    platforms: [.macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PlutusFinancialReportSlicer",
            targets: ["PlutusFinancialReportSlicer"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/swiftcsv/SwiftCSV", .upToNextMajor(from: "0.9.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PlutusFinancialReportSlicer",
            dependencies: [/*"SwiftCSV"*/]),
        .testTarget(
            name: "PlutusFinancialReportSlicerTests",
            dependencies: ["PlutusFinancialReportSlicer"],
            resources: [
                .copy("Resources/45545510_0914.txt"),
                .copy("Resources/financial_report.csv"),
                .copy("Resources/result.txt"),
            ]),
    ])
