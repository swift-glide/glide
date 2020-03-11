import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

let testPort = 8070

class GlideTestCase: XCTestCase {
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
