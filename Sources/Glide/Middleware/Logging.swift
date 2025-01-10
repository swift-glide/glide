public let requestLogger = {
  passthrough { request, response in
    print("\(request.head.method):", request.head.uri)
  }
}()

public let errorLogger: ErrorHandler = { errors, request, response in
  errors.forEach { error in
    let errorResponse = Router.ErrorResponse.from(error)

    if let code = errorResponse.code {
      print("Error \(code):", errorResponse.error)
    } else {
      print("Error:", errorResponse.error)
    }
  }
}


