import Foundation

let errorSerializer: ErrorHandler = { errors, request, response in
  guard let error = errors.first else {
    assertionFailure("No errors were passed to the main error handler.")
    return response.success
  }

  let errorDescription: String
  var code: Int? = nil
  response.setContentType(.json)

  switch error {
  case let error as GlideError:
    response.status = error.status
    errorDescription = error.description
  case let error as AbortError:
    response.status = error.status
    errorDescription = error.description
    code = error.code
  default:
    response.status = .internalServerError
    errorDescription = "Unknown internal error."
  }

  return response.with(
    Router.ErrorResponse(error: errorDescription, code: code)
  )
}
