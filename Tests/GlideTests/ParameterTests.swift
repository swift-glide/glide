import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

final class ParameterTests: GlideTests {
  func testQueryParameterString() throws {
    let path = "/query"
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get(path) { request, response in
        response.send(request.queryParameters.foo ?? "")

        XCTAssertEqual(request.queryParameters.storage["foo"]?.asString(), "bar")
        XCTAssertEqual(request.queryParameters.baz, "qux")
        expectation.fulfill()
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)\(path)?foo=bar&baz=qux",
        method: .GET,
        headers: .init()
      )

      _ = try client.execute(request: request).wait()
    }

    wait(for: [expectation], timeout: 5)
  }

  func testQueryParameterNumeric() throws {
    let path = "/query"
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get(path) { request, response in
        response.send(request.queryParameters.foo ?? "")

        XCTAssertEqual(request.queryParameters.storage["foo"]?.asInt(), 12)
        XCTAssertEqual(request.queryParameters.foo, 12)

        XCTAssertEqual(request.queryParameters.storage["bar"]?.asDouble(), 10.9)
        XCTAssertEqual(request.queryParameters.bar, 10.9)

        XCTAssertEqual(request.queryParameters.storage["baz"]?.asFloat(), Float(10))
        XCTAssertEqual(request.queryParameters.baz, Float(10))

        XCTAssertNotNil(request.queryParameters.storage["qux"])

        expectation.fulfill()
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)\(path)?foo=12&bar=10.9&baz=10.0&qux",
        method: .GET,
        headers: .init()
      )

      _ = try client.execute(request: request).wait()
    }

    wait(for: [expectation], timeout: 5)
  }

  func testQueryParameterBool() throws {
    let path = "/query"
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get(path) { request, response in
        response.send(request.queryParameters.foo ?? "")

        XCTAssertEqual(request.queryParameters.storage["foo"]?.asBool(), true)
        XCTAssertTrue(request.queryParameters.foo ?? false)

        XCTAssertEqual(request.queryParameters.storage["baz"]?.asBool(), false)
        XCTAssertFalse(request.queryParameters.baz ?? true)

        XCTAssertNotEqual(request.queryParameters.bar, false)

        expectation.fulfill()
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)\(path)?foo=true&bar=0&baz=false",
        method: .GET,
        headers: .init()
      )

      _ = try client.execute(request: request).wait()
    }

    wait(for: [expectation], timeout: 5)
  }
}
