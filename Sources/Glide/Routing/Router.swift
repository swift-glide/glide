import Foundation
import NIOHTTP1
import NIO

public class Router {
  private var middlewares = [Middleware]()
  private var errorHandlers = [ErrorHandler]()

  public func use(_ middleware: Middleware...) {
    self.middlewares.append(contentsOf: middleware)
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
      return request.successFuture
    })
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
       Router.middleware(method, with: expression, and: middleware)
     )
   }

  // MARK: Get
  public func get<T: URIMatching>(_ uriMatcher: T, middleware: @escaping Middleware) {
    use(
      Router.middleware(with: uriMatcher, and: middleware)
    )
  }

  public func get(_ expression: PathExpression, middleware: @escaping Middleware) {
    use(
      Router.middleware(with: expression, and: middleware)
    )
  }

  // MARK: Post
  public func post<T: URIMatching>(_ uriMatcher: T, middleware: @escaping Middleware) {
    use(
      Router.middleware(.POST, with: uriMatcher, and: middleware)
    )
  }

  public func post(_ expression: PathExpression, middleware: @escaping Middleware) {
    use(
      Router.middleware(.POST, with: expression, and: middleware)
    )
  }

  // MARK: Put
  public func put<T: URIMatching>(_ uriMatcher: T, middleware: @escaping Middleware) {
    use(
      Router.middleware(.PUT, with: uriMatcher, and: middleware)
    )
  }

  public func put(_ expression: PathExpression, middleware: @escaping Middleware) {
    use(
      Router.middleware(.PUT, with: expression, and: middleware)
    )
  }

  // MARK: Patch
  public func patch<T: URIMatching>(_ uriMatcher: T, middleware: @escaping Middleware) {
    use(
      Router.middleware(.PATCH, with: uriMatcher, and: middleware)
    )
  }

  public func patch(_ expression: PathExpression, middleware: @escaping Middleware) {
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

  public func delete(_ expression: PathExpression, middleware: @escaping Middleware) {
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
        return request.next()
      }

      return try middleware(request, response)
    }
  }
}

extension Router {
  struct ErrorResponse: Codable {
    var error: String
  }
}

extension Router {
  final class MiddlewareStack {
    var stack: ArraySlice<Middleware>
    var errorHandlers: ArraySlice<ErrorHandler>
    var errors = [Error]()
    let request: Request
    let response: Response

    init(
      stack: ArraySlice<Middleware>,
      errorHandlers: ArraySlice<ErrorHandler>,
      request: Request,
      response: Response
    ) {
      self.stack = stack
      self.errorHandlers = errorHandlers
      self.request = request
      self.response = response
    }

    func pop() -> Future<Void> {
      if let middleware = stack.popFirst() {
        do {
          let outputFuture = try middleware(request, response)

          return outputFuture.flatMap { output in
            switch output {
            case .next:
              return self.pop()
            case .text(let text, let type):
              return self.response.with(text, type: type)

            case .file(let path):
              do {
                return try sendFile(
                  at: path,
                  response: self.response,
                  request: self.request
                )
              } catch {
                return self.pop()
              }
            case .data(let data, let type):
              return self.response.with(data, type: type)
            }
          }
        } catch {
          errors.append(error)

          switch error {
          case let error as AbortError:
            return mainErrorHandler([error], request, response)
          default:
            return pop()
          }
        }
      } else {
       return Future<Void>.andAllSucceed(
          errorHandlers.map { $0(errors, request, response) },
          on: response.eventLoop
        ).flatMap {
          mainErrorHandler(
            [InternalError.unhandledRoute],
            self.request,
            self.response
          )
        }
      }
    }
  }
}

fileprivate func sendFile(
  at path: String,
  response: Response,
  request: Request
) throws -> Future<Void> {
  try request.fileReader.readEntireFile(at: path)
    .flatMap { buffer in
      response.body = .buffer(buffer)
      return request.successFuture
  }
}
