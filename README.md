# Glide
![Swift 5.2](https://img.shields.io/badge/Swift-5.2-orange.svg) [![GitHub release](https://img.shields.io/github/release/kaishin/glide.svg)](https://github.com/kaishin/glide/releases/latest) ![CI](https://github.com/kaishin/glide/workflows/Test/badge.svg)

A Swift micro-framework for server-side development. Inspired by Express, Sinatra, Flask, etc.

⚠️ This is a work in progress and *should not* be used in production.

## Usage

### Getting Started

Start by creating a Swift package for your own app:

```shell
mkdir APP_NAME
cd APP_NAME
swift package init --name APP_NAME
git init
```

In your `Package.swift` file, add the following line in `dependencies: [...]`:

```swift
.package(url: "https://github.com/kaishin/glide", from: "0.4.0")
```

And in the `targets` section, add Glide as a dependency to your main target:

```swift
targets: [
  .target(
    name: "APP_NAME",
    dependencies: ["Glide"]
  )
```

Then, in the `main.swift` of your server-side app, add the following:

```swift
// 1. Import the framework
import Glide

// 2. Instantiate the app
let app = Application()

// 3. Add a route.
app.get("/hello") { _, response in
  response.text("Hello, world!")
}

// 4. Start listening on a given port
app.listen(1337)
```

If you are using Xcode, double-click the `Package.swift` file so that it opens in the IDE. Wait for the dependencies to be automatically installed then run the project.

Otherwise, run these commands in the terminal:

```shell
swift package update
swift build
swift run
```

Once the project is running either via Xcode or the CLI, run the following in your terminal:

```shell
curl "http://localhost:1337/hello"
# -> "Hello, world!"
```

### Middleware

Glide uses middleware to process requests. Each request is passed down from one middleware to the next one in the chain, triggering side-effects such as reading from a database or fetching JSON from a remote server.

A middleware function receives a request and a response and return a future (of type  `EventLoopFuture`, aliased to `Future` in Glide) that wraps an output value. It can modify both the request and the response, which are reference types.

When an error occurs in the body of the middleware function, it can be thrown and subsequently caught by error handlers.

The signature of a middleware function looks as follows:

```swift
(Request, Response) throws -> EventLoopFuture<MiddlewareOutput>
```

Where `MiddlewareOutput` is an enum with the following possible cases:

```swift
enum MiddlewareOutput {
  case next
  case text(String)
  case data(Data)
  case file(String)
  
  static func json<T: Encodable>(_ model: T) -> Self { ... }
}
```

As an example, here is a middleware function that adds a response header to any response that goes through it.

```swift
func waldoMiddleware(
  _ request: Request, 
  _ response: Response
) throws -> EventLoopFuture<MiddlewareOutput> {
  response["My-Header"] = "waldo"
  return request.next()
}
```

To register the middleware, call the `use()` method on your `Application` instance during configuration:

```swift
let app = Application()
app.use(waldoMiddleware)
```

For convenience, Glide introduces a number of middleware generators that handle the most common use cases such as routing, CORS, etc. More on these below.

### Routes

In Glide, routes are also defined as middleware. Every route middleware is constrained using a path and an HTTP verb.

For example, to return todos when the user visits `/todos`:

```swift
app.get("/todos") { request, response in
  let todos = ... // Load todos from database.
  return response.json(todos)
}
```

#### Parameters & Queries

In the real world, route URLs will likely use path or query parameters. Glide uses custom string interpolation to achieve that.

Let's say that we want to return a specific todo to the end user. We know that the `id` property of the todo is an `Int`.

```swift
app.get("/todos/\("id", as: Int.self)") { request, response in
  let id: Int = request.pathParameters.id 
  
  if let todo = findTodo(id) {
    return .json(todo)
  } else {
    throw CustomError.todoNotFound  
  }
}
```

If we are interested in the parameter as a string, the above can be shortened to `get("/todos/\("id"))`.
Query parameters work in a similar fashion:

```swift
app.get("/todos") { request, response in
  let sortOrder = request.queryParameters.sortOrder ?? "DESC"
  let sortedTodos = ...
  return .json(sortedTodos)
}

// Example: http://localhost:1337/todos?sortOrder=ASC
```

Query parameters are optional for route matching, but you can require the presence of a query parameter like so:

```swift
app.get("/todos?\("sortOrder")") { ... }

// /todos?foo=true will *not* match the middleware above.
```

#### Wildcards

Sometimes a route needs to match any request path, storing nameless path components for later use. For such cases, the `wildcard` custom interpolation in `PathExpression` comes in handy:

```swift
app.get(/todos/\(wildcard: .all))
/* This will match all of the following:
  /todos/foo/bar
  /todos
  /todos/23/baz/qux
*/
```

The path components after the wildcard are collected in the order they appear as strings in the `request.pathParameters.wildcards` array. Similarly, `\(wildcard: .one)` can be used to mark only one path of the segment as an nameless path parameter.

### Error Handling

The same way that successful request and response transformations can be passed down the middleware chain, errors can be passed down the _error handler_ chain.

#### Throwing Errors

Any middleware function can throw errors either sync or async.

```swift
enum CustomError: Error {
  case someError
}

app.get("/throw") { _, _ in
  throw CustomError.someError
}
```

In the example above, the route middleware throws an error synchronously. The error can also be thrown asynchronously using `EventLoopFuture`.

```swift
app.get("/throw-async") { request, response in
  request.failure(CustomError.someError)
}
```

Async errors integrate well with other NIO-based libraries and are thus the preferred way of bubbling up errors.

#### Error Types

Glide distinguishes between two kind of errors.

- **Abort errors** are errors that shortcut the middleware chain when they occur. They have an HTTP status code and a reason. When they occur, they are serialized into a response and sent back to the client. All abort errors conform to the `AbortError` protocol, which itself conforms to `LocalizedError`.

- **Generic errors** are errors that _do not_ shortcut the middleware chain and are not serialized as a response. Instead, they can be handled using custom error handlers. Internal errors can be any `Error` type that does not conform to `AbortError`.

Consider this example;

```swift
enum CustomAbortError: AbortError {
  case badCredentials

  var code: Int { return 1224 }
  var status: HTTPResponseStatus { return .badRequest }
  var reason: String { "Wrong credentials." }
}

app.get("/abort") { request, response in
  request.failure(CustomAbortError.badCredentials)
}

// $ curl http://localhost:1337/abort
// HTTP/1.1 400 Bad Request
// { "code": 1224, "error": "Wrong credentials." }
```

It's worth noting that when a middleware throws a non-aborting error, the request and respons epair is passed to the next middleware. If no middleware handles the pair, an `unhandledRoute` is thrown and serialized as a response.

```json
{ "error": "No middleware found to handle this route." }
```

#### Custom Error Handlers

Error handlers are middleware functions with an extra superpower: they get access to all non-aborting errors thrown by other middleware.

```swift
([Error], Request, Response) -> EventLoopFuture<Void> // Async
([Error], Request, Response) -> Void // Sync
```

 For example, here is a custom error handler that prints the final error count to the console:

 ```swift
 func consoleErrorLogger(
   _ errors: [Error], 
   _ request: Request, 
   _ response: Response
) {
  print(errors.count, "error(s) encountered.")
}
 ```

To register an error handler, use the `catch` instance method on `Application`:

```swift
app.catch(consoleErrorLogger)
```

Glide ships with a basic `errorLogger` that you can register when configuring your app. In most cases however, you want to define your own.

### Static Files

If you need to serve static files, register the `staticFileHandler` built-in middleware when configuring the app.

```swift
app.use(
  staticFileHandler(path: "/static/\(wildcard: .all)")
)
```

You can use a wildcard to match all files, or a literal value. The path needs to be relative to the working directory, which corresponds to the project root when running the app from the CLI, or manually set in Xcode.

By default, the static file middleware looks for files in the `/Public` folder. You can register more than one file handling middleware.

## Roadmap

- ~Add error middleware.~
- ~Add support for path and query parameters.~
- ~Add support for static files~. _Streaming is not supported yet_.
- ~Add support for templating packages.~
- Add support for sessions & cookies.
- Add support for HTTP/2.
- Add support for Websockets.
- Add support for uploads.
- Add support for redirects.
- Add support for state storage.
- Add support for Web forms.

## License

See LICENSE file.
