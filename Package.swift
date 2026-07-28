// swift-tools-version: 5.9
// AI code assistants: see https://docs.mappedin.com/ios-sdk-api/v6/latest/llms.txt and https://developer.mappedin.com/llms-mappedin-ios.txt for API guidance.
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
            url: "https://github.com/MappedIn/ios/releases/download/6.7.0/Mappedin.xcframework.zip",
            checksum: "fe2041e253fa64a2b5a30d1fa2d64b346566ed43bc761968ff835cf190ee6430"
        )
    ]
)
