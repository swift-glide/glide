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

  public func readEntireFile(at path: String) async throws -> ByteBuffer {
    var data = allocator.buffer(capacity: 0)

    return try readFile(at: path) { chunk in
      var newChunk = chunk
      data.writeBuffer(&newChunk)
      return self.eventLoop.makeSucceededFuture(())
    }.map { data }
  }

  public func readEntireFile(at path: String) throws -> Future<ByteBuffer> {
    var data = allocator.buffer(capacity: 0)

    return try readFile(at: path) { chunk in
      var newChunk = chunk
      data.writeBuffer(&newChunk)
      return self.eventLoop.makeSucceededFuture(())
    }.map { data }
  }

  private func readChunkedAsync(
    at path: String,
    fileSize: Int,
    chunkSize: Int,
    onRead: @escaping (ByteBuffer) async -> Void
  ) async throws {
    let fileHandle = try NIOFileHandle(path: path)

    // TODO: Use FileRegion(fileHandle: NIOFileHandle)
    let readFile = self.fileIO.readChunked(
      fileHandle: fileHandle,
      byteCount: fileSize,
      chunkSize: chunkSize,
      allocator: allocator,
      eventLoop: eventLoop
    ) { byteBuffer in
      let promise = eventLoop.makePromise(of: Void.self)

      promise.completeWithTask {
        await onRead(byteBuffer)
      }

      return promise.futureResult
    }

    readFile.whenComplete { _ in
      try? fileHandle.close()
    }

    return try await readFile.get()
  }
}
