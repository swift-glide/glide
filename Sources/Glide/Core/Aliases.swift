import Foundation
import NIO

public typealias Middleware = (Request, Response) async throws -> MiddlewareOutput
public typealias ErrorHandler = ([Error], Request, Response) async throws -> Void
public typealias HTTPHandler = (Request, Response) throws -> Void
