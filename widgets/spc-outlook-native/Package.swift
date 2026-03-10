// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SPCOutlook",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "SPCOutlook",
            path: "Sources/SPCOutlook"
        )
    ]
)
