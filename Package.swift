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
            url: "https://github.com/MappedIn/ios/releases/download/6.0.0-alpha.0/Mappedin.xcframework.zip",
            checksum: "c9f4052584199c079d24a0a4c0f5097f94a5a0cdb8929b7d7c4f0bac7c8454ee"
        )
    ]
)
