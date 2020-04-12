import Foundation
import NIO

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

public enum ContentType: String {
  case plainText = "text/plain; charset=utf-8"
  case json = "application/json; charset=utf-8"
  case html = "text/html; charset=utf-8"
  case xml = "application/html; charset=utf-8"
}

public enum MiddlewareOutput {
  case next
  case send(String, as: ContentType = .plainText)
  case data(Data, as: ContentType = .json)
  case file(String)
  
  public static func json<T: Encodable>(_ model: T) -> Self {
    if let data = try? JSONEncoder().encode(model) {
      return .data(data)
    } else {
      return .next
    }
  }
}

public typealias Handler = () -> Future<Void>
public typealias Middleware = (Request, Response) throws -> Future<MiddlewareOutput>
public typealias HTTPHandler = (Request, Response) throws -> Future<Void>
public typealias ErrorHandler = ([Error], Request, Response) -> Future<Void>

public func passthrough(_ perform: @escaping HTTPHandler) -> Middleware {
  return { request, response in
    try perform(request, response).map { .next }
  }
}

// MARK: - Built-in Middleware

let parameterParsingHandler: HTTPHandler = { request, response in
  guard let components = URLComponents(string: request.header.uri)
    else { return request.successFuture }

  request.queryParameters = queryParameters(with: components)
  return request.successFuture
}

public let parameterParser = {
  passthrough(parameterParsingHandler)
}()

public let consoleLogger = {
  passthrough { request, response in
    print("\(request.header.method):", request.header.uri)
    return  request.successFuture
  }
}()

public let errorLogger: ErrorHandler = { errors, request, response in
  errors.forEach {
    print("Error:", $0.localizedDescription)
  }

  return request.successFuture
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

  return Router.middleware(.GET, with: path) { request, response in
    let filePath = request.pathParameters.wildcards.joined(separator: "/")
    return response.file("\(assetPath)/\(filePath)")
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
      return response.send("")
    } else {
      return request.next()
    }
  }
}


