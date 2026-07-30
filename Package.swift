// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IkigaiPush",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "IkigaiPush", targets: ["IkigaiPush"])
    ],
    targets: [
        .target(name: "IkigaiPush")
    ]
)
