import Foundation
import Glide

struct User: Codable {
  var name: String
  var password: String
}

enum CustomError: Error {
  case missingUser

  var localizedDescription: String {
    switch self {
    case .missingUser:
      return "The user seems to be missing"
    }
  }
}

let app = Glide()

app.use(
  consoleLogger,
  corsHandler(allowOrigin: "*")
)

app.get("/hello") { _, response in
  response.send("Hello, world!")
}

app.post("/post") { request, response in
  guard let data = request.body else {
    throw CustomError.missingUser
  }

  let user = try JSONDecoder().decode(User.self, from: data)

  response.send("\(user.name)")
}

app.listen(1337)
