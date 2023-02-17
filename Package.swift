// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "JazzServerNio",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "JazzServerNio",
            targets: ["JazzServerNio"]),
        .library(
            name: "JazzServerHummingbird",
            targets: ["JazzServerHummingbird"]),
    ],
    dependencies: [
        .package(url: "https://github.com/JazzFramework/Jazz.git", from: "0.0.8"),

        .package(url: "https://github.com/apple/swift-nio.git", from: "2.42.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.6.0"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.9.0"),

        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "0.13.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "JazzServerNio",
            dependencies: [
                .product(name: "JazzLogging", package: "Jazz"),
                .product(name: "JazzServer", package: "Jazz"),

                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ]),
        .target(
            name: "JazzServerHummingbird",
            dependencies: [
                .product(name: "JazzLogging", package: "Jazz"),
                .product(name: "JazzServer", package: "Jazz"),

                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdFoundation", package: "hummingbird"),

                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ]
        ),
        .testTarget(
            name: "JazzServerNioTests",
            dependencies: ["JazzServerNio"]),
        .testTarget(
            name: "JazzServerHummingbirdTests",
            dependencies: ["JazzServerHummingbird"]),
    ]
)