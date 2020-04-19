import NIO

extension ByteBuffer {
  public var data: Data {
    .init(buffer: self)
  }
  
  public var string: String {
    .init(decoding: self.readableBytesView, as: UTF8.self)
  }
}

