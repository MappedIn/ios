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
            url: "https://github.com/MappedIn/ios/releases/download/6.9.0/Mappedin.xcframework.zip",
            checksum: "0637cecdd328bfe9fa2de8163e1db7ac8ba5f5df3f6f1d2a56d625b0e6850bdc"
        )
    ]
)
