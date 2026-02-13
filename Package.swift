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
            url: "https://github.com/MappedIn/ios/releases/download/6.2.0-beta.1/Mappedin.xcframework.zip",
            checksum: "ebb744b978fe974b11ed15ee5ca86f17834a334522cc41fbc8cb76ef5bff0378"
        )
    ]
)
