import NIOHTTP1
import Foundation
import NIO

public final class Request {
  public let header: HTTPRequestHead
  public var body: Data? = nil
  public var pathParameters = Parameters(storage: [:])
  public var queryParameters = Parameters(storage: [:])
  public var userInfo = [AnyHashable: Any]()
  public let eventLoop: EventLoop

  init(header: HTTPRequestHead, eventLoop: EventLoop) {
    self.header = header
    self.eventLoop = eventLoop
  }
}
