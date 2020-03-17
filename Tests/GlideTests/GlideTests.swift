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

  func performHTTPTest(_ test: (_ app: Glide, _ client: HTTPClient) throws -> Void) {
    let app = Glide(.testing)
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
    let path = "/ping"
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get(path) { request, response in
        response.send("pong")
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)\(path)",
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
    let app = Glide(.testing)

    app.listen(testPort)
    app.shutdown()

    XCTAssertTrue(app.didShutdown)
  }
}
