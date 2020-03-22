import Foundation
import NIOHTTP1

public class Router {
  private var middlewares = [Middleware]()
  private var errorHandlers = [ErrorHandler]()

  public func use(_ middleware: Middleware...) {
    self.middlewares.append(contentsOf: middleware)
  }

  func unwind(
    request: Request?,
    response: Response?
  ) {
    guard let request = request,
      let response = response else {
        assertionFailure("Request and response were not initialized.")
        return
    }

    MiddlewareStack(
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
  public func use(_ errorHandler: ErrorHandler...) {
    self.errorHandlers.append(contentsOf: errorHandler)
  }

  public func handleErrors(_ errorHandler: ErrorHandler...) {
    self.errorHandlers.append(contentsOf: errorHandler)
  }
}

// MARK: - HTTP Methods
extension Router {
  // MARK: Get
  public func get<T>(_ pathParser: T, handler: @escaping HTTPHandler) where T: PathParsing {
    use(
      Router.generate(with: pathParser, and: handler)
    )
  }

  public func get(_ expression: PathExpression, handler: @escaping HTTPHandler) {
    use(
      Router.generate(with: expression, and: handler)
    )
  }


  // MARK: Post
  public func post<T>(_ pathParser: T, handler: @escaping HTTPHandler) where T: PathParsing {
    use(
      Router.generate(.POST, with: pathParser, and: handler)
    )
  }

  public func post(_ expression: PathExpression, handler: @escaping HTTPHandler) {
    use(
      Router.generate(.POST, with: expression, and: handler)
    )
  }

  // MARK: Put
  public func put<T>(_ pathParser: T, handler: @escaping HTTPHandler) where T: PathParsing {
    use(
      Router.generate(.PUT, with: pathParser, and: handler)
    )
  }

  public func put(_ expression: PathExpression, handler: @escaping HTTPHandler) {
    use(
      Router.generate(.PUT, with: expression, and: handler)
    )
  }


  // MARK: Patch
  public func patch<T>(_ pathParser: T, handler: @escaping HTTPHandler) where T: PathParsing {
    use(
      Router.generate(.PATCH, with: pathParser, and: handler)
    )
  }

  public func patch(_ expression: PathExpression, handler: @escaping HTTPHandler) {
    use(
      Router.generate(.PATCH, with: expression, and: handler)
    )
  }


  // MARK: Delete
  public func delete<T>(_ pathParser: T, handler: @escaping HTTPHandler) where T: PathParsing {
    use(
      Router.generate(.DELETE, with: pathParser, and: handler)
    )
  }


  public func delete(_ expression: PathExpression, handler: @escaping HTTPHandler) {
    use(
      Router.generate(.DELETE, with: expression, and: handler)
    )
  }


  // MARK: Private Members
  static func generate<T>(
    _ method: HTTPMethod = .GET,
    with builder: T,
    and handler: @escaping HTTPHandler
  ) -> Middleware  where T: PathParsing {
    { request, response, nextHandler in
      guard request.header.method == method else { return nextHandler() }

      let (isMatching, parameters) = builder.parse(request.header.uri)

      if isMatching, let params = parameters {
        request.pathParameters = params
        try finalize(handler)(request, response, nextHandler)
      } else {
        return nextHandler()
      }
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

    func pop() {
      if let middleware = stack.popFirst() {
        do {
          try middleware(request, response, self.pop)
        } catch {
          errors.append(error)

          switch error {
          case let error as AbortError:
            errorHandler([error], request, response)
          default:
            pop()
          }
        }
      } else {
        errorHandlers.forEach {
          $0(errors, request, response)
        }

        errorHandler([InternalError.unhandledRoute], request, response)
      }
    }
  }
}
