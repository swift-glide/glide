import Foundation
import NIO
import NIOHTTP1
import NIOFoundationCompat

class HTTPResponseSerializer: ChannelOutboundHandler {
  typealias OutboundIn = Response
  typealias OutboundOut = HTTPServerResponsePart

  func write(
    context: ChannelHandlerContext,
    data: NIOAny,
    promise: EventLoopPromise<Void>?
  ) async {
    let response = unwrapOutboundIn(data)

    writeHead(
      on: context,
      status: response.status,
      headers: response.headers
    )

    do {
      try await writeBody(on: context, body: response.body)
      writeEnd(on: context)
    } catch {
      handleError(error, on: context)
    }
  }

  private func writeHead(
    on context: ChannelHandlerContext,
    status: HTTPResponseStatus,
    headers: HTTPHeaders
  ) {
    let head = HTTPResponseHead(
      version: .init(major: 1, minor: 1),
      status: status,
      headers: headers
    )

    context.write(wrapOutboundOut(.head(head)), promise: nil)
  }

  private func writeBody(
    on context: ChannelHandlerContext,
    body: Response.Body
  ) async throws {
    var byteBuffer: ByteBuffer

    switch body {
    case .buffer(let buffer):
      byteBuffer = buffer

    case .string(let text):
      byteBuffer = context.channel.allocator.buffer(capacity: text.count)
      byteBuffer.writeString(text)

    case .data(let data):
      byteBuffer = context.channel.allocator.buffer(capacity: data.count)
      byteBuffer.writeBytes(data)

    case .empty:
      return
    }

    return try await context.writeAndFlush(
      wrapOutboundOut(
        .body(
          .byteBuffer(byteBuffer)
        )
      )
    )

  }

  private func writeEnd(on context: ChannelHandlerContext) {
    let endpart = HTTPServerResponsePart.end(nil)

    context.writeAndFlush(wrapOutboundOut(endpart))
      .whenSuccess {
        context.channel.close().whenFailure {
          self.handleError($0, on: context)
        }
      }
  }

  private func handleError(
    _ error: Error,
    on context: ChannelHandlerContext
  ) {
    print("Response Error:", error)
    writeEnd(on: context)
  }
}
