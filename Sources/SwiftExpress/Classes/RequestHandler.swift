import Foundation
import NIO
import NIOHTTP1

final class RequestHandler: ChannelInboundHandler {
  typealias InboundIn = HTTPServerRequestPart

  let router : SwiftExpress

  init(router: SwiftExpress) {
    self.router = router
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let requestPart = unwrapInboundIn(data)

    switch requestPart {
    case .head(let header):
      let request = Request(header: header)
      let response = Response(channel: context.channel,
                              renderer: router.htmlKit.renderer)

      router.handle(request: request,
                    response: response) { (items : Any...) in
                      response.status = .notFound
                      response.send("Page not found.")
      }
    case .body, .end: break
    }
  }
}
