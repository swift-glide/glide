import Foundation

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif


public enum MiddlewareResult {
  case next
  case send(String)
  case data(Data)
  case file(String)
  
  public static func json<T: Encodable>(_ model: T) -> Self {
    if let data = try? JSONEncoder().encode(model) {
      return .data(data)
    } else {
      return .next
    }
  }
}

public typealias Handler = () -> Void
public typealias Middleware = (Request, Response) throws -> MiddlewareResult
public typealias HTTPHandler = (Request, Response) throws -> Void
public typealias ErrorHandler = ([Error], Request, Response) -> Void

public func passthrough(_ perform: @escaping HTTPHandler) -> Middleware {
  return { request, response in
    try perform(request, response)
    return .next
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

  return Router.generate(.GET, with: path) { request, response in
    let filePath = request.pathParameters.wildcards.joined(separator: "/")
    return .file("\(assetPath)/\(filePath)")
  }
}

public func corsHandler(allowOrigin origin: String) -> Middleware {
  { request, response in
    response["Access-Control-Allow-Origin"] = origin
    response["Access-Control-Allow-Headers"] = "Accept, Content-Type"
    response["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS"
    response["Access-Control-Max-Age"] = "86400"

    if request.header.method == .OPTIONS {
      response["Allow"] = "POST, GET, OPTIONS"
      return .send("")
    } else {
      return .next
    }
  }
}


