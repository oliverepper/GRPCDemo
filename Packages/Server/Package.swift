// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Server",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Server",
            targets: ["Server"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.18.0"),
        .package(url: "https://github.com/grpc/grpc-swift", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Server",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GRPC", package: "grpc-swift"),
            ]),
        .testTarget(
            name: "ServerTests",
            dependencies: ["Server"]),
    ]
)
