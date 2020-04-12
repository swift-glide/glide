import Foundation
import NIO

public protocol HTMLRendering {
  func render(_ eventLoop: EventLoop) -> Future<String>
}
