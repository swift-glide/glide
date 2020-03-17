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
  public func get(
    _ pathLiteral: String = "",
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(with: pathLiteral, and: handler)
    )
  }

  public func get(
    _ segments: PathSegmentDescriptor...,
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(with: segments, and: handler)
    )
  }

  public func get(
    _ pathMatcher: PathMatching,
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(with: pathMatcher, and: handler)
    )
  }

  // MARK: Post
  public func post(
    _ pathLiteral: String = "",
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.POST, with: pathLiteral, and: handler)
    )
  }

  public func post(
    _ segments: PathSegmentDescriptor...,
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.POST, with: segments, and: handler)
    )
  }

  public func post(
    _ pathMatcher: PathMatching,
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.POST, with: pathMatcher, and: handler)
    )
  }

  // MARK: Put
  public func put(
    _ pathLiteral: String = "",
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.PUT, with: pathLiteral, and: handler)
    )
  }

  public func put(
    _ segments: PathSegmentDescriptor...,
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.PUT, with: segments, and: handler)
    )
  }

  public func put(
    _ pathMatcher: PathMatching,
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.PUT, with: pathMatcher, and: handler)
    )
  }

  // MARK: Patch
  public func patch(
    _ pathLiteral: String = "",
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.PATCH, with: pathLiteral, and: handler)
    )
  }

  public func patch(
    _ segments: PathSegmentDescriptor...,
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.PATCH, with: segments, and: handler)
    )
  }

  public func patch(
    _ pathMatcher: PathMatching,
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.PATCH, with: pathMatcher, and: handler)
    )
  }

  // MARK: Delete
  public func delete(
    _ pathLiteral: String = "",
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.DELETE, with: pathLiteral, and: handler)
    )
  }

  public func delete(
    _ segments: PathSegmentDescriptor...,
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.DELETE, with: segments, and: handler)
    )
  }

  public func delete(
    _ pathMatcher: PathMatching,
    handler: @escaping HTTPHandler
  ) {
    use(
      generate(.DELETE, with: pathMatcher, and: handler)
    )
  }

  // MARK: Private Members
  private func generate(
    _ method: HTTPMethod = .GET,
    with pathLiteral: String = "",
    and handler: @escaping HTTPHandler
  ) -> Middleware {
    generate(method, with: PathBuilder(segments: pathSegmentParser.run(pathLiteral).match ?? []), and: handler)
  }

  private func generate(
    _ method: HTTPMethod = .GET,
    with segments: [PathSegmentDescriptor],
    and handler: @escaping HTTPHandler
  ) -> Middleware {
    generate(method, with: PathBuilder(segments: segments), and: handler)
  }

  private func generate(
    _ method: HTTPMethod = .GET,
    with builder: PathMatching,
    and handler: @escaping HTTPHandler
  ) -> Middleware {
    { request, response, nextHandler in
      guard request.header.method == method else { return nextHandler() }

      let (isMatching, parameters) = builder.match(request.header.uri)

      if isMatching {
        request.pathParameters = parameters
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
