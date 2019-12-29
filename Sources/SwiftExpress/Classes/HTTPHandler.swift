import Foundation
import NIO
import NIOHTTP1

final class HTTPHandler: ChannelInboundHandler {
  typealias InboundIn = HTTPServerRequestPart

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let requestPart = unwrapInboundIn(data)

    switch requestPart {
    case .head(let header):
      let request = ClientRequest(header: header)
      let response = ServerResponse(channel: context.channel)

      print("req:", header.method, header.uri, request)

      response.send("Way easier to send data!!!")
    case .body, .end: break
    }
  }
}
