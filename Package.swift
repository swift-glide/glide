// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SwiftExpress",
    products: [
      .executable(name: "swift-express", targets: ["SwiftExpress"])
    ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-nio", from: "2.12.0")
    ],
    targets: [
        .target(
          name: "SwiftExpress",
          dependencies: [
              "NIO",
              "NIOFoundationCompat",
              "NIOHTTP1",
              "NIOTLS"
            ]),
        .testTarget(
            name: "SwiftExpressTests",
            dependencies: ["SwiftExpress"]),
    ]
)

