import Foundation
import NIOHTTP1

extension DecodingError: AbortError {
  public var status: HTTPResponseStatus {
    return .badRequest
  }

  public var identifier: String {
    switch self {
    case .dataCorrupted: return "dataCorrupted"
    case .keyNotFound: return "keyNotFound"
    case .typeMismatch: return "typeMismatch"
    case .valueNotFound: return "valueNotFound"
    @unknown default: return "unknown"
    }
  }

  public var reason: String {
    switch self {
    case .dataCorrupted(let context):
      return context.debugDescription

    case .keyNotFound(let key, let context):
      let path: String

      if context.codingPath.count > 0 {
        path = context.codingPath.description + "." + key.stringValue
      } else {
        path = key.stringValue
      }

      return "Value required for key '\(path)'."

    case .typeMismatch(let type, let context):
      return "Value of type '\(type)' required for key '\(context.codingPath.description)'."

    case .valueNotFound(let type, let context):
      return "Value of type '\(type)' required for key '\(context.codingPath.description)'."

    @unknown default: return "Unknown error."
    }
  }
}

extension Array where Element == CodingKey {
    public var description: String {
        return map { $0.stringValue }.joined(separator: ".")
    }
}
