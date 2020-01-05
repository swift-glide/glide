# SwiftExpress

A Swift micro-framework for server-side developement. NOT PRODUCTION READY.

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
.package(url: "https://github.com/kaishin/swift-express", branch: "master")
```

Then, in the `main.swift` of your server-side app, add the following:

```swift
// 1. Import the framework
import SwiftExpress 

// 2. Instantiate the app
let app = SwiftExpress() 

// 3. Add a route.
app.get("/hello") { _, response, _ in
  response.send("Hello, 2020!")
}

// 4. Start listening on a given port
app.listen(1337)
```

Then in your temrinal:

```shell
curl http://localhost:1337/hello
# -> "Hello, 2020!"
```
