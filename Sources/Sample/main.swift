import SwiftExpress
import HTMLKit

let app = SwiftExpress()

app.use { request, response, next in
  print("\(request.header.method):", request.header.uri)
  next()
}

app.use(
  parseParameters,
  cors(allowOrigin: "*")
)

app.useHTML { html in
  html.addTemplate(view: HelloTemplate())
  html.addStaticPage(view: StaticPage())
  html.registerLocalization(atPath: "./", defaultLocale: "en")
}

app.get("/hello") { _, response, _ in
  response.send("Hello, world!")
}

app.get("/template") { _, response, _ in
  response.render(
    HelloTemplate(),
    context: .init(name: "Sam", title: "Porter")
  )
}

app.get("/static") { _, response, _ in
  response.render(StaticPage())
}

app.listen(1337)
