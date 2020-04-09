import Foundation

let mainErrorHandler: ErrorHandler = { errors, request, response in
  guard let error = errors.first else {
    assertionFailure("No errors were passed to the main error handler.")
    return request.successFuture
  }

  let errorDescription: String

  switch error {
  case let error as InternalError:
    response.status = error.status
    errorDescription = error.description
  case let error as AbortError:
    response.status = error.status
    errorDescription = error.description
  default:
    response.status = .internalServerError
    errorDescription = "Unknown internal error."
  }

  return response.send(
    Router.ErrorResponse(error: errorDescription)
  )
}
