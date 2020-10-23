import XCTest
@testable import Glide

final class MIMETypeTests: GlideTests {
  func testCreateFromStringSuccess() throws {
    let type = MIMEType("application/json; charset=utf-8")
    XCTAssertNotNil(type)
    XCTAssertEqual(type!.parameter?.0, "charset")
    XCTAssertEqual(type!.parameter?.1, "utf-8")
    XCTAssertEqual(type!.type, .application)
    XCTAssertEqual(type!.subtype, "json")
  }

  func testCreateFromStringFailure() throws {
    let type = MIMEType("aplication/json; charset=utf-8")
    XCTAssertNil(type)
  }

  func testDescription() throws {
    let type = MIMEType(.application, subtype: "json", parameter: ("charset", "utf-8"))
    XCTAssertEqual(type.description, "application/json; charset=utf-8")
  }
}
