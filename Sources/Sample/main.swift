import Foundation
import Glide
import NIOHTTP1

struct User: Codable {
  var id: Int
  var name: String = "user"
  var password: String = "password"
}

enum CustomError: LocalizedError {
  case missingUser
  case nonCriticalError

  var errorDescription: String? {
    switch self {
    case .missingUser:
      return "The user seems to be missing."
    default:
      return "Some non-critical error occured."
    }
  }
}

enum CustomAbortError: AbortError {
  case badCredentials

  public var code: Int {
    return 1224
  }

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

app.loadDotEnv()

if app.env["THREE"] != nil {
  print(".env file loaded!")
} else {
  print("No .env file detected.")
}

app.use(
  requestLogger,
  corsMiddleware(allowOrigin: "*"),
  staticFileHandler(path: "/static/\(wildcard: .all)")
)

app.catch(errorLogger)

app.get("/throw") { request, response in
  throw CustomError.nonCriticalError
}

app.get("/abort-sync") { _, _ in
  throw CustomAbortError.badCredentials
}

app.get("/abort-async") { request, response in
  throw CustomAbortError.badCredentials
}

app.get("/hello/\("name")") { request, response in
  response.send("Hello, \(request.pathParameters.name ?? "world")!")
}

app.get("/users/\("id", as: Int.self)") { request, response in
  func find(_ id: Int) -> User {
    User(id: id)
  }

  return try response.json(find(request.pathParameters.id ?? 0))
}

app.post("/post") { request, response in
  guard let data = request.body else {
    throw CustomError.missingUser
  }

  do {
    let user = try JSONDecoder().decode(User.self, from: data)
    return response.send("\(user.name)")
  } catch let error as DecodingError {
    throw error
  }
}

struct HTML: HTMLRendering {
  func render(_ eventLoop: EventLoop) async throws -> String {
    """
    <!doctype html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>We're Live!</title>
      </head>
      <body>
        Hello, world!
      </body>
    </html>
    """
  }
}

app.get("/html") { _, response in
  let renderer = HTML()
  return try await response.html(renderer)
}

app.listen(1337)
