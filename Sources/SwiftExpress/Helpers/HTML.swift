import HTMLKit

public func html(renderer: HTMLRenderer) -> Middleware {
  return { request, response, next in
    response.htmlRenderer = renderer
    next()
  }
}
