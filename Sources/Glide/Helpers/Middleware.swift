import Foundation

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

public typealias Handler = () -> Void
public typealias HTTPHandler = (Request, Response) throws -> Void
public typealias ErrorHandler = ([Error], Request, Response) -> Void

public typealias Middleware = (
  _ request: Request,
  _ response: Response,
  _ next: @escaping () -> Void
) throws -> Void

public func passthrough(_ perform: @escaping HTTPHandler) -> Middleware {
  return { request, response, nextHandler in
    try perform(request, response)
    nextHandler()
  }
}

public func finalize(_ perform: @escaping HTTPHandler) -> Middleware {
  return { request, response, _ in
    try perform(request, response)
  }
}

// MARK: - Built-in Middleware

let parameterParsingHandler: HTTPHandler = { request, _ in
  guard let components = URLComponents(string: request.header.uri),
    let queryItems = components.queryItems else { return }

  request.queryParameters = Parameters(storage: Dictionary(
    grouping: queryItems,
    by: { $0.name }
  ).mapValues {
    $0.compactMap({ $0.value })
      .joined(separator: ",")
    }
  )
}

public let parameterParser = {
  passthrough(parameterParsingHandler)
}()

public let consoleLogger = {
  passthrough { request, response in
    print("\(request.header.method):", request.header.uri)
  }
}()

public let errorLogger: ErrorHandler = { errors, request, response in
  errors.forEach {
    print("Error:", $0.localizedDescription)
  }
}

let workingDirectory: String = {
  let cwd = getcwd(nil, Int(PATH_MAX))
  defer { free(cwd) }
  return cwd.flatMap { String(validatingUTF8: $0) } ?? "./"
}()

public func staticFileHandler(_ directory: String = "/static") -> Middleware {
  let assetDirName = directory.hasPrefix("/") ? String(directory.dropFirst()) : directory
  var assetPath = workingDirectory + "/" + assetDirName
  assetPath = assetPath.hasSuffix("/") ? String(assetPath.dropFirst()) : assetPath

  let path: PathExpression = "\(literal: assetDirName)/\(wildcard: .all)"
  return Router.generate(.GET, with: path) { request, response in
    let filePath = request.pathParameters.wildcards.joined(separator: "/")
    try response.file(at: "\(assetPath)/\(filePath)", for: request)
  }
}

public func corsHandler(allowOrigin origin: String) -> Middleware {
  { request, response, nextHandler in
    response["Access-Control-Allow-Origin"] = origin
    response["Access-Control-Allow-Headers"] = "Accept, Content-Type"
    response["Access-Control-Allow-Methods"] = "GET, OPTIONS"

    if request.header.method == .OPTIONS {
      response["Allow"] = "GET, OPTIONS"
      response.send("")
    } else {
      nextHandler()
    }
  }
}


