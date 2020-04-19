public let consoleLogger = {
  passthrough { request, response in
    print("\(request.header.method):", request.header.uri)
  }
}()

public let errorLogger: ErrorHandler = { errors, request, response in
  errors.forEach {
    print("Error:", $0.localizedDescription)
  }

  return request.successFuture
}
