import Foundation

struct PathBuilder {
  var segments = [PathSegmentDescriptor]()

  func match(_ url: String) -> (
    isMatching: Bool,
    parameters: Parameters
    ) {
    var parameters = Parameters()

    guard let urlComponents = URLComponents(string: url) else {
      return (false, parameters)
    }

    let matches = zip(segments, urlComponents.segments)

    for match in matches {
      switch match.0 {
      case .constant(let value):
        if value != match.1 {
          return (false, parameters)
        }
      case .int(let name):
        if let value = Int(match.1) {
          parameters[name] = value
        } else {
          return (false, parameters)
        }
      case .string(let name):
        parameters[name] = match.1
      case .wildcard:
        parameters.wildcards.append(match.1)
      case .matchAll:
        return (true, parameters)
      }
    }

    return (segments.count == urlComponents.segments.count, parameters)
  }
}

public extension URLComponents {
  var segments: [Substring] {
    path.split(separator: "/")
  }
}
