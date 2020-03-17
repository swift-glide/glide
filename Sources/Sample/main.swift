import Foundation
import Glide
import NIOHTTP1

struct User: Codable {
  var name: String
  var password: String
}

enum CustomError: Error {
  case missingUser
  case nonCriticalError

  var localizedDescription: String {
    switch self {
    case .missingUser:
      return "The user seems to be missing"
    default:
      return "Unknown error"
    }
  }
}

enum CustomAbortError: AbortError {
  case badCredentials

  var status: HTTPResponseStatus {
    return .badRequest
  }

  var reason: String {
    "I don't know why..."
  }

  var description: String {
    "Bad stuff happened."
  }
}

let app = Glide()

app.use(
  consoleLogger,
  corsHandler(allowOrigin: "*")
)

app.use(errorLogger, { errors, _, _ in
  print(errors.count)
})

app.use { _, _, _ in
  throw CustomError.missingUser
}

app.get("/throw") { _, _ in
  throw CustomError.nonCriticalError
}

app.get("/abort") { _, _ in
  throw CustomAbortError.badCredentials
}

app.get("hello", .string("name")) { request, response in
  response.send("Hello, \(request.pathParameters.name ?? "world")!")
}

app.post("/post") { request, response in
  guard let data = request.body else {
    throw CustomError.missingUser
  }

  do {
    let user = try JSONDecoder().decode(User.self, from: data)
    response.send("\(user.name)")
  } catch let error as DecodingError {
    throw error
  }

}

app.listen(1337)
