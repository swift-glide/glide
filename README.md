# Glide
![Swift 5.1](https://img.shields.io/badge/Swift-5.1-orange.svg) [![GitHub release](https://img.shields.io/github/release/kaishin/glide.svg)](https://github.com/kaishin/glide/releases/latest)

A Swift micro-framework for server-side development.
⚠️ Not production ready.

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
let app = Glide()

// 3. Add a route.
app.get("/hello") { _, response, _ in
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
curl http://localhost:1337/hello
# -> "Hello, 2020!"
```

## Roadmap

- Add error middleware.
- Add support for templating packages.
- Add support for sessions & cookies.
- Add support for static file.
- Add support for uploads.
- Add support for redirects.
- Add support for state storage.
- Add support for Web forms.
- Add support for type-safe request parameters.
