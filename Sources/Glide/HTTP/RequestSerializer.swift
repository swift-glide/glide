import Foundation
import NIO
import NIOHTTP1
import NIOFoundationCompat

final class HTTPRequestSerializer: ChannelInboundHandler {
  typealias InboundIn = HTTPServerRequestPart
  typealias InboundOut = Request

  enum RequestState {
    case awaitingHeadPart
    case awaitingBodyPart(Request)
    case awaitingEnd(Request)
  }

  var requestState: RequestState = .awaitingHeadPart
  let application: Application

  init(application: Application) {
    self.application = application
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let requestPart = unwrapInboundIn(data)

    switch (requestPart, requestState) {
    case (.head(let head), .awaitingHeadPart):
      let request = Request(
        application: application,
        header: head,
        eventLoop: context.eventLoop
      )
      requestState = .awaitingBodyPart(request)

    case let (.body(byteBuffer), .awaitingBodyPart(request)):
      request.body = byteBuffer
      requestState = .awaitingEnd(request)

    case let (.end, .awaitingBodyPart(request)),
         let (.end, .awaitingEnd(request)):
      context.fireChannelRead(wrapInboundOut(request))
    default:
      assertionFailure("Unexpected request state: \(self.requestState)")
    }
  }
}
