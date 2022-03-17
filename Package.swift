// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "MMMCardModal",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "MMMCardModal",
            targets: ["MMMCardModal"]
	)
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MMMCardModal",
            dependencies: [],
            path: "Sources"
	)
    ]
)
