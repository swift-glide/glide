import NIOHTTP1
import Foundation
import NIO

public final class Request {
  public let application: Application
  public let header: HTTPRequestHead
  public var body: ByteBuffer? = nil
  public var pathParameters = Parameters()
  public var queryParameters = Parameters()
  public var userInfo = [AnyHashable: Any]()
  public let eventLoop: EventLoop

  init(
    application: Application,
    header: HTTPRequestHead,
    eventLoop: EventLoop
  ) {
    self.application = application
    self.header = header
    self.eventLoop = eventLoop
  }
}

extension Request {
  public var fileReader: FileReader {
    return .init(
      fileIO: application.fileIO,
      allocator: application.allocator,
      request: self
    )
  }
}

public extension Request {
  var successFuture: EventLoopFuture<Void> {
    eventLoop.makeSucceededFuture(())
  }

  func successFuture<T>(_ value: T) -> EventLoopFuture<T> {
    eventLoop.makeSucceededFuture(value)
  }

  func failureFuture<T>(_ error: Error) -> EventLoopFuture<T> {
    eventLoop.makeFailedFuture(error)
  }
}

