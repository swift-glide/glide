import SwiftExpress
import HTMLKit

let app = SwiftExpress()

do {
  try app.htmlKit.registerLocalization(atPath: "./", defaultLocale: "en")
  try app.htmlKit.add(view: StaticPage())
  try app.htmlKit.add(view: HelloTemplate())
} catch {
  print(error.localizedDescription)
}

app.use { request, response, next in
  print("\(request.header.method):", request.header.uri)
  next()
}

// app.use(HTMLKit())
// app.views.add(SomeView())


app.use(
  parseParameters,
  cors(allowOrigin: "*")
)

app.get("/hello") { _, response, _ in
  response.send("Hello, Schwifty world!")
}

app.get("/html") { _, response, _ in
  response.render(HelloTemplate(), context: .init(name: "Reda", title: "Dinosaur"))
}

app.get("/static") { _, response, _ in
  response.render(StaticPage())
}

app.listen(1337)
