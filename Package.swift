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
            url: "https://github.com/MappedIn/ios/releases/download/6.2.0-beta.0/Mappedin.xcframework.zip",
            checksum: "592a2355df00116386742a61b9fa2df4acc919a6f20f6bdc6225d01b11f901e1"
        )
    ]
)
