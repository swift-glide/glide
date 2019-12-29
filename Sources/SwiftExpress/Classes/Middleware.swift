public typealias Next = (Any...) -> Void

public typealias Middleware = (
  ClientRequest,
  ServerResponse,
  @escaping Next
) -> Void
