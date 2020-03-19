import Foundation

public protocol PathParsing {
  func parse(_ url: String) -> (
    isMatching: Bool,
    parameters: Parameters
  )
}

public struct PathExpression {
  var segments = [Segment]()
}

public extension PathExpression {
  enum WildcardScope: CustomStringConvertible {
    case segment
    case allTrailing

    public var description: String {
      switch self {
      case .segment:
        return "*"
      case .allTrailing:
        return "**"
      }
    }
  }

  enum Segment: Equatable, CustomStringConvertible {
    case literal(_ value: String)
    case int(_ identifier: String)
    case string(_ identifier: String)
    case wildcard(_ scope: WildcardScope = .segment)

    init?<T>(_ raw: T) where T: StringProtocol {
      let segment = String(raw)

      if segment.starts(with: ":") {
        let name = segment.dropFirst()
        self = .string(String(name))
      } else if !segment.isEmpty {
        self = .literal(String(segment))
      } else {
        return nil
      }
    }

    public var description: String {
      switch self {
      case .literal(let value):
        return value
      case .string(let identifier):
        return ":\(identifier)"
      case .int(let identifier):
        return ":\(identifier)"
      case .wildcard(let scope):
        return scope.description
      }
    }
  }
}

func parseSegments(_ string: String) -> [PathExpression.Segment] {
  return string.split(separator: "/").compactMap({ PathExpression.Segment($0) })
}

extension PathExpression: CustomStringConvertible {
  public var description: String {
    return "/" + segments.map({ $0.description }).joined(separator: "/")
  }
}

extension PathExpression: ExpressibleByStringLiteral {
  public init(stringLiteral: String) {
    self.segments = parseSegments(stringLiteral)
  }
}

extension PathExpression: ExpressibleByStringInterpolation {
  public struct StringInterpolation: StringInterpolationProtocol {
    var segments: [Segment] = []

    public init(literalCapacity: Int, interpolationCount: Int) {
      self.segments = []
      segments.reserveCapacity(literalCapacity + interpolationCount)
    }

    mutating public func appendLiteral(_ stringLiteral: String) {
      segments.append(contentsOf: parseSegments(stringLiteral))
    }

    mutating public func appendInterpolation(string identifier: String) {
      segments.append(.string(identifier))
    }

    mutating public func appendInterpolation(int identifier: String) {
      segments.append(.int(identifier))
    }

    mutating public func appendInterpolation(wildcard scope: WildcardScope) {
      segments.append(.wildcard(scope))
    }
  }

  public init(stringInterpolation: StringInterpolation) {
    self.segments = stringInterpolation.segments
  }
}

extension PathExpression: PathParsing {
  public func parse(_ url: String) -> (
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
      case .literal(let value):
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
      case .wildcard(let scope):
        switch scope {
        case .segment:
          parameters.wildcards.append(match.1)
        default:
          return (true, parameters)
        }
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
