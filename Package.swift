// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SwiftExpress",
    products: [
      .library(name: "SwiftExpress", targets: ["SwiftExpress"]),
      .executable(name: "sample", targets: ["Sample"])
    ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-nio", from: "2.12.0"),
      .package(url: "https://github.com/kaishin/HTMLKit", from: "2.0.0-beta.3"),
  ],
    targets: [
      .target(
        name: "Sample",
        dependencies: ["SwiftExpress"]
      ),
      .target(
        name: "SwiftExpress",
        dependencies: [
          "NIO",
          "NIOFoundationCompat",
          "NIOHTTP1",
          "NIOTLS",
          "HTMLKit"
      ]),
      .testTarget(
        name: "SwiftExpressTests",
        dependencies: ["SwiftExpress"]),
  ]
)

