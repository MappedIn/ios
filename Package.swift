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
            url: "https://github.com/MappedIn/ios/releases/download/6.2.0-alpha.3/Mappedin.xcframework.zip",
            checksum: "5cd79cf87b3a315b3865288b98e853f3e4089f023e21393d0bd2bd32b3f400dd"
        )
    ]
)
