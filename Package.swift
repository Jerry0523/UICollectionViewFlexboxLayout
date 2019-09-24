// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "UICollectionViewFlexboxLayout",
    products: [
        .library(name: "UICollectionViewFlexboxLayout", targets: ["UICollectionViewFlexboxLayout"]),
    ],
    targets: [
        .target(name: "UICollectionViewFlexboxLayout", path: "UICollectionViewFlexboxLayout/UICollectionViewFlexboxLayout")
    ]
)
