import Foundation
import NIO
import NIOHTTP1

final class HTTPHandler: ChannelInboundHandler {
  typealias InboundIn = HTTPServerRequestPart

  let router : Router

  init(router: Router) {
    self.router = router
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let requestPart = unwrapInboundIn(data)

    switch requestPart {
    case .head(let header):
      let request = ClientRequest(header: header)
      let response = ServerResponse(channel: context.channel)

      router.handle(request: request,
                    response: response) { (items : Any...) in
                      response.status = .notFound
                      response.send("No middleware handled the request!")
      }
    case .body, .end: break
    }
  }
}
