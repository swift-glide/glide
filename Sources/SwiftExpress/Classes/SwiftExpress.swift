import Foundation
import NIO
import NIOHTTP1

public final class SwiftExpress: Router {
  let loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

  public override init() {
    super.init()
    use(parameterParser)
  }

  public func listen(_ port: Int,
                     _ host: String = "localhost",
                     _ backlog: Int = 256) {
    let bootstrap = makeServerBootstrap(backlog)

    do {
      let serverChannel = try bootstrap.bind(host: host, port: port).wait()

      guard let localAddress = serverChannel.localAddress else {
        fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
      }

      print("Server running on http://localhost:\(localAddress.port!)")
      try serverChannel.closeFuture.wait()
      print("Server closed")

    } catch {
      fatalError("Failed to start server: \(error.localizedDescription)")
    }
  }

  public func listen(unixSocket: String = "swift-express.socket",
                     backlog: Int = 256) {
    let bootstrap = makeServerBootstrap(backlog)

    do {
      let serverChannel = try bootstrap.bind(unixDomainSocketPath: unixSocket).wait()
      print("Server running on:", socket)

      try serverChannel.closeFuture.wait()
    } catch {
      fatalError("Failed to start server: \(error.localizedDescription)")
    }
  }

  private func makeServerBootstrap(_ backlog: Int) -> ServerBootstrap {
    let localAddressReuseOption = ChannelOptions.socket(
      SocketOptionLevel(SOL_SOCKET),
      SO_REUSEADDR
    )

    let bootstrap = ServerBootstrap(group: loopGroup)
      .serverChannelOption(ChannelOptions.backlog, value: Int32(backlog))
      .serverChannelOption(localAddressReuseOption, value: 1)
      .childChannelInitializer { channel in
        channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
          channel.pipeline.addHandler(HTTPServerHandler(router: self))
        }
    }
    .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
    .childChannelOption(localAddressReuseOption, value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)

    return bootstrap

  }
}
