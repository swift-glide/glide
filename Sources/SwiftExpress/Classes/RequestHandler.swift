import Foundation
import NIO
import NIOHTTP1
import NIOFoundationCompat

final class RequestHandler: ChannelInboundHandler {
  typealias InboundIn = HTTPServerRequestPart

  let router: Router
  var request: Request?
  var response: Response?

  init(router: Router) {
    self.router = router
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let requestPart = unwrapInboundIn(data)

    switch requestPart {
    case .head(let header):
      request = Request(header: header)
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

      router.handle(request: request, response: response!) { (items: Any...) in
        self.response!.status = .notFound
        self.response!.send("Page not found.")
      }
    case .end: break
    }
  }
}
