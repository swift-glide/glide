public class Router {
  private var middleware = [Middleware]()

  public func use(_ middleware: Middleware...) {
    self.middleware.append(contentsOf: middleware)
  }

  public func get(_ path: String = "",
           middleware: @escaping Middleware) {
    use { request, response, next in
      guard request.header.method == .GET,
        request.header.uri.hasPrefix(path)
        else { return next() }

      middleware(request, response, next)
    }
  }

  public func post(_ path: String = "",
                   middleware: @escaping Middleware) {
    use { request, response, next in
      guard request.header.method == .POST,
        request.header.uri.hasPrefix(path)
      else { return next() }

      middleware(request, response, next)
    }
  }

  func handle(request: Request,
              response: Response,
              last: @escaping Next) {
    let stack = MiddlewareStack(stack: middleware[middleware.indices],
                                request: request,
                                response: response,
                                last: last)
    stack.step()
  }
}

extension Router {
  final class MiddlewareStack {
    var stack: ArraySlice<Middleware>
    let request: Request
    let response: Response
    var lastMiddleware: Next?

    init(stack: ArraySlice<Middleware>,
         request: Request,
         response: Response,
         last: Next?) {
      self.stack = stack
      self.request = request
      self.response = response
      self.lastMiddleware = last
    }

    func step(_ args: Any...) {
      if let middleware = stack.popFirst() {
        middleware(request, response, self.step)
      } else {
        lastMiddleware?()
        lastMiddleware = nil
      }
    }
  }
}
