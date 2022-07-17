import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

final class ParameterMatchingTests: GlideTests {
  func testQueryParameterString() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get("/query") { request, response in

        XCTAssertEqual(request.queryParameters["foo"]?.as(String.self), "bar")
        XCTAssertEqual(request.queryParameters.string("foo"), "bar")
        XCTAssertEqual(request.queryParameters.baz, "qux")
        expectation.fulfill()

        return request.syncSuccess(.text(request.queryParameters.foo ?? ""))
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
        XCTAssertEqual(request.queryParameters.int("foo"), 12)

        XCTAssertEqual(request.queryParameters["bar"]?.as(Double.self), 10.9)
        XCTAssertEqual(request.queryParameters.bar, 10.9)
        XCTAssertEqual(request.queryParameters.double("bar"), 10.9)

        XCTAssertEqual(request.queryParameters["baz"]?.as(Float.self), Float(10))
        XCTAssertEqual(request.queryParameters.baz, Float(10))
        XCTAssertEqual(request.queryParameters.float("baz"), Float(10))

        XCTAssertNotNil(request.queryParameters["qux"])
        XCTAssertEqual(request.queryParameters.contains("qux"), true)
        XCTAssertEqual(request.queryParameters.bool("fox"), false)
        XCTAssertEqual(request.queryParameters.thud, true)
        XCTAssertEqual(request.queryParameters.bool("thud"), true)

        expectation.fulfill()

        return request.syncSuccess(.text(request.queryParameters.foo ?? ""))
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

        return request.syncSuccess(.text(request.queryParameters.foo ?? ""))
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

  func testValidQueryParameter() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get("/query?\("foo")&\("baz")") { request, response in
        XCTAssertEqual(request.queryParameters.foo, "bar")
        XCTAssertEqual(request.queryParameters.baz, "qux")
        XCTAssertEqual(request.queryParameters.thud, "xyzzy")
        XCTAssertEqual(request.queryParameters.toto, "")
        expectation.fulfill()

        return request.syncSuccess(.text(request.queryParameters.foo ?? ""))
      }

      app.get("\(wildcard: .all)") { request, response in
        XCTFail("The path expression didn't match the provided URL.")
        expectation.fulfill()
        return request.syncSuccess(.text("Oops"))
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)/query?foo=bar&baz=qux&thud=xyzzy&toto",
        method: .GET,
        headers: .init()
      )

      _ = try client.execute(request: request).wait()
    }

    wait(for: [expectation], timeout: 5)
  }

  func testInvalidQueryParameter() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get("/query?\("thud")") { request, response in
        XCTFail("The path expression should not match this URL.")
        expectation.fulfill()
        return request.syncSuccess(.text("Oops"))
      }

      app.get("\(wildcard: .all)") { request, response in
        XCTAssert(true)
        expectation.fulfill()
        return request.syncSuccess(.text("Yieet!"))
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
