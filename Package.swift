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
            checksum: "ebb5689db2c7c90505577c558f73ddbd30e874e729bf09b665872279d27e059a"
        )
    ]
)
