import NIO
import NIOHTTP1

public class ServerResponse {
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

    _ = channel.writeAndFlush(bodypart)
      .recover(handleError)
      .map(end)
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

    _ = channel.writeAndFlush(headPart)
      .recover(handleError)
  }

  func handleError(_ error: Error) {
    print("Error:", error.localizedDescription)
    end()
  }

  func end() {
    guard !didEnd else { return }

    let endpart = HTTPServerResponsePart.end(nil)

    channel.writeAndFlush(endpart).whenSuccess {
      _ = self.channel.close()
    }
  }
}
