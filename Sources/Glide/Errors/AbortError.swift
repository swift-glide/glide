import Foundation
import NIOHTTP1

public protocol AbortError: LocalizedError, CustomStringConvertible {
  var status: HTTPResponseStatus { get }
  var reason: String { get }
  var code: Int { get }
}

extension AbortError {
  public var description: String {
    reason
  }

  public var localizedDescription: String {
    reason
  }
}
