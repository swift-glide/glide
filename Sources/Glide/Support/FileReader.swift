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

    try await readFile(at: path) { chunk in
      var newChunk = chunk
      data.writeBuffer(&newChunk)
    }

    return data
  }

  public func readFile(
    at path: String,
    chunkSize: Int = NonBlockingFileIO.defaultChunkSize,
    onRead: @escaping (ByteBuffer) async -> Void
  ) async throws {
    let attributes = try FileManager.default.attributesOfItem(atPath: path)

    guard let fileSize = attributes[.size] as? NSNumber else {
      throw GlideError.assetNotFound
    }

    try await readChunked(
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
      future(on: eventLoop) {
        await onRead(byteBuffer)
      }
    }

    readFile.whenComplete { _ in
      try? fileHandle.close()
    }

    return try await readFile.get()
  }
}

func future<T>(
  on eventLoop: EventLoop,
  _ work: @escaping () async throws -> T
) -> EventLoopFuture<T> {
  let promise = eventLoop.makePromise(of: T.self)
  promise.completeWithTask { try await work() }
  return promise.futureResult
}
