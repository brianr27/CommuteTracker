// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CommuteTracker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "CommuteTracker",
            targets: ["CommuteTracker"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "CommuteTracker",
            dependencies: [],
            path: "Sources"
        )
    ]
)
