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
      app.loadDotEnv("env", workingDirectory: testWorkingDirectory)
      XCTAssertEqual(app.env.three, "baz")
      XCTAssertEqual(app.env["FOUR"], "thud")
      XCTAssertNil(app.env.THREE)
      XCTAssertEqual(app.env.Three, "baz")
      XCTAssertNil(app.env["#SIX"])
      XCTAssertNil(app.env.six)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)
  }
}
