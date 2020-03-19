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


public func == (lhs: PathExpression.Segment, rhs: PathExpression.Segment) -> Bool {
  switch (lhs, rhs) {
  case let (.literal(lhsValue), .literal(rhsValue)):
    return lhsValue == rhsValue
  case let (.wildcard(lhsValue), .wildcard(rhsValue)):
    return lhsValue == rhsValue
  case let (.parameter(lhsID, lhsType), .parameter(rhsID, rhsType)):
    return lhsID == rhsID && lhsType == rhsType
  default:
    return false
  }
}

public extension PathExpression {
  enum WildcardScope: CustomStringConvertible {
    case one
    case all

    public var description: String {
      switch self {
      case .one:
        return "*"
      case .all:
        return "**"
      }
    }
  }

  enum Segment: CustomStringConvertible, Equatable {
    case literal(_ value: String)
    case parameter(_ identifier: String, type: ParameterRepresentable.Type = String.self)
    case wildcard(_ scope: WildcardScope = .one)

    init?<T>(_ raw: T) where T: StringProtocol {
      let segment = String(raw)

      if segment.starts(with: ":") {
        let name = segment.dropFirst()
        self = .parameter(String(name))
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
      case .parameter(let identifier, _):
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

    mutating public func appendInterpolation(wildcard scope: WildcardScope) {
      segments.append(.wildcard(scope))
    }

    mutating public func appendInterpolation<T: ParameterRepresentable>(as name: String, type: T.Type) {
        segments.append(.parameter(name, type: type))
      }

    mutating public func appendInterpolation(as name: String) {
      segments.append(.parameter(name, type: String.self))
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
      case .parameter(let name, let type):
        if type == String.self {
          parameters[name] = match.1
        } else if let value = type.init(String(match.1)) {
          parameters[name] = value
        } else {
          return (false, parameters)
        }
      case .wildcard(let scope):
        switch scope {
        case .one:
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
