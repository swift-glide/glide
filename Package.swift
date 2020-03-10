// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "Glide",
  products: [
    .library(name: "Glide", targets: ["Glide"]),
    .executable(name: "sample", targets: ["Sample"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio", from: "2.12.0"),
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "Sample",
      dependencies: ["Glide"]
    ),
    .target(
      name: "Glide",
      dependencies: [
        "NIO",
        "NIOFoundationCompat",
        "NIOHTTP1",
        "NIOTLS",
    ]),
    .testTarget(
      name: "GlideTests",
      dependencies: [
        "Glide",
        "AsyncHTTPClient"
    ]),
  ]
)
