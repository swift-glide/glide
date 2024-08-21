import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

let testPort = 8070

class GlideTests: XCTestCase {
  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func performHTTPTest(_ test: (_ app: Application, _ client: HTTPClient) throws -> Void) {
    let app = Application(.testing)
    app.listen(testPort)
    defer { app.shutdown() }

    let client = HTTPClient(eventLoopGroupProvider: .createNew)
    defer { try! client.syncShutdown() }

    do {
      try test(app, client)
    } catch {
      XCTFail("Could not run the test.")
    }
  }
}

class AppTests: GlideTests {
  func testPing() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get("/ping") { _, response in
        return response.send("pong")
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)/ping",
        method: .GET,
        headers: .init()
      )

      let response = try client.execute(request: request).wait()

      var buffer = response.body ?? ByteBufferAllocator().buffer(capacity: 0)
      let responseContent = buffer.readString(length: buffer.readableBytes) ?? ""

      XCTAssertEqual(responseContent, "pong")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)
  }

  func testGracefulShutdown() throws {
    let app = Application(.testing)

    app.listen(testPort)
    app.shutdown()

    XCTAssertTrue(app.didShutdown)
  }
}
