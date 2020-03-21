import NIO
import NIOHTTP1
import struct Foundation.Data
import class Foundation.JSONEncoder

public class Response {
  public var status = HTTPResponseStatus.ok
  public var headers = HTTPHeaders()
  public let channel: Channel

  private var didWriteHeader = false
  private var didEnd = false

  public init(channel: Channel) {
    self.channel = channel
  }

  public func send(_ text: String) {
    flushHeader()

    var buffer = channel.allocator.buffer(capacity: text.count)
    buffer.writeString(text)

    let bodypart = HTTPServerResponsePart.body(.byteBuffer(buffer))

    channel.writeAndFlush(bodypart)
      .recover(handleError)
      .whenSuccess(end)
  }

  func flushHeader() {
    guard !didWriteHeader else { return }
    
    didWriteHeader = true

    let head = HTTPResponseHead(
      version: .init(major:1, minor:1),
      status: status,
      headers: headers
    )

    let headPart = HTTPServerResponsePart.head(head)

    channel.writeAndFlush(headPart)
      .whenFailure(handleError)
  }

  func handleError(_ error: Error) {
    print("Response Error:", error)
    end()
  }

  func end() {
    guard !didEnd else { return }

    let endpart = HTTPServerResponsePart.end(nil)

    channel.writeAndFlush(endpart)
      .whenSuccess {
        self.channel.close().whenFailure(self.handleError)
      }
  }
}

public extension Response {
  subscript(name: String) -> String? {
    set {
      assert(!didWriteHeader, "The header has been already sent.")

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
  func file(at path: String, for request: Request) throws {
    try request.fileIO.readEntireFile(at: path)
      .whenSuccess { buffer in
        self.flushHeader()

        let bodypart = HTTPServerResponsePart.body(.byteBuffer(buffer))

        self.channel.writeAndFlush(bodypart)
          .recover(self.handleError)
          .whenSuccess(self.end)
    }
  }

  func json<T: Encodable>(_ model: T) {
    let data : Data

    do {
      data = try JSONEncoder().encode(model)
    } catch {
      return handleError(error)
    }

    self["Content-Type"] = "application/json"
    self["Content-Length"] = "\(data.count)"

    flushHeader()

    var buffer = channel.allocator.buffer(capacity: data.count)
    buffer.writeBytes(data)

    let bodypart = HTTPServerResponsePart.body(.byteBuffer(buffer))

    channel.writeAndFlush(bodypart)
      .recover(handleError)
      .whenSuccess(end)
  }
}
