import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

final class ErrorHandlerTests: GlideTestCase {
  func testUnhandledRoute() throws {
    let path = "/unhandled"
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)\(path)",
        method: .GET,
        headers: .init()
      )

      let response = try client.execute(request: request).wait()
      var buffer = response.body ?? ByteBufferAllocator().buffer(capacity: 0)

      let data = buffer.readData(length: buffer.readableBytes)
      XCTAssertNotNil(data)

      let error = try? JSONDecoder().decode(Router.ErrorResponse.self, from: data!)
      XCTAssertNotNil(error)
      XCTAssertEqual(error!.error, "No middleware found to handle this route.")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)
  }

  func testCustomErrorHandler() throws {
    let path = "/throw"
    var caughtError: CustomError? = nil
    let expectation = XCTestExpectation()

    enum CustomError: Error {
      case someError
      case someOtherError
    }

    performHTTPTest { app, client in
      app.get(path) { _, _ in
        throw CustomError.someError
      }

      app.handleErrors { errors, _, _ in
        caughtError = errors.first as? CustomError
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)\(path)",
        method: .GET,
        headers: .init()
      )

      _ = try client.execute(request: request).wait()
      XCTAssertEqual(caughtError, CustomError.someError)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)
  }

  func testAbortError() throws {
    let path = "/abort"
    let expectation = XCTestExpectation()

    enum CustomAbortError: AbortError {
      case someError
      static let customReason = "Something went wrong"

      var status: HTTPResponseStatus {
        .notFound
      }

      var reason: String {
        CustomAbortError.customReason
      }
    }

    performHTTPTest { app, client in
      app.get(path) { _, _ in
        throw CustomAbortError.someError
      }

      app.use { _, response, _ in
        response.send("Success")
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)\(path)",
        method: .GET,
        headers: .init()
      )

      let response = try client.execute(request: request).wait()
      var buffer = response.body ?? ByteBufferAllocator().buffer(capacity: 0)

      let data = buffer.readData(length: buffer.readableBytes)
      XCTAssertNotNil(data)

      let error = try? JSONDecoder().decode(Router.ErrorResponse.self, from: data!)
      XCTAssertNotNil(error)
      XCTAssertEqual(error!.error, CustomAbortError.customReason)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)
  }
}
