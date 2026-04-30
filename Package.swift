// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AuroraIOSApp",
    platforms: [.iOS(.v15)],
    products: [
        .executable(name: "AuroraIOSApp", targets: ["AuroraIOSApp"])
    ],
    targets: [
        .executableTarget(
            name: "AuroraIOSApp",
            path: "Platforms/AuroraIOS/swift",
            exclude: ["Bridge/AuroraSwift-Bridging-Header.h"],
            sources: ["App", "UI", "Bridge"],
            swiftSettings: [.unsafeFlags(["-Xfrontend", "-enable-experimental-cxx-interop"])]
        )
    ]
)
