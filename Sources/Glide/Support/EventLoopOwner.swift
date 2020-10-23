import Foundation

public protocol EventLoopOwner {
  var eventLoop: EventLoop { get }
}

public extension EventLoopOwner {
  var next: Future<MiddlewareOutput> {
    eventLoop.makeSucceededFuture(.next)
  }

  var success: Future<Void> {
    eventLoop.makeSucceededFuture(())
  }

  func success<T>(_ value: T) -> Future<T> {
    eventLoop.makeSucceededFuture(value)
  }

  func failure<T>(_ error: Error) -> Future<T> {
    eventLoop.makeFailedFuture(error)
  }
}
