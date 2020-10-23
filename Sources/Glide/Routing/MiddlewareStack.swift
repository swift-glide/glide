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
        do {
          let outputFuture = try middleware(request, response)

          return outputFuture
            .flatMapError { error in
              self.errors.append(error)

              switch error {
              case let error as AbortError:
                return mainErrorHandler([error], self.request, self.response).flatMap {
                  self.response.middlewareOutput
                }
              default:
                return self.response.failure(error)
              }
            }
            .flatMap { output in
            switch output {
            case .next:
              return self.pop()
            case .text(let text, let type):
              return self.response.with(text, type: type)

            case .file(let path):
              do {
                return try sendFile(
                  at: path,
                  response: self.response,
                  request: self.request
                )
              } catch {
                return self.pop()
              }
            case .data(let data, let type):
              return self.response.with(data, type: type)
            }
          }
        } catch {
          errors.append(error)

          switch error {
          case let error as AbortError:
            return mainErrorHandler([error], request, response)
          default:
            return pop()
          }
        }
      } else {
       return Future<Void>.andAllSucceed(
          errorHandlers.map { $0(errors, request, response) },
          on: response.eventLoop
        ).flatMap {
          mainErrorHandler(
            [InternalError.unhandledRoute],
            self.request,
            self.response
          )
        }
      }
    }
  }
}
