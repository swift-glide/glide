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

  func syncWith(_ text: String, as type: MIMEType) -> Future<Void> {
    setContentType(type)
    body = .string(text)
    return success
  }

  func syncWith(_ data: Data, as type: MIMEType) -> Future<Void> {
    setContentType(type)
    self["Content-Length"] = "\(data.count)"
    body = .data(data)
    return success
  }

  func syncWith<T: Encodable>(_ model: T) -> Future<Void> {
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
  func syncSend(_ text: String, as type: MIMEType = .plainText) -> Future<MiddlewareOutput> {
    syncSuccess(.text(text, as: type))
  }

  func syncSend(_ data: Data) -> Future<MiddlewareOutput> {
    syncSuccess(.data(data))
  }

  func syncFile(_ path: String) -> Future<MiddlewareOutput> {
    syncSuccess(.file(path))
  }

  func syncJson<T: Encodable>(
    _ model: T,
    using encoder: JSONEncoder = .init()
  ) -> Future<MiddlewareOutput> {
    do {
      let output = try MiddlewareOutput.json(model, using: encoder)
      return syncSuccess(output)
    } catch {
      return failure(error)
    }
  }

  func syncHtml(_ renderer: HTMLRendering) -> Future<MiddlewareOutput> {
    renderer.render(eventLoop).flatMap {
      return self.syncSuccess(.text($0, as: .html))
    }
  }

  func syncToOutput() -> Future<MiddlewareOutput> {
    switch body {
    case .string(let text):
      return syncSend(text)
    case .buffer(let byteBuffer):
      return syncSend(byteBuffer.data)
    case .data(let data):
      return syncSend(data)
    default:
      return syncSuccess(.text(""))
    }
  }
}

public extension Response {
  func send(_ text: String, as type: MIMEType = .plainText) async throws -> MiddlewareOutput {
    try await successAsync(.text(text, as: type))
  }

  func send(_ data: Data) async throws -> MiddlewareOutput {
    try await successAsync(.data(data))
  }

  func file(_ path: String) async throws -> MiddlewareOutput {
    try await successAsync(.file(path))
  }

  func json<T: Encodable>(
    _ model: T,
    using encoder: JSONEncoder = .init()
  ) async throws -> MiddlewareOutput {
    let output = try MiddlewareOutput.json(model, using: encoder)
    return try await successAsync(output)
  }

  func html(_ renderer: HTMLRendering) -> Future<MiddlewareOutput> {
    renderer.render(eventLoop).flatMap {
      return self.syncSuccess(.text($0, as: .html))
    }
  }

  func toOutput() async throws -> MiddlewareOutput {
    switch body {
    case .string(let text):
      return try await send(text)

    case .buffer(let byteBuffer):
      return try await send(byteBuffer.data)

    case .data(let data):
      return try await send(data)

    default:
      return try await successAsync(.text(""))
    }
  }
}
