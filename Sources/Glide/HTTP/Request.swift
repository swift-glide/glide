import NIOHTTP1
import Foundation
import NIO

public final class Request: EventLoopOwner {
  public let application: Application
  public let head: HTTPRequestHead
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
    self.head = header
    self.eventLoop = eventLoop
  }
}

extension Request {
  public var fileReader: FileReader {
    return .init(
      fileIO: application.fileIO,
      allocator: application.allocator,
      eventLoop: eventLoop
    )
  }

  public var bodyData: Data? {
    body?.data
  }

  public var bodyString: String? {
    body?.string
  }
}
