import Foundation
import NIOHTTP1

public protocol URIMatching {
  func match(_ url: String) -> URIMatchingResult
}

public enum URIMatchingResult {
  case notMatching
  case matching(
    pathParameters: Parameters,
    queryParameters: Parameters?
  )

  public var isMatching: Bool {
    guard case .notMatching = self else { return true }
    return false
  }

  public var pathParameters: Parameters? {
    get {
      guard case let .matching(value, _) = self else { return nil }
      return value
    }

    set {
      guard case .matching = self, let newValue = newValue else { return }
      self = .matching(
        pathParameters: newValue,
        queryParameters: nil
      )
    }
  }

  public var queryParameters: Parameters? {
    guard case let .matching(_, value) = self else { return nil }
    return value
  }
}

enum URIMatchingError: Error {
  case invalidSegment
  case missingSegment
  case mismatchingSegmentCount
}

public func match<T: URIMatching>(
  _ method: HTTPMethod,
  request: Request,
  matcher: T
) -> Bool {
  guard request.header.method == method else { return false }

  let result = matcher.match(request.header.uri)

  switch result {
  case .notMatching:
    return false
  case let .matching(pathParameters, queryParameters):
    request.pathParameters = pathParameters

    request.queryParameters = {
      if let queryParameters = queryParameters {
        return queryParameters.merge(with: request.queryParameters)
      } else {
        return request.queryParameters
      }
    }()

    return true
  }
}
