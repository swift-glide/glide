import Foundation
import NIO
import NIOHTTP1
import AsyncHTTPClient
import XCTest
@testable import Glide

final class PathExpressionTests: GlideTests {
  func testPathExpressionLiteral() throws {
    let expression: PathExpression = "/hello/\("foo")/\("bar")/baz/\("qux", as: Int.self)/"
    let segments = expression.segments
    XCTAssertFalse(segments.isEmpty)
    XCTAssertEqual(segments[0], .literal("hello"))
    XCTAssertEqual(segments[1], .parameter("foo"))
    XCTAssertEqual(segments[2], .parameter("bar"))
    XCTAssertEqual(segments[4], .parameter("qux", type: Int.self))
  }

  func testPathBuilderWildcards() throws {
    let expression: PathExpression = "/hello/\(wildcard: .one)/bar/\(wildcard: .one)/baz"
    let segments = expression.segments
    XCTAssertFalse(segments.isEmpty)
    XCTAssertEqual(segments[1], .wildcard())
    XCTAssertEqual(segments[3], .wildcard())
  }
}
