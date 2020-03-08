import SwiftExpress
import Foundation
let app = SwiftExpress()

app.use { request, response, next in
  print("\(request.header.method):", request.header.uri)
  next()
}

app.use(
  parseParameters,
  cors(allowOrigin: "*")
)

app.get("/hello") { _, response, _ in
  response.send("Hello, world!")
}

struct User: Codable {
  var name: String
  var password: String
}
app.post("/post") { request, response, _ in
  guard let data = request.body,
    let user = try? JSONDecoder().decode(User.self, from: data) else {
      response.send("Wrong data sent")
      return
  }

  response.send("\(user.name)")
}

app.listen(1337)
