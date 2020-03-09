import SwiftExpress
import Foundation
let app = SwiftExpress()

struct User: Codable {
  var name: String
  var password: String
}

app.use(
  consoleLogger,
  corsHandler(allowOrigin: "*")
)

app.get("/hello") { _, response in
  response.send("Hello, world!")
}

app.post("/post") { request, response in
  guard let data = request.body,
    let user = try? JSONDecoder().decode(User.self, from: data) else {
      response.send("Wrong data sent.")
      return
  }

  response.send("\(user.name)")
}

app.listen(1337)
