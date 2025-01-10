import Foundation
import NIO

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

public let workingDirectory: String = {
  let cwd = getcwd(nil, Int(PATH_MAX))
  defer { free(cwd) }
  return cwd.flatMap { String(validatingUTF8: $0) } ?? "./"
}()

public func staticFileHandler(_
  directory: String = "/Public",
  workingDirectory: String = workingDirectory,
  path: PathExpression? = nil
) -> Middleware {
  let assetDirName = directory.hasPrefix("/") ? String(directory.dropFirst()) : directory
  var assetPath = workingDirectory + "/" + assetDirName
  assetPath = assetPath.hasSuffix("/") ? String(assetPath.dropFirst()) : assetPath

  print("Serving static files from: \(assetPath)")

  let path = path ?? "\(wildcard: .all)"

  return Router.middleware(.GET, with: path) { request, response in
    let filePath = request.pathParameters.wildcards.joined(separator: "/")
    return response.file("\(assetPath)/\(filePath)")
  }
}

public func staticFileMiddleware(
  _
  directory: String = "/Public",
  workingDirectory: String = workingDirectory,
  path: PathExpression? = nil
) -> Middleware {
  let assetDirName = directory.hasPrefix("/") ? String(directory.dropFirst()) : directory
  var assetPath = workingDirectory + "/" + assetDirName
  assetPath = assetPath.hasSuffix("/") ? String(assetPath.dropFirst()) : assetPath

  print("Serving static files from: \(assetPath)")

  let path = path ?? "\(wildcard: .all)"

  return Router.middleware(.GET, with: path) { request, response in
    let filePath = request.pathParameters.wildcards.joined(separator: "/")
    return response.file("\(assetPath)/\(filePath)")
  }
}

