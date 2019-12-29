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

  func handle(request: Request,
              response: Response,
              next: @escaping Next) {
    let stack = MiddlewareStack(stack: middleware[middleware.indices],
                                request: request,
                                response: response,
                                next: next)
    stack.step()
  }
}

extension Router {
  final class MiddlewareStack {
    var stack: ArraySlice<Middleware>
    let request: Request
    let response: Response
    var next: Next?

    init(stack: ArraySlice<Middleware>,
         request: Request,
         response: Response,
         next: Next?) {
      self.stack = stack
      self.request = request
      self.response = response
      self.next = next
    }

    func step(_ args: Any...) {
      if let middleware = stack.popFirst() {
        middleware(request, response, self.step)
      } else {
        next?()
        next = nil
      }
    }
  }
}
