import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

let testWorkingDirectory: String = {
  return String(
    URL(fileURLWithPath: #file)
      .pathComponents
      .dropLast()
      .joined(separator: "/")
      .dropFirst()
  )
}()


final class StaticFileTests: GlideTests {
  func testTextFile() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.use(
        consoleLogger,
        corsHandler(allowOrigin: "*"),
        staticFileHandler(workingDirectory: testWorkingDirectory)
      )

      app.catch(errorLogger, { errors, request, _ in
        print(errors.count, "error(s) encountered.")
        return request.success
      })

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)/sample.txt",
        method: .GET,
        headers: .init()
      )

      let response = try client.execute(request: request).wait()

      var buffer = response.body ?? ByteBufferAllocator().buffer(capacity: 0)
      let responseContent = buffer.readString(length: buffer.readableBytes) ?? ""

      XCTAssertEqual(responseContent, "Hello, world!\n")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)
  }

  func testStaticFileMiddlewarePrecedence() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.use(
        consoleLogger,
        corsHandler(allowOrigin: "*"),
        staticFileHandler(workingDirectory: testWorkingDirectory)
      )

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
}
