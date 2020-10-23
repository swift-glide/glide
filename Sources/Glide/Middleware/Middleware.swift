import Foundation
import NIO

public enum MiddlewareOutput {
  case next
  case text(String, as: MIMEType = .plainText)
  case data(Data, as: MIMEType = .json)
  case file(String)

  public static func json<T: Encodable>(_ model: T) throws -> Self {
    let data = try JSONEncoder().encode(model)
    return .data(data)
  }
}

public func passthrough(_ perform: @escaping ThrowingSyncHTTPHandler) -> ThrowingMiddleware {
  return { request, response in
    try perform(request, response)
    return request.next
  }
}
