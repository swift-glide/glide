import NIO
import NIOHTTP1
import struct Foundation.Data
import class Foundation.JSONEncoder

public class Response: EventLoopOwner {
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
  func with(_ text: String, type: MIMEType) -> Future<Void> {
    setContentType(type)
    body = .string(text)
    return success
  }

  func with(_ data: Data, type: MIMEType) -> Future<Void> {
    setContentType(type)
    self["Content-Length"] = "\(data.count)"
    body = .data(data)
    return success
  }

  func with<T: Encodable>(_ model: T) -> Future<Void> {
    let data : Data

    do {
      data = try JSONEncoder().encode(model)
      body = .data(data)
      return success
    } catch {
      return failure(error)
    }
  }

  public func setContentType(_ type: MIMEType) {
    self["Content-Type"] = type.description
  }
}

public extension Response {
  func send(_ text: String) -> Future<MiddlewareOutput> {
    success(.text(text))
  }

  func send(_ data: Data) -> Future<MiddlewareOutput> {
    success(.data(data))
  }

  func file(_ path: String) -> Future<MiddlewareOutput> {
    success(.file(path))
  }

  func json<T: Encodable>(_ model: T) -> Future<MiddlewareOutput> {
    success(.json(model))
  }

  func html(_ renderer: HTMLRendering) -> Future<MiddlewareOutput> {
    renderer.render(eventLoop).flatMap {
      return self.success(.text($0, as: .html))
    }
  }

  func toOutput() -> Future<MiddlewareOutput> {
    switch body {
    case .string(let text):
      return send(text)
    case .buffer(let byteBuffer):
      return send(byteBuffer.data)
    case .data(let data):
      return send(data)
    default:
      return success(.text(""))
    }
  }
}
