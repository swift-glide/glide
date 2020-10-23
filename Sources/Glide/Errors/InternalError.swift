import Foundation
import NIOHTTP1

enum GlideError: LocalizedError, CustomStringConvertible {
  case unhandledRoute
  case assetNotFound
  case unknown

  var status: HTTPResponseStatus {
    switch self {
    case .unhandledRoute:
      return .notFound
    case .unknown:
      return .internalServerError
    case .assetNotFound:
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
    case .assetNotFound:
      return "Static asset not found."
    case .unknown:
      return "An internal server error has occured."
    }
  }

  var localizedDescription: String {
    reason
  }
}
