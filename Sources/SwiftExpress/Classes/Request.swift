import NIOHTTP1

public final class Request {
  public let header: HTTPRequestHead
  public var userInfo = [String: Any]()

  init(header: HTTPRequestHead) {
    self.header = header
  }
}

public extension Request {
  func param(_ id: String) -> String? {
    let parameters = userInfo[paramDictKey] as? [String: String]
    return parameters?[id]
  }
}
