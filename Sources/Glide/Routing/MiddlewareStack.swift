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
    
    func pop() async throws {
      if let middleware = stack.popFirst() {
        do {
          let output = try await middleware(request, response)
          switch output {
          case .next:
            return try await pop()
            
          case .text(let text, let type):
            return response.with(text, as: type)
            
          case .data(let data, let type):
            return response.with(data, as: type)
            
          case .file(let path):
            return try await sendFile(
              at: path,
              response: response,
              request: request
            )
          }
        } catch {
          switch error {
          case let error as AbortError:
            return try await processErrors(serializing: error)
            
          default:
            errors.append(error)
            return try await pop()
          }
        }
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
      
      return try await errorSerializer(
        [error],
        self.request,
        self.response
      )
    }
  }
}
