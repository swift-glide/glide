import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

final class EnvFileTests: GlideTests {
  func testEnvFile() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.loadDotEnv()
      XCTAssertEqual(app.environment["THREE"], "baz")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)
  }
}
