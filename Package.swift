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
            url: "https://github.com/MappedIn/ios/releases/download/6.1.0-alpha.1/Mappedin.xcframework.zip",
            checksum: "e451614fe972d4d8fb77e9da470ff2ab36f030ffc9a0cf50bf9cc634d00d038a"
        )
    ]
)
