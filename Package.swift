// swift-tools-version:5.2
import PackageDescription

let package = Package(
  name: "glide",
  platforms: [
     .macOS(.v10_15)
  ],
  products: [
    .library(name: "Glide", targets: ["Glide"]),
    .executable(name: "sample", targets: ["Sample"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.19.0"),
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.1.0"),
  ],
  targets: [
    .target(
      name: "Sample",
      dependencies: [
        .target(name: "Glide"),
      ]
    ),
    .target(
      name: "Glide",
      dependencies: [
        .product(name: "NIO", package: "swift-nio"),
        .product(name: "NIOFoundationCompat", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio")
    ]),
    .testTarget(
      name: "GlideTests",
      dependencies: [
        .target(name: "Glide"),
        .product(name: "AsyncHTTPClient", package: "async-http-client")
    ]),
  ]
)
