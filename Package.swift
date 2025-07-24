// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirestoreQueryBuilder",
    platforms: [.iOS(.v16), .macOS(.v11)],
    products: [
        .library(
            name: "FirestoreQueryBuilder",
            targets: ["FirestoreQueryBuilder"]),
    ],
    dependencies: [
      .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .exactItem("12.0.0"))
    ],
    targets: [
        .target(
            name: "FirestoreQueryBuilder",
            dependencies: [
              .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ]),

    ]
)
