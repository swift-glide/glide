extension Router {
  final class AsyncMiddlewareStack {
    var stack: ArraySlice<AsyncMiddleware>
    var errorHandlers: ArraySlice<AsyncErrorHandler>
    var errors = [Error]()
    let request: Request
    let response: Response

    init(
      stack: ArraySlice<AsyncMiddleware>,
      errorHandlers: ArraySlice<AsyncErrorHandler>,
      request: Request,
      response: Response
    ) {
      self.stack = stack
      self.errorHandlers = errorHandlers
      self.request = request
      self.response = response
    }

    func pop() async throws {
      if let middleware = stack.popFirst() {
        let output = try await middleware(request, response)
        switch output {
        case .next:
          return try await pop()

        case .text(let text, let type):
          return response.with(text, as: type)

        case .data(let data, let `as`):
          <#code#>
        case .file(let path):
          <#code#>
        }
//        return nonThrowing(middleware)(request, response)
//          .flatMap { output in
//            switch output {
//            case .next:
//              return self.pop()
//
//            case .text(let text, let type):
//              return self.response.syncWith(text, as: type)
//
//            case .file(let path):
//              return sendFile(
//                at: path,
//                response: self.response,
//                request: self.request
//              )
//
//            case .data(let data, let type):
//              return self.response.syncWith(data, as: type)
//            }
//          }
//          .flatMapError { error in
//            switch error {
//            case let error as AbortError:
//              return self.processErrors(serializing: error)
//            default:
//              self.errors.append(error)
//              return self.pop()
//            }
//          }
      } else {
        return try await processErrors()
      }
    }

    private func processErrors(
      serializing error: Error = GlideError.unhandledRoute
    ) async throws {
      errors.append(error)

      for handler in errorHandlers {
        try await handler(errors, request, response)
      }

      return try await asyncErrorSerializer(
        [error],
        self.request,
        self.response
      )
    }
  }

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
              return self.response.syncWith(text, as: type)

            case .file(let path):
              return sendFile(
                at: path,
                response: self.response,
                request: self.request
              )

            case .data(let data, let type):
              return self.response.syncWith(data, as: type)
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

    private func processErrors(
      serializing error: Error = GlideError.unhandledRoute
    ) -> Future<Void> {
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
