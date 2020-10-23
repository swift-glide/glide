import Foundation
import NIO

public enum MiddlewareOutput {
  case next
  case text(String, as: MIMEType = .plainText)
  case data(Data, as: MIMEType = .json)
  case file(String)

  public static func json<T: Encodable>(_ model: T) -> Self {
    if let data = try? JSONEncoder().encode(model) {
      return .data(data)
    } else {
      return .next
    }
  }
}

public func passthrough(_ perform: @escaping ThrowingSyncHTTPHandler) -> Middleware {
  return { request, response in
    try perform(request, response)
    return request.next
  }
}
