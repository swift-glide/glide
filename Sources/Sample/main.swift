import Foundation
import Glide
import NIOHTTP1

struct User: Codable {
  var id: Int
  var name: String = "user"
  var password: String = "password"
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

let app = Application()

app.use(
  consoleLogger,
  corsHandler(allowOrigin: "*"),
  staticFileHandler()
)

app.use(errorLogger, { errors, _, _ in
  print(errors.count, "error(s) encountered.")
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

app.get("/hello/\("name")") { request, response in
  response.send("Hello, \(request.pathParameters.name ?? "world")!")
}

app.get("/users/\("id", as: Int.self)") { request, response in
  func find(_ id: Int) -> User {
    User(id: id)
  }

  response.json(find(request.pathParameters.id ?? 0))
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
