public func cors(allowOrigin origin: String) -> Middleware {
  return { request, response, next in
    response["Access-Control-Allow-Origin"] = origin
    response["Access-Control-Allow-Headers"] = "Accept, Content-Type"
    response["Access-Control-Allow-Methods"] = "GET, OPTIONS"

    if request.header.method == .OPTIONS {
      response["Allow"] = "GET, OPTIONS"
      response.send("")
    } else {
      next()
    }
  }
}
