// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TilawahOverlay",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "TilawahOverlay", targets: ["TilawahOverlay"]),
    ],
    targets: [
        .executableTarget(
            name: "TilawahOverlay",
            path: "Sources/TilawahOverlay",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
            ]
        ),
    ]
)
