public let consoleLogger = {
  passthrough { request, response in
    print("\(request.head.method):", request.head.uri)
  }
}()

public let errorLogger: ErrorHandler = { errors, request, response in
  errors.forEach { error in
    let errorResponse = Router.ErrorResponse.from(error)

    let code = { () -> String in
      if let code = errorResponse.code {
        return " (\(code))"
      } else {
        return ""
      }
    }()

    print("Error\(code):", errorResponse.error)
  }

  return request.success
}


