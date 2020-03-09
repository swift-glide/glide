import Foundation

let requestParameterKey = "com.redalemeden.swift-express.parameter"

public let parameterParser = {
  passthrough { request, response in
    guard let queryItems = URLComponents(string: request.header.uri)?.queryItems else { return }

    request.userInfo[requestParameterKey] = Dictionary(grouping: queryItems, by: { $0.name })
      .mapValues {
        $0.compactMap({ $0.value })
          .joined(separator: ",")
      }
  }
}()

public let consoleLogger = {
  passthrough { request, response in
    print("\(request.header.method):", request.header.uri)
  }
}()

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
