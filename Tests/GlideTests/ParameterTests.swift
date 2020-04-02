import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

final class ParameterTests: GlideTests {
  func testQueryParameterString() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get("/query") { request, response in

        XCTAssertEqual(request.queryParameters["foo"]?.as(String.self), "bar")
        XCTAssertEqual(request.queryParameters.baz, "qux")
        expectation.fulfill()
        
        return .send(request.queryParameters.foo ?? "")
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)/query?foo=bar&baz=qux",
        method: .GET,
        headers: .init()
      )

      _ = try client.execute(request: request).wait()
    }

    wait(for: [expectation], timeout: 5)
  }

  func testQueryParameterNumeric() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get("/query") { request, response in
        XCTAssertEqual(request.queryParameters["foo"]?.as(Int.self), 12)
        XCTAssertEqual(request.queryParameters.foo, 12)

        XCTAssertEqual(request.queryParameters["bar"]?.as(Double.self), 10.9)
        XCTAssertEqual(request.queryParameters.bar, 10.9)

        XCTAssertEqual(request.queryParameters["baz"]?.as(Float.self), Float(10))
        XCTAssertEqual(request.queryParameters.baz, Float(10))

        XCTAssertNotNil(request.queryParameters["qux"])
        XCTAssertEqual(request.queryParameters.thud, true)

        expectation.fulfill()

        return .send(request.queryParameters.foo ?? "")
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)/query?foo=12&bar=10.9&baz=10.0&qux&thud=true",
        method: .GET,
        headers: .init()
      )

      _ = try client.execute(request: request).wait()
    }

    wait(for: [expectation], timeout: 5)
  }

  func testQueryParameterBool() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get("/query") { request, response in

        XCTAssertEqual(request.queryParameters["foo"]?.as(Bool.self), true)
        XCTAssertTrue(request.queryParameters.foo ?? false)

        XCTAssertEqual(request.queryParameters["baz"]?.as(Bool.self), false)
        XCTAssertFalse(request.queryParameters.baz ?? true)

        XCTAssertNotEqual(request.queryParameters.bar, false)

        expectation.fulfill()

        return .send(request.queryParameters.foo ?? "")
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)/query?foo=true&bar=0&baz=false",
        method: .GET,
        headers: .init()
      )

      _ = try client.execute(request: request).wait()
    }

    wait(for: [expectation], timeout: 5)
  }
}
