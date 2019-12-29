import NIOHTTP1

public final class ClientRequest {
  public let header: HTTPRequestHead
  public var userInfo = [String: Any]()

  init(header: HTTPRequestHead) {
    self.header = header
  }
}
