let app = SwiftExpress()

app.use { request, response, next in
  print("\(request.header.method):", request.header.uri)
  next()
}

app.use { _, response, _ in
  response.send("Hello, Schwifty world!")
}

app.listen(1337)
