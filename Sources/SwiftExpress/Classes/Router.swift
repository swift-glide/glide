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
              next upperNext: @escaping Next) {

    let stack = self.middleware
    guard !stack.isEmpty else { return upperNext() }

    var next: Next? = { (args: Any...) in }
    var i = stack.startIndex

    next = { (args: Any...) in
      let middleware = stack[i]
      i = stack.index(after: i)
      middleware(request, response, i == stack.endIndex ? upperNext : next!)
    }

    next!()
  }

}
