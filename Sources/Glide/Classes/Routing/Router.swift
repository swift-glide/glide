import Foundation

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
  public func get(
    _ pathLiteral: String = "",
    handler: @escaping HTTPHandler
  ) {
    use { request, response, nextHandler in
      guard request.header.method == .GET else { return nextHandler() }

      let pathBuilder = PathBuilder(segments: pathSegmentParser.run(pathLiteral).match ?? [])
      let (isMatching, pathParameters) = pathBuilder.match(request.header.uri)

      if isMatching {
        request.pathParameters = .init(storage: pathParameters)
        try finalize(handler)(request, response, nextHandler)
      } else {
        return nextHandler()
      }
    }
  }


  public func get(
    _ segments: PathSegmentDescriptor...,
    handler: @escaping HTTPHandler
  ) {
    use { request, response, nextHandler in
      guard request.header.method == .GET else { return nextHandler() }

      let pathBuilder = PathBuilder(segments: segments)
      let (isMatching, pathParameters) = pathBuilder.match(request.header.uri)

      if isMatching {
        request.pathParameters = .init(storage: pathParameters)
        try finalize(handler)(request, response, nextHandler)
      } else {
        return nextHandler()
      }
    }
  }

  public func post(
    _ path: String = "",
    handler: @escaping HTTPHandler
  ) {
    use { request, response, nextHandler in
      guard request.header.method == .POST,
        request.header.uri.hasPrefix(path)
      else { return nextHandler() }

      try finalize(handler)(request, response, nextHandler)
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
