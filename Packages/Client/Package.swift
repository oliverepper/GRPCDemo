// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Client",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Client",
            targets: ["Client"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.18.0"),
        .package(url: "https://github.com/grpc/grpc-swift", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Client",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GRPC", package: "grpc-swift")
            ]),
        .testTarget(
            name: "ClientTests",
            dependencies: ["Client"]),
    ]
)
