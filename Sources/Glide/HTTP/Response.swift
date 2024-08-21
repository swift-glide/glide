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
  func with(_ text: String, as type: MIMEType) {
    setContentType(type)
    body = .string(text)
  }

  func with(_ data: Data, as type: MIMEType) {
    setContentType(type)
    self["Content-Length"] = "\(data.count)"
    body = .data(data)
  }

  func with<T: Encodable>(_ model: T) throws {
    let data : Data
    data = try JSONEncoder().encode(model)
    body = .data(data)
  }

  public func setContentType(_ type: MIMEType) {
    self["Content-Type"] = type.description
  }
}

public extension Response {
  func send(_ text: String, as type: MIMEType = .plainText) -> MiddlewareOutput {
    .text(text, as: type)
  }

  func send(_ data: Data) -> MiddlewareOutput {
    .data(data)
  }

  func file(_ path: String) -> MiddlewareOutput {
    .file(path)
  }

  func json<T: Encodable>(
    _ model: T,
    using encoder: JSONEncoder = .init()
  ) throws -> MiddlewareOutput {
    return try .json(model, using: encoder)
  }

  func html(_ renderer: HTMLRendering) async throws -> MiddlewareOutput {
    let html = try await renderer.render(eventLoop)
    return .text(html, as: .html)
  }

  func toOutput() async throws -> MiddlewareOutput {
    switch body {
    case .string(let text):
      return send(text)

    case .buffer(let byteBuffer):
      return send(byteBuffer.data)

    case .data(let data):
      return send(data)

    default:
      return .text("")
    }
  }
}
