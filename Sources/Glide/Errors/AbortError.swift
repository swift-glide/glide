import Foundation
import NIOHTTP1

public protocol AbortError: LocalizedError, CustomStringConvertible {
  var status: HTTPResponseStatus { get }
  var reason: String { get }
}

extension AbortError {
  public var description: String {
    reason
  }
}
