import Foundation
import NIO
import NIOHTTP1

public final class SwiftExpress {
  let loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

  public func listen(_ port: Int) {
    let bootstrap = ServerBootstrap(group: loopGroup)
  }
}
