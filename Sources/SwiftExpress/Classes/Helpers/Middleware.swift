public typealias Next = (Any...) -> Void

public typealias Middleware = (
  Request,
  Response,
  @escaping Next
) -> Void
