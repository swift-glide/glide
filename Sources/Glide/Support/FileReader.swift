import Foundation
import NIO

public struct FileReader {
  private var fileIO: NonBlockingFileIO
  private let allocator: ByteBufferAllocator
  private let eventLoop: EventLoop

  init(
    fileIO: NonBlockingFileIO,
    allocator: ByteBufferAllocator,
    eventLoop: EventLoop
  ) {
    self.fileIO = fileIO
    self.allocator = allocator
    self.eventLoop = eventLoop
  }

  public func readEntireFile(at path: String) throws -> Future<ByteBuffer> {
    var data = allocator.buffer(capacity: 0)

    return try readFile(at: path) { chunk in
      var newChunk = chunk
      data.writeBuffer(&newChunk)
      return self.eventLoop.makeSucceededFuture(())
    }.map { data }
  }

  public func readFile(
    at path: String,
    chunkSize: Int = NonBlockingFileIO.defaultChunkSize,
    onRead: @escaping (ByteBuffer) -> Future<Void>
  ) throws -> Future<Void> {
    let attributes = try FileManager.default.attributesOfItem(atPath: path)

    guard let fileSize = attributes[.size] as? NSNumber else {
        return eventLoop.makeFailedFuture(InternalError.assetNotFound)
     }

    return readChunked(
      at: path,
      fileSize: fileSize.intValue,
      chunkSize: chunkSize,
      onRead: onRead
    )
  }

  private func readChunked(
    at path: String,
    fileSize: Int,
    chunkSize: Int,
    onRead: @escaping (ByteBuffer) -> Future<Void>
  ) -> Future<Void> {
    do {
      let fileHandle = try NIOFileHandle(path: path)
      // TODO: Use FileRegion(fileHandle: NIOFileHandle)
      let readFile = self.fileIO.readChunked(
        fileHandle: fileHandle,
        byteCount: fileSize,
        chunkSize: chunkSize,
        allocator: allocator,
        eventLoop: eventLoop
      ) { onRead($0) }

      readFile.whenComplete { _ in
        try? fileHandle.close()
      }

      return readFile
    } catch {
      return eventLoop.makeFailedFuture(error)
    }
  }
}
