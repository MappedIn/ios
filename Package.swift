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
            url: "https://github.com/MappedIn/ios/releases/download/6.2.0-alpha.2/Mappedin.xcframework.zip",
            checksum: "95f160543a88bacd3e650c1a6e8845e6db53c6f73be966b8877610a08d22200b"
        )
    ]
)
