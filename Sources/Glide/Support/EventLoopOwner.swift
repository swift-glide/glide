import Foundation
import NIO

public protocol EventLoopOwner {
  var eventLoop: EventLoop { get }
}

extension ChannelHandlerContext: EventLoopOwner {}
