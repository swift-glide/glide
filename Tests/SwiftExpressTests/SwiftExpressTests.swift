import XCTest
import class Foundation.Bundle

final class SwiftExpressTests: XCTestCase {
    func testExample() throws {
        let output = "Hello, world!\n"

        XCTAssertEqual(output, "Hello, world!\n")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
