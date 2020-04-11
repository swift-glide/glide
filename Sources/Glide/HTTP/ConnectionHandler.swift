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
    let response = Response(eventLoop: context.eventLoop)

    router.unwind(request: request, response: response).whenComplete { result in
      switch result {
      case .success(_):
        context.write(self.wrapInboundOut(response), promise: nil)

      case .failure(let error):
        print("Middleware Error: \(error.localizedDescription)")
        context.write(self.wrapInboundOut(response), promise: nil)
      }
    }
  }
}
