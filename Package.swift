// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Nomen",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "NomenCore"),
        .executableTarget(name: "Nomen", dependencies: ["NomenCore"]),
        .testTarget(name: "NomenCoreTests", dependencies: ["NomenCore"]),
    ]
)
