// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Mappedin",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "Mappedin", targets: ["Mappedin"])
    ],
    targets: [
        .binaryTarget(
            name: "Mappedin",
            url: "https://github.com/MappedIn/ios/releases/download/6.2.0-alpha.1/Mappedin.xcframework.zip",
            checksum: "6006bbe838d5445653152cf088bd7d19bdddd81d1ab144ef941064b0beb77942"
        )
    ]
)
