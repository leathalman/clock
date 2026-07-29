// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UtcMenuBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "UtcMenuBar", targets: ["UtcMenuBar"]),
    ],
    targets: [
        .executableTarget(name: "UtcMenuBar"),
    ]
)
