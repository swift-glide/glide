extension Router {
  final class MiddlewareStack {
    var stack: ArraySlice<Middleware>
    var errorHandlers: ArraySlice<ErrorHandler>
    var errors = [Error]()
    let request: Request
    let response: Response

    init(
      stack: ArraySlice<Middleware>,
      errorHandlers: ArraySlice<ErrorHandler>,
      request: Request,
      response: Response
    ) {
      self.stack = stack
      self.errorHandlers = errorHandlers
      self.request = request
      self.response = response
    }

    func pop() -> Future<Void> {
      if let middleware = stack.popFirst() {
        return nonThrowing(middleware)(request, response)
          .flatMap { output in
            switch output {
            case .next:
              return self.pop()

            case .text(let text, let type):
              return self.response.with(text, type: type)

            case .file(let path):
              return sendFile(
                at: path,
                response: self.response,
                request: self.request
              )

            case .data(let data, let type):
              return self.response.with(data, type: type)
            }
          }
          .flatMapError { error in
            switch error {
            case let error as AbortError:
              return self.processErrors(serializing: error)
            default:
              self.errors.append(error)
              return self.pop()
            }
          }
      } else {
        return processErrors()
      }
    }

    private func processErrors(serializing error: Error = GlideError.unhandledRoute) -> Future<Void> {
      errors.append(error)

      return Future<Void>.andAllSucceed(
        errorHandlers.map { $0(errors, request, response) },
        on: response.eventLoop
      )
      .flatMap {
        errorSerializer(
          [error],
          self.request,
          self.response
        )
      }
    }
  }
}
