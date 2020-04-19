import Foundation
import NIO

public typealias Handler = () -> Future<Void>
public typealias Middleware = (Request, Response) throws -> Future<MiddlewareOutput>
public typealias SyncHTTPHandler = (Request, Response) throws -> Void
public typealias ErrorHandler = ([Error], Request, Response) -> Future<Void>

public enum ContentType: String {
  case plainText = "text/plain; charset=utf-8"
  case json = "application/json; charset=utf-8"
  case html = "text/html; charset=utf-8"
  case xml = "application/html; charset=utf-8"
}

public enum MiddlewareOutput {
  case next
  case send(String, as: ContentType = .plainText)
  case data(Data, as: ContentType = .json)
  case file(String)

  public static func json<T: Encodable>(_ model: T) -> Self {
    if let data = try? JSONEncoder().encode(model) {
      return .data(data)
    } else {
      return .next
    }
  }
}

public func passthrough(_ perform: @escaping SyncHTTPHandler) -> Middleware {
  return { request, response in
    try perform(request, response)
    return request.next()
  }
}
