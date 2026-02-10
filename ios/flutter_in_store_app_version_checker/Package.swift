// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_in_store_app_version_checker",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "flutter-in-store-app-version-checker",
            targets: ["flutter_in_store_app_version_checker"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_in_store_app_version_checker",
            dependencies: [],
            path: "Sources/flutter_in_store_app_version_checker",
            publicHeadersPath: "include"
        )
    ]
)
