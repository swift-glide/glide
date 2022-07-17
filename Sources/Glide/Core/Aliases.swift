import Foundation
import NIO

public typealias Future = EventLoopFuture

public typealias Handler = () -> Future<Void>
public typealias ThrowingMiddleware = (Request, Response) throws -> Future<MiddlewareOutput>
public typealias Middleware = (Request, Response) -> Future<MiddlewareOutput>

public typealias ThrowingSyncHTTPHandler = (Request, Response) throws -> Void
public typealias SyncHTTPHandler = (Request, Response) -> Void

public typealias ErrorHandler = ([Error], Request, Response) -> Future<Void>
public typealias SyncErrorHandler = ([Error], Request, Response) -> Void

func nonThrowing(_ middleWare: @escaping ThrowingMiddleware) -> Middleware {
  { request, response in
    do {
      return try middleWare(request, response)
    } catch {
      return request.failure(error)
    }
  }
}

// Async

public typealias AsyncHandler = () async -> Void
public typealias AsyncMiddleware = (Request, Response) async throws -> MiddlewareOutput
public typealias AsyncErrorHandler = ([Error], Request, Response) async throws -> Void
