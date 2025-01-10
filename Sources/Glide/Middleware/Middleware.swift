import Foundation
import NIO

public enum MiddlewareOutput {
  case next
  case text(String, as: MIMEType = .plainText)
  case data(Data, as: MIMEType = .json)
  case file(String)

  public static func json<T: Encodable>(
    _ model: T,
    using encoder: JSONEncoder
  ) throws -> Self {
    let data = try encoder.encode(model)
    return .data(data)
  }
}

public func passthrough(
  _ perform: @escaping HTTPHandler
) -> Middleware {
  { request, response in
    try perform(request, response)
    return .next
  }
}
