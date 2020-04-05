import NIO
import NIOHTTP1
import struct Foundation.Data
import class Foundation.JSONEncoder

public class Response {
  public var status = HTTPResponseStatus.ok
  public var headers = HTTPHeaders()
  public var body = Body.empty

  public enum Body {
    case empty
    case buffer(ByteBuffer)
    case data(Data)
    case string(String)
  }

}

public extension Response {
  subscript(name: String) -> String? {
    set {
      if let value = newValue {
        headers.replaceOrAdd(name: name, value: value)
      } else {
        headers.remove(name: name)
      }
    }

    get {
      return headers[name].joined(separator: ", ")
    }
  }
}

public extension Response {
  func send(_ text: String) {
    body = .string(text)
  }

  func send(_ data: Data) {
    // TODO: Get proper content type.
    self["Content-Type"] = "application/json"
    self["Content-Length"] = "\(data.count)"
    body = .data(data)
  }

  func send<T: Encodable>(_ model: T) {
    let data : Data

    do {
      data = try JSONEncoder().encode(model)
      body = .data(data)
    } catch {
      print("Encoding error:", error)
    }
  }
}
