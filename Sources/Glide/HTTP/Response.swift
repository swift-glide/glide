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

public extension Response {
  func send(_ text: String) -> EventLoopFuture<Void> {
    body = .string(text)
    return eventLoop.makeSucceededFuture(())
  }

  func send(_ data: Data) -> EventLoopFuture<Void> {
    // TODO: Get proper content type.
    self["Content-Type"] = "application/json"
    self["Content-Length"] = "\(data.count)"
    body = .data(data)
    return eventLoop.makeSucceededFuture(())
  }

  func send<T: Encodable>(_ model: T) -> EventLoopFuture<Void> {
    let data : Data

    do {
      data = try JSONEncoder().encode(model)
      body = .data(data)
    return eventLoop.makeSucceededFuture(())
    } catch {
      print("Encoding error:", error)
      return failure(error)
    }
  }
}

public extension Response {
  func successFuture(_ output: MiddlewareOutput) -> EventLoopFuture<MiddlewareOutput> {
    eventLoop.makeSucceededFuture(output)
  }

  func failure<T>(_ error: Error) -> EventLoopFuture<T> {
    eventLoop.makeFailedFuture(error)
  }
}
