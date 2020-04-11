import NIO
import NIOHTTP1
import struct Foundation.Data
import class Foundation.JSONEncoder

public class Response {
  public var status = HTTPResponseStatus.ok
  public var headers = HTTPHeaders()
  public var body = Body.empty
  public let eventLoop: EventLoop

  public init(eventLoop: EventLoop) {
    self.eventLoop = eventLoop
  }

  public enum Body {
    case empty
    case buffer(ByteBuffer)
    case data(Data)
    case string(String)
  }
}

public extension Response {
  subscript(name: String) -> String? {
    set {
      if let value = newValue {
        headers.replaceOrAdd(name: name, value: value)
      } else {
        headers.remove(name: name)
      }
    }

    get {
      return headers[name].joined(separator: ", ")
    }
  }
}

extension Response {
  func with(_ text: String) -> Future<Void> {
    body = .string(text)
    return eventLoop.makeSucceededFuture(())
  }

  func with(_ data: Data) -> Future<Void> {
    // TODO: Get proper content type.
    self["Content-Type"] = "application/json"
    self["Content-Length"] = "\(data.count)"
    body = .data(data)
    return eventLoop.makeSucceededFuture(())
  }

  func with<T: Encodable>(_ model: T) -> Future<Void> {
    let data : Data

    do {
      data = try JSONEncoder().encode(model)
      body = .data(data)
    return eventLoop.makeSucceededFuture(())
    } catch {
      print("Encoding Error:", error)
      return failure(error)
    }
  }
}

public extension Response {
  func send(_ text: String) -> Future<MiddlewareOutput> {
    eventLoop.makeSucceededFuture(.send(text))
  }

  func send(_ data: Data) -> Future<MiddlewareOutput> {
    eventLoop.makeSucceededFuture(.data(data))
  }

  func file(_ path: String) -> Future<MiddlewareOutput> {
    eventLoop.makeSucceededFuture(.file(path))
  }

  func json<T: Encodable>(_ model: T) -> Future<MiddlewareOutput> {
    eventLoop.makeSucceededFuture(.json(model))
  }

  func failure<T>(_ error: Error) -> Future<T> {
    eventLoop.makeFailedFuture(error)
  }
}
