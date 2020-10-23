public let consoleLogger = {
  passthrough { request, response in
    print("\(request.head.method):", request.head.uri)
  }
}()

public let errorLogger: ErrorHandler = { errors, request, response in
  errors.forEach {
    print("Error:", $0.localizedDescription)
  }

  return request.success
}
