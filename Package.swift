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
            url: "https://github.com/MappedIn/ios/releases/download/6.4.0/Mappedin.xcframework.zip",
            checksum: "4fe24f3bbe35c8b5297aa4032b9db171659f2d3466e9a459b30a05284d53df85"
        )
    ]
)
