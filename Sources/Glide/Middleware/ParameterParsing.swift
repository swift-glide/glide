let parameterParsingHandler: SyncHTTPHandler = { request, response in
  guard let components = URLComponents(string: request.header.uri)
    else { return }

  request.queryParameters = queryParameters(with: components)
}

public let parameterParser = {
  passthrough(parameterParsingHandler)
}()
