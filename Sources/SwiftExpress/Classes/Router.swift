import Foundation

public class Router {
  private var middlewares = [Middleware]()

  public func use(_ middleware: Middleware...) {
    self.middlewares.append(contentsOf: middleware)
  }

  public func get(
    _ path: String = "",
    handler: @escaping HTTPHandler
  ) {
    use { request, response, nextHandler in
      guard request.header.method == .GET,
        request.header.uri.hasPrefix(path)
        else { return nextHandler() }

      finalize(handler)(request, response, nextHandler)
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

      finalize(handler)(request, response, nextHandler)
    }
  }

  func unwind(
    request: Request?,
    response: Response?,
    onComplete: @escaping HTTPHandler
  ) {
    guard let request = request,
      let response = response else {
        assertionFailure("Request and response were not initialized.")
        return
    }

    MiddlewareStack(
      stack: middlewares[middlewares.indices],
      request: request,
      response: response,
      onComplete: onComplete
    )
    .pop()
  }
}

extension Router {
  final class MiddlewareStack {
    var stack: ArraySlice<Middleware>
    let request: Request
    let response: Response

    /// Callback to call once all middlewares have been handled
    var onComplete: HTTPHandler?

    init(
      stack: ArraySlice<Middleware>,
      request: Request,
      response: Response,
      onComplete: HTTPHandler?
    ) {
      self.stack = stack
      self.request = request
      self.response = response
      self.onComplete = onComplete
    }

    func pop() {
      if let middleware = stack.popFirst() {
        middleware(request, response, self.pop)
      } else {
        onComplete?(request, response)
      }
    }
  }
}
