import Foundation
import NIOHTTP1

enum InternalError: LocalizedError, CustomStringConvertible {
  case unhandledRoute

  var status: HTTPResponseStatus {
    switch self {
    case .unhandledRoute:
      return .notFound
    }
  }

  var errorDescription: String? {
    return self.description
  }

  var description: String {
    reason
  }

  var reason: String {
    switch self {
    case .unhandledRoute:
      return "No middleware found to handle this route."
    }
  }
}
