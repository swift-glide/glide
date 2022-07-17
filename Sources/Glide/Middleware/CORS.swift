public func corsMiddleware(allowOrigin origin: String) -> Middleware {
  { request, response in
    response["Access-Control-Allow-Origin"] = origin
    response["Access-Control-Allow-Headers"] = "X-Requested-With, Origin, Content-Type, Accept"
    response["Access-Control-Allow-Methods"] = "POST, GET, PUT, OPTIONS, DELETE, PATCH"
    response["Access-Control-Max-Age"] = "86400"

    if request.head.method == .OPTIONS {
      response["Allow"] = "POST, GET, OPTIONS"
      return response.syncSend("")
    } else {
      return request.next
    }
  }
}

public func asyncCorsMiddleware(allowOrigin origin: String) -> AsyncMiddleware {
  { request, response in
    response["Access-Control-Allow-Origin"] = origin
    response["Access-Control-Allow-Headers"] = "X-Requested-With, Origin, Content-Type, Accept"
    response["Access-Control-Allow-Methods"] = "POST, GET, PUT, OPTIONS, DELETE, PATCH"
    response["Access-Control-Max-Age"] = "86400"

    if request.head.method == .OPTIONS {
      response["Allow"] = "POST, GET, OPTIONS"
      return try await response.send("")
    } else {
      return try await request.nextAsync()
    }
  }
}

