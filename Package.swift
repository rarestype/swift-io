// swift-tools-version:6.0
import PackageDescription

let package:Package = .init(name: "swift-bson",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .visionOS(.v2), .watchOS(.v11)],
    products: [
        .library(name: "SystemIO", targets: ["SystemIO"]),
        .library(name: "System_ArgumentParser", targets: ["System_ArgumentParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-system", from: "1.4.0"),
    ],
    targets: [
        .target(name: "SystemIO",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system"),
            ]),

        .target(name: "System_ArgumentParser",
            dependencies: [
                .target(name: "SystemIO"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),

        .testTarget(name: "SystemTests",
            dependencies: [
                .target(name: "SystemIO"),
            ],
            exclude: [
                "directories",
            ]),
    ]
)

for target:PackageDescription.Target in package.targets
{
    {
        var settings:[PackageDescription.SwiftSetting] = $0 ?? []

        settings.append(.enableUpcomingFeature("ExistentialAny"))
        settings.append(.enableExperimentalFeature("StrictConcurrency"))

        $0 = settings
    } (&target.swiftSettings)
}
