#if os(Linux)
import Glibc
#else
import Darwin
#endif

public enum Environment: Equatable {
  case development
  case testing
  case production
  case custom(String)

  public subscript(_ key: String) -> String? {
    return ProcessInfo.processInfo.environment[key]
  }
}

public struct EnvironmentFile {
  private var storage: [String: String]

  init(storage: [String : String]) {
    self.storage = storage
  }

  init(with string: String) {
    self.storage = parse(string)
  }

  public static func load(
    path: String,
    fileIO: NonBlockingFileIO,
    on eventLoop: EventLoop,
    overwrite: Bool = false
  ) -> EventLoopFuture<Void> {
    read(path: path, fileIO: fileIO, on: eventLoop)
      .map { $0.setEnv(overwrite: overwrite) }
  }

  private static func read(
    path: String,
    fileIO: NonBlockingFileIO,
    on eventLoop: EventLoop
  ) -> EventLoopFuture<EnvironmentFile> {
    fileIO.openFile(path: path, eventLoop: eventLoop).flatMap { arg -> EventLoopFuture<ByteBuffer> in
      fileIO.read(fileRegion: arg.1, allocator: .init(), eventLoop: eventLoop)
        .flatMapThrowing { buffer in
          try arg.0.close()
          return buffer
        }
    }.map { buffer in
      return .init(with: buffer.string)
    }
  }

  public func setEnv(overwrite: Bool = false) {
    for key in storage.keys {
      setenv(key, storage[key], overwrite ? 1 : 0)
    }
  }
}

public extension Application {
  func loadDotEnv(
    _ name: String = ".env",
    workingDirectory: String = workingDirectory
  ) {
    do {
      try EnvironmentFile.load(
        path: workingDirectory + "/" + name,
        fileIO: fileIO,
        on: loopGroup.next(),
        overwrite: false
      ).wait()
    } catch {
      print(error.localizedDescription)
    }

  }
}

private func parse(_ string: String) -> [String: String] {
  string.split(separator: "\n").reduce([String: String]()) { dict, line in
    let pair = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)

    switch pair.count {
    case 2:
      let key = pair[0]
      var value = pair[1]

      switch (value.first, value.last) {
      case ("\"", "\""), ("'", "'"):
        value = value.dropFirst().dropLast()
      default: break
      }

      var newDict = dict
      newDict[String(key)] = String(value)
      return newDict
    case 1:
      var newDict = dict
      newDict[String(pair[0])] = ""
      return newDict
    default: break
    }

    return dict
  }
}
