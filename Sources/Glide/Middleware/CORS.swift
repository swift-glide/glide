public func corsHandler(allowOrigin origin: String) -> Middleware {
  { request, response in
    response["Access-Control-Allow-Origin"] = origin
    response["Access-Control-Allow-Headers"] = "Accept, Content-Type"
    response["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS"
    response["Access-Control-Max-Age"] = "86400"

    if request.head.method == .OPTIONS {
      response["Allow"] = "POST, GET, OPTIONS"
      return response.send("")
    } else {
      return request.next()
    }
  }
}
