import Foundation
import NIOHTTP1
import NIO

public class Router {
  private var middlewares = [Middleware]()
  private var errorHandlers = [ErrorHandler]()

  public func use(_ middleware: ThrowingMiddleware...) {
    self.middlewares.append(contentsOf: middleware.map(nonThrowing))
  }

  func unwind(
    request: Request,
    response: Response
  ) -> Future<Void> {
    return MiddlewareStack(
      stack: middlewares[middlewares.indices],
      errorHandlers: errorHandlers[errorHandlers.indices],
      request: request,
      response: response
    )
    .pop()
  }
}

// MARK: - Error Handling
extension Router {
  public func `catch`(_ errorHandlers: ErrorHandler...) {
    self.errorHandlers.append(contentsOf: errorHandlers)
  }

  public func `catch`(_ handler: @escaping SyncErrorHandler) {
    self.errorHandlers.append({ errors, request, response in
      handler(errors, request, response)
      return request.success
    })
  }
}

// MARK: - HTTP Methods
extension Router {
  public func route<T: URIMatching>(
    _ method: HTTPMethod = .GET,
    _ uriMatcher: T,
    middleware: @escaping ThrowingMiddleware
  ) {
     use(
       Router.middleware(method, with: uriMatcher, and: middleware)
     )
   }

   public func route(
    _ method: HTTPMethod = .GET,
    _ expression: PathExpression,
    middleware: @escaping ThrowingMiddleware
   ) {
     use(
       Router.middleware(
        method,
        with: expression,
        and: middleware
       )
     )
   }

  // MARK: Get
  public func get<T: URIMatching>(
    _ uriMatcher: T,
    middleware: @escaping ThrowingMiddleware
  ) {
    use(
      Router.middleware(with: uriMatcher, and: middleware)
    )
  }

  public func get(
    _ expression: PathExpression,
    middleware: @escaping ThrowingMiddleware
  ) {
    use(
      Router.middleware(with: expression, and: middleware)
    )
  }

  // MARK: Post
  public func post<T: URIMatching>(
    _ uriMatcher: T,
    middleware: @escaping ThrowingMiddleware
  ) {
    use(
      Router.middleware(.POST, with: uriMatcher, and: middleware)
    )
  }

  public func post(
    _ expression: PathExpression,
    middleware: @escaping ThrowingMiddleware
  ) {
    use(
      Router.middleware(.POST, with: expression, and: middleware)
    )
  }

  // MARK: Put
  public func put<T: URIMatching>(
    _ uriMatcher: T,
    middleware: @escaping Middleware
  ) {
    use(
      Router.middleware(.PUT, with: uriMatcher, and: middleware)
    )
  }

  public func put(
    _ expression: PathExpression, 
    middleware: @escaping ThrowingMiddleware
  ) {
    use(
      Router.middleware(.PUT, with: expression, and: middleware)
    )
  }

  // MARK: Patch
  public func patch<T: URIMatching>(
    _ uriMatcher: T,
    middleware: @escaping Middleware
  ) {
    use(
      Router.middleware(.PATCH, with: uriMatcher, and: middleware)
    )
  }

  public func patch(
    _ expression: PathExpression,
    middleware: @escaping Middleware
  ) {
    use(
      Router.middleware(.PATCH, with: expression, and: middleware)
    )
  }

  // MARK: Delete
  public func delete<T: URIMatching>(_ uriMatcher: T, middleware: @escaping Middleware) {
    use(
      Router.middleware(.DELETE, with: uriMatcher, and: middleware)
    )
  }

  public func delete(
    _ expression: PathExpression,
    middleware: @escaping Middleware
  ) {
    use(
      Router.middleware(.DELETE, with: expression, and: middleware)
    )
  }

  // MARK: Private Members
  static func middleware<T: URIMatching>(
    _ method: HTTPMethod = .GET,
    with matcher: T,
    and middleware: @escaping ThrowingMiddleware
  ) -> Middleware {
    { request, response in
      guard match(method, request: request, matcher: matcher) else {
        return request.next
      }

      return nonThrowing(middleware)(request, response)
    }
  }
}

func sendFile(
  at path: String,
  response: Response,
  request: Request
) -> Future<Void> {
  do {
    return try request.fileReader.readEntireFile(at: path)
      .flatMap { buffer in
        response.body = .buffer(buffer)
        return response.success
      }
  } catch {
    return response.failure(error)
  }
}
