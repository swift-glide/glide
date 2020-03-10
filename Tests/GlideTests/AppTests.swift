import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

final class GlideTests: XCTestCase {
  func testPing() throws {
    let app = Glide(.testing)
    let path = "/ping"

    app.get(path) { request, response in
      response.send("pong")
    }

    app.listen(testPort)
    defer { app.shutdown() }

    let client = HTTPClient(eventLoopGroupProvider: .createNew)
    defer { try! client.syncShutdown() }

    let request = try HTTPClient.Request(
      url: "http://localhost:\(testPort)\(path)",
      method: .GET,
      headers: .init()
    )

    let response = try client.execute(request: request).wait()
    var buffer = response.body ?? ByteBufferAllocator().buffer(capacity: 0)
    let responseContent = buffer.readString(length: buffer.readableBytes) ?? ""

    XCTAssertEqual(responseContent, "pong")
  }

  func testGracefulShutdown() throws {
    let app = Glide(.testing)

    app.listen(testPort)
    app.shutdown()

    XCTAssertTrue(app.didShutdown)
  }
}
