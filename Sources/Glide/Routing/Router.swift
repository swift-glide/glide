import Foundation
import NIOHTTP1
import NIO

public class Router {
  private var middleware = [Middleware]()
  private var errorHandlers = [ErrorHandler]()

  public func use(_ middleware: Middleware...) {
    self.middleware.append(contentsOf: middleware)
  }

  func unwind(
    request: Request,
    response: Response
  ) async throws {
    return try await MiddlewareStack(
      stack: middleware[middleware.indices],
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
}

// MARK: - HTTP Methods
extension Router {
  public func route<T: URIMatching>(
    _ method: HTTPMethod = .GET,
    _ uriMatcher: T,
    middleware: @escaping Middleware
  ) {
     use(
       Router.middleware(method, with: uriMatcher, and: middleware)
     )
   }

   public func route(
    _ method: HTTPMethod = .GET,
    _ expression: PathExpression,
    middleware: @escaping Middleware
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
    middleware: @escaping Middleware
  ) {
    use(
      Router.middleware(with: uriMatcher, and: middleware)
    )
  }

  public func get(
    _ expression: PathExpression,
    middleware: @escaping Middleware
  ) {
    use(
      Router.middleware(with: expression, and: middleware)
    )
  }

  // MARK: Post
  public func post<T: URIMatching>(
    _ uriMatcher: T,
    middleware: @escaping Middleware
  ) {
    use(
      Router.middleware(.POST, with: uriMatcher, and: middleware)
    )
  }

  public func post(
    _ expression: PathExpression,
    middleware: @escaping Middleware
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
    middleware: @escaping Middleware
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
    and middleware: @escaping Middleware
  ) -> Middleware {
    { request, response in
      guard match(method, request: request, matcher: matcher) else {
        return .next
      }

      return try await middleware(request, response)
    }
  }
}

func sendFile(
  at path: String,
  response: Response,
  request: Request
) async throws {
  let buffer = try await request.fileReader.readEntireFile(at: path)
  response.body = .buffer(buffer)
  return
}
