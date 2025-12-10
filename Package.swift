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
            checksum: "aa9b4c8dfd7a062ce8230d7121415c359959383cfa154c617cf71ba921648055"
        )
    ]
)
