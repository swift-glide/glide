import Foundation
import NIO
import NIOHTTP1

final class HTTPHandler: ChannelInboundHandler {
  typealias InboundIn = HTTPServerRequestPart

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let requestPart = unwrapInboundIn(data)

    switch requestPart {
    case .head(let header):
      print("req:", header)

      let channel = context.channel

      let head = HTTPResponseHead(
        version: header.version,
        status: .ok
      )

      let part = HTTPServerResponsePart.head(head)
      channel.write(part).whenSuccess({})

      var buffer = channel.allocator.buffer(capacity: 42)
      buffer.writeString("Hello Schwifty World!")

      let bodypart = HTTPServerResponsePart.body(.byteBuffer(buffer))
      channel.write(bodypart).whenSuccess({})

      let endpart = HTTPServerResponsePart.end(nil)

     channel.writeAndFlush(endpart).whenSuccess {
        channel.close().whenSuccess({})
      }

    case .body, .end: break
    }
  }
}
