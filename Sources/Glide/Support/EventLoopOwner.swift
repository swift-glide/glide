import Foundation
import NIO

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

  func syncSuccess<T>(_ value: T) -> Future<T> {
    eventLoop.makeSucceededFuture(value)
  }

  func failure<T>(_ error: Error) -> Future<T> {
    eventLoop.makeFailedFuture(error)
  }

  func nextAsync() async throws -> MiddlewareOutput {
    try await eventLoop.makeSucceededFuture(.next).get()
  }

  func failureAsync<T>(_ error: Error) async throws -> T {
    try await eventLoop.makeFailedFuture(error).get()
  }

  func successAsync<T>(_ value: T) async throws -> T {
    try await eventLoop.makeSucceededFuture(value).get()
  }
}

extension ChannelHandlerContext: EventLoopOwner {}
