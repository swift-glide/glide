import Foundation
import NIO
import NIOHTTP1

public final class SwiftExpress: Router {
  let loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

  public override init() {}

  public func listen(_ port: Int) {
    let localAddressReuseOption = ChannelOptions.socket(
      SocketOptionLevel(SOL_SOCKET),
      SO_REUSEADDR
    )

    let bootstrap = ServerBootstrap(group: loopGroup)
      .serverChannelOption(ChannelOptions.backlog, value: 256)
      .serverChannelOption(localAddressReuseOption, value: 1)
      .childChannelInitializer { channel in
        channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
          channel.pipeline.addHandler(RequestHandler(router: self))
        }
      }
      .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
      .childChannelOption(localAddressReuseOption, value: 1)
      .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)

    do {
      let serverChannel = try bootstrap.bind(host: "localhost", port: port).wait()

      guard let localAddress = serverChannel.localAddress else {
        fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
      }

      print("Server running on:", localAddress)
      try serverChannel.closeFuture.wait()
      print("Server closed")

    } catch {
      fatalError("failed to start server: \(error.localizedDescription)")
    }
  }
}
