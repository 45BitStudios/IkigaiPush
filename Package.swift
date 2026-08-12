// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IkigaiPush",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "IkigaiPush", targets: ["IkigaiPush"])
    ],
    targets: [
        .target(name: "IkigaiPush"),
        .testTarget(name: "IkigaiPushTests", dependencies: ["IkigaiPush"])
    ]
)
