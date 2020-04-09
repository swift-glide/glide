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

        return response.successFuture(.json(find(request.pathParameters.id ?? 0)))
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
}
