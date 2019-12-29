import SwiftExpress

let app = SwiftExpress()

app.use { request, response, next in
  print("\(request.header.method):", request.header.uri)
  next()
}

app.use(
  parseParameters,
  cors(allowOrigin: "*")
)

app.get { request, response, _ in
  let text = request.param("text") ?? "Schwifty"
  response.send("Hello, \(text) world!")
}

app.get("/hello") { _, response, _ in
  response.send("Hello, Schwifty world!")
}

app.get("/moo") { _, response, _ in
  response.send("Moo!")
}

app.listen(1337)
