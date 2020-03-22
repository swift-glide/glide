# Glide
![Swift 5.1](https://img.shields.io/badge/Swift-5.1-orange.svg) [![GitHub release](https://img.shields.io/github/release/kaishin/glide.svg)](https://github.com/kaishin/glide/releases/latest) ![CI](https://github.com/kaishin/glide/workflows/Test/badge.svg)

A Swift micro-framework for server-side development.

⚠️ This is a work in progress and *should not* be used in production.

## Usage

### Getting Started

Start off by creating a Swift package for your own app:

```shell
mkdir APP_NAME
cd APP_NAME
swift package init --type executable --name APP_NAME
git init
```
In your `Package.swift` file, add the following line in `dependencies: [...]`:

```swift
.package(url: "https://github.com/kaishin/glide", .branch("master"))
```

And in the `targets` section, add Glide as a depdency to your main target:

```swift
targets: [
    .target(
      name: APP_NAME,
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
  response.send("Hello, 2020!")
}

// 4. Start listening on a given port
app.listen(1337)
```

#### Xcode

Double-click your `Package.swift` file so that it opens in Xcode. Wait for the dependencies to be automatically installed then run the project.

#### Command Line / Linux

If you are not using Xcode, run these commands in the terminal:

```shell
swift package update
swift build
swift run
```

Once the project is running either via Xcode or the Swift CLI, run the following in your terminal:

```shell
curl "http://localhost:1337/hello"
# -> "Hello, 2020!"
```

### Middleware

Glide uses a highly flexible middleware architecture. Each request will go through a chain of middleware functions matching its route and triggering side-effects such as reading from a database or fetching data from a remote server.

A middleware function receives a request, a response, and a closure. It can modify both the request and the response. It can also decide to to call the next closure to handover the request/response pair to the next middleware in the chain. It opts out of calling `next()`, it needs to finalize the response and send it back using one of the provided methods.

Whn an error occures in the bidy o fthe middleware function, it can be thrown and left for other error handlers to catch. More on error handling later.

The middleware signature is the following:

```swift
typealias Middleware = (
  _ request: Request,
  _ response: Response,
  _ next: @escaping () -> Void
) throws -> Void
```

Any function that has the same signature can be used as middleware. Here is a function that adds a response header to any response that goes through it.

```swift
func waldoMiddleware(
_ request: Request,
_ response: Response,
_ next: @escaping () -> Void
) throws {
  response["My-Header"] = "waldo"
  next()
}
```

To register the middleware, call the `use()` method on `Application` when configurring your app:

```swift
let app = Application()
app.use(waldoMiddleware)
```

For convenience, Glide introduces a number of middleware generators that handle the most common use cases such as creating passhtrough middleware, routing, CORS, etc. More on these in dedicated sections.

### Routing

Routing is the process of matching the path of a request to a specific middleware. Since it's a common operation, Glide provides dedicated middleware generators such as `get()`, `post()`, `patch()`, etc.

For example, if you want your app to return a list of todos when the user visist the `/todos` page, you can add a middleware like so:

```swift
app.get("/todos") { request, response in
  let todos = ... // Get a list of todos from a database, a file, a remote server, etc.
  
  response.json(todos)
}
```

Notice how the `get()`  middleware generator makes the next handler an implementation detail, letting you focus on the request and response instead. This also means that you have to finalize the response and send it back, int his case as a JOSN response using the `response.json()` helper.

#### Parameters & Queries

In the real world,  requests will likely have a path or query parameter in them. To tackle that, Glide uses custom string interpolation to create path expressions used for route matching. 

To illustrate, let's say that we want to return a specific todo to the end-user. We know that the `id` property of the todo is an `Int`. Here's how we can handle that:

```swift
app.get("/todos/\("id", as: Int.self)") { request, response in
  /* We specify the type of the variable to help the 
  compiler pick the right dynamic memeber lookup method. */
  let id: Int = request.pathParameters.id 
  
  if let todo = findTodo(id) {
    response.json(todo)
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
  let sortedTodos = ... // Get a list of todos with the sort order.
  
  response.json(sortedTodos)
}
```
and in the shell:

```shell
curl "http://localhost:1337/todos?sortOrder=ASC"
```

PS: Path and query parameters might change in the future based on usage feedback.

#### Wildcards

Sometimes a route has to match any request path, storing unnnamed path components for later perusal. In those case, the `wildcard` custom interploiation in `PathExpression` comes in handy:

```swift
app.get(/todos/\(wildcard: .all))
/* This will match all the following:
  /todos/foo/bar
  /todos
  /todos/23/baz/qux
*/
```

The path components after the wildcard are collected in the order they appear as strings in the `request.pathParameters.wildcards` array. Similary, `\(wildcard: .one)` can be used to mark only one path of the segment as an unnamed path parameter.

### Error Handling

_WIP_

### Static Files

_WIP_

## Roadmap

- ~Add error middleware.~
- ~Add support for path and query parameters.~
- ~Add support for static files~. _Streaming is not supported yet_.
- Add support for templating packages.
- Add support for sessions & cookies.
- Add support for uploads.
- Add support for redirects.
- Add support for state storage.
- Add support for Web forms.
