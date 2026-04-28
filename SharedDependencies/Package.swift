// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SharedDependencies",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "SharedDependencies", targets: ["SharedDependencies"])
    ],
    dependencies: [
        .package(url: "https://github.com/Azoy/zlib-spm", branch: "master"),
        .package(url: "https://github.com/jarrodnorwell/zstd", branch: "dev"),
        .package(url: "https://github.com/krzyzanowskim/OpenSSL", branch: "main")
    ],
    targets: [
        .target(
            name: "SharedDependencies",
            dependencies: [
                .product(name: "libzstd", package: "zstd"),
                .product(name: "libseekable_format", package: "zstd"),
                .product(name: "OpenSSL", package: "OpenSSL")
            ]
        )
    ]
)
