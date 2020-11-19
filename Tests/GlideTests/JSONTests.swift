import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

final class JSONTests: GlideTests {
  struct User: Codable {
    var id: Int
    var name: String = "user"
    var password: String = "password"
  }

  func testJSONResponse() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.use(
        consoleLogger
      )

      app.get("/users/\("id", as: Int.self)") { request, response in
        func find(_ id: Int) -> User {
          User(id: id)
        }

        return response.json(find(request.pathParameters.id ?? 0))
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)/users/8",
        method: .GET,
        headers: .init()
      )

      let response = try client.execute(request: request).wait()
      var buffer = response.body ?? ByteBufferAllocator().buffer(capacity: 0)
      let responseContent = buffer.readData(length: buffer.readableBytes)

      XCTAssertNotNil(responseContent)

      let user = try? JSONDecoder().decode(User.self, from: responseContent!)
      XCTAssertNotNil(user)
      XCTAssertEqual(user?.id, 8)
      XCTAssertEqual(user?.name, "user")

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)
  }

  func testCustomEncoder() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get("/") { request, response in
        let date = Date(timeIntervalSince1970: 1605830400)
        let encoder: JSONEncoder = {
          let encoder = JSONEncoder()
          encoder.dateEncodingStrategy = .secondsSince1970
          return encoder
        }()

        return response.json(date, using: encoder)
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)/",
        method: .GET,
        headers: .init()
      )

      let response = try client.execute(request: request).wait()
      guard let responseContent = response.body?.string else {
        throw XCTestError(.failureWhileWaiting, userInfo: [:])
      }

      XCTAssertEqual(responseContent, "1605830400")

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)
  }

  func testCustomEncoderFailure() throws {
    let expectation = XCTestExpectation()

    performHTTPTest { app, client in
      app.get("/") { request, response in
        let date = Date(timeIntervalSince1970: 1605830400)
        return response.json(date)
      }

      let request = try HTTPClient.Request(
        url: "http://localhost:\(testPort)/",
        method: .GET,
        headers: .init()
      )

      let response = try client.execute(request: request).wait()
      guard let responseContent = response.body?.string else {
        throw XCTestError(.failureWhileWaiting, userInfo: [:])
      }

      XCTAssertNotEqual(responseContent, "1605830400")

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)
  }
}
