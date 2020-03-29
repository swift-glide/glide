import Foundation
import NIO
import NIOHTTP1
import NIOFoundationCompat

class HTTPConnectionHandler: ChannelInboundHandler {
  typealias InboundIn = Request
  typealias InboundOut = Response

  let router: Router

  init(router: Router) {
    self.router = router
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let request = unwrapInboundIn(data)
    let response = Response()

    router.unwind(request: request, response: response).whenSuccess {
      context.write(self.wrapInboundOut(response), promise: nil)
    }
  }
}
