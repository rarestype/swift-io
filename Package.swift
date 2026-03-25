// swift-tools-version:6.0
import PackageDescription

let package: Package = .init(
    name: "swift-io",
    platforms: [.macOS(.v15), .iOS(.v18), .visionOS(.v2)],
    products: [
        .library(name: "SystemIO", targets: ["SystemIO"]),
        .library(name: "System_ArgumentParser", targets: ["System_ArgumentParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ordo-one/dollup", from: "1.0.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.1"),
        .package(url: "https://github.com/apple/swift-system", from: "1.6.4"),
    ],
    targets: [
        .target(
            name: "SystemIO",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system"),
            ]
        ),

        .target(
            name: "System_ArgumentParser",
            dependencies: [
                .target(name: "SystemIO"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),

        .testTarget(
            name: "SystemTests",
            dependencies: [
                .target(name: "SystemIO"),
            ],
            exclude: [
                "directories",
            ]
        ),
    ]
)

for target: Target in package.targets {
    {
        var settings: [SwiftSetting] = $0 ?? []

        settings.append(.enableUpcomingFeature("ExistentialAny"))
        settings.append(.enableUpcomingFeature("InternalImportsByDefault"))
        settings.append(.enableExperimentalFeature("StrictConcurrency"))

        $0 = settings
    } (&target.swiftSettings)
}
