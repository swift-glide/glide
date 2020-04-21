let parameterParsingHandler: SyncHTTPHandler = { request, response in
  guard let components = URLComponents(string: request.head.uri)
    else { return }

  request.queryParameters = queryParameters(with: components)
}

public let parameterParser = {
  passthrough(parameterParsingHandler)
}()
