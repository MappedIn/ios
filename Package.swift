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
            url: "https://github.com/MappedIn/ios/releases/download/6.8.0/Mappedin.xcframework.zip",
            checksum: "ae79fb3676c166180950b722ef8eb90919f3261e9cd549dd82bfdc2ae3829400"
        )
    ]
)
