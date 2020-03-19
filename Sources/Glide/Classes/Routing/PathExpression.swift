import Foundation

public protocol PathParsing {
  func parse(_ url: String) -> (
    isMatching: Bool,
    parameters: Parameters?
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

    mutating public func appendInterpolation<T>(_ name: String, as type: T.Type)
      where T: ParameterRepresentable {
        segments.append(.parameter(name, type: type))
      }

    mutating public func appendInterpolation(_ name: String) {
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
    parameters: Parameters?
  ) {

    guard let urlComponents = URLComponents(string: url) else {
      return (false, nil)
    }

    var parameters = Parameters()
    let segmentPairs = zip(segments, urlComponents.segments)
    var wildcards: [Substring?] = urlComponents.segments

    for (index, pair) in segmentPairs.enumerated() {
      switch pair.0 {
      case .literal(let value):
        wildcards[index] = nil

        if value != pair.1 {
          return (false, nil)
        }

      case let .parameter(name, type) where type == String.self:
        parameters[name] = pair.1
        wildcards[index] = nil

      case let .parameter(name, type):
        guard let value = type.init(String(pair.1)) else {
          return (false, nil)
        }

        parameters[name] = value
        wildcards[index] = nil

      case .wildcard(let scope):
        switch scope {
        case .one:
          parameters.wildcards.append(pair.1)
          wildcards[index] = nil

        case .all:
          parameters.wildcards.append(contentsOf: wildcards.compactMap { $0 })
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
