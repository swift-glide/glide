import Foundation
import NIO
import NIOHTTP1
import NIOFoundationCompat

final class HTTPServerHandler: ChannelInboundHandler {
  typealias InboundIn = HTTPServerRequestPart

  let router: Router
  var request: Request?
  var response: Response?
  let application: Application

  init(
    application: Application,
    router: Router
  ) {
    self.application = application
    self.router = router
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let requestPart = unwrapInboundIn(data)

    switch requestPart {
    case .head(let header):
      request = Request(application: application, header: header, eventLoop: context.eventLoop)
      response = Response(channel: context.channel)
      
    case .body(var byteBuffer):
      response = response ?? Response(channel: context.channel)

      guard let request = self.request else {
        response!.status = .badRequest
        response!.send("Malformed client request.")
        return
      }

      let byteBufferSize = byteBuffer.readableBytes
      let data = byteBuffer.readData(length: byteBufferSize)
      request.body = data

    case .end:
      router.unwind(request: request, response: response)
    }
  }
}
