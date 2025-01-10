extension Router {
  public struct ErrorResponse: Codable, Error {
    var error: String
    var code: Int?
  }
}

public extension Router.ErrorResponse {
  static func from(_ error: AbortError) -> Self {
    .init(error: error.description, code: error.code)
  }

  static func from(_ error: Error) -> Self {
    let errorDescription: String
    var code: Int? = nil

    switch error {
    case let error as AbortError:
      errorDescription = error.description
      code = error.code
    case let error as LocalizedError:
      errorDescription = error.errorDescription ?? error.localizedDescription
    default:
      errorDescription = "Unknown server error."
    }

    return .init(error: errorDescription, code: code)
  }
}
