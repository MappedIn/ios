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
            checksum: "83154f039574745e3dde26534be68f06ffb934c2b0d4a4f9afe7a4d8b85fd3b7"
        )
    ]
)
