import NIO

public extension Future {
  func ignoreValue() -> EventLoopFuture<Void> {
    self.map { _ in () }
  }
}
