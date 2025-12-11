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
            checksum: "567769158536c499fc6582ae6d39777ba4f6e4fc1448c5ff98c25f776f93c07a"
        )
    ]
)
