import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

final class PathExpressionTests: GlideTests {
  func testPathExpressionLiteral() throws {
    let expression: PathExpression = "/hello/\(string: "foo")/\(string: "bar")/baz/\(int: "qux")/"
    let segments = expression.segments
    XCTAssertFalse(segments.isEmpty)
    XCTAssertEqual(segments[0], .literal("hello"))
    XCTAssertEqual(segments[1], .string("foo"))
    XCTAssertEqual(segments[2], .string("bar"))
    XCTAssertEqual(segments[4], .int("qux"))
  }

  func testPathBuilderWildcards() throws {
    let expression: PathExpression = "/hello/\(wildcard: .segment)/bar/\(wildcard: .segment)/baz"
    let segments = expression.segments
    XCTAssertFalse(segments.isEmpty)
    XCTAssertEqual(segments[1], .wildcard())
    XCTAssertEqual(segments[3], .wildcard())
  }
}
