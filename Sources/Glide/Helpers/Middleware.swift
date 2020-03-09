public typealias Handler = () -> Void
public typealias HTTPHandler = (Request, Response) -> Void

public typealias Middleware = (
  _ request: Request,
  _ response: Response,
  _ next: @escaping () -> Void
) -> Void

public func passthrough(_ perform: @escaping HTTPHandler) -> Middleware {
  return { request, response, nextHandler in
    perform(request, response)
    nextHandler()
  }
}

public func finalize(_ perform: @escaping HTTPHandler) -> Middleware {
  return { request, response, _ in
    perform(request, response)
  }
}
