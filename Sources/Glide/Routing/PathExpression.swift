import Foundation

public struct PathExpression {
  var pathSegments = [Segment]()
  var querySegments = [Segment]()

  public init(_ segments: [Segment]) {
    if segments.contains(.querySeparator) {
      let parts = segments.split(
        separator: .querySeparator,
        maxSplits: 2,
        omittingEmptySubsequences: true
      )

      guard parts.count == 2 else {
        fatalError("Invalid path expression.")
      }

      pathSegments = Array(parts[0])
      querySegments = Array(parts[1])
    } else {
      pathSegments = segments
    }
  }
}

public func == (
  lhs: PathExpression.Segment,
  rhs: PathExpression.Segment
) -> Bool {
  switch (lhs, rhs) {
  case let (.literal(lhsValue), .literal(rhsValue)):
    return lhsValue == rhsValue
  case let (.wildcard(lhsValue), .wildcard(rhsValue)):
    return lhsValue == rhsValue
  case let (.parameter(lhsID, lhsType), .parameter(rhsID, rhsType)):
    return lhsID == rhsID && lhsType == rhsType
  case (.querySeparator, .querySeparator):
    return true
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
    case querySeparator
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
      case .querySeparator:
        return "?"
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

func parseSegments(
  _ string: String
) -> [PathExpression.Segment] {
  let querySeparator: [PathExpression.Segment] = string.contains("?") ? [.querySeparator] : []
  let parts = string.split(separator: "?")

  switch parts.count {
  case 1:
    return parts[0]
      .split { separator in return separator == "/" || separator == "&" }
      .compactMap({ PathExpression.Segment($0) })
      + querySeparator
  case 2:
    return parts[0]
      .split(separator: "/")
      .compactMap({ PathExpression.Segment($0) })
      + querySeparator
      + parts[1]
        .split(separator: "&")
        .compactMap({ PathExpression.Segment($0) })

  default:
    return querySeparator
  }
}

extension PathExpression: CustomStringConvertible {
  public var description: String {
    return "/"
      + pathSegments.map({ $0.description })
        .joined(separator: "/")
      + "?"
      + querySegments.map({ $0.description })
        .joined(separator: "&")
  }
}

extension PathExpression: ExpressibleByStringLiteral {
  public init(stringLiteral: String) {
    self = .init(parseSegments(stringLiteral))
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

    mutating public func appendInterpolation(literal value: String) {
      segments.append(.literal(value))
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
    self = .init(stringInterpolation.segments)
  }
}

extension PathExpression: URIMatching {
  public func match(_ url: String) -> URIMatchingResult {
    guard let urlComponents = URLComponents(string: url) else {
      return .notMatching
    }

    let pathParameters: Parameters

    do {
      pathParameters = try validatePathParameters(in: urlComponents)
    } catch {
      return .notMatching
    }

    guard querySegments.isEmpty else {
      do {
        let queryParameters = try validateQueryParameters(in: urlComponents)
        return .matching(
          pathParameters: pathParameters,
          queryParameters: queryParameters
        )
      } catch {
        return .notMatching
      }
    }

    return .matching(
      pathParameters: pathParameters,
      queryParameters: nil
    )
  }

  private func validatePathParameters(in urlComponents: URLComponents) throws -> Parameters {
    var parameters = Parameters()

    let segmentPairs = zip(
      pathSegments,
      urlComponents.segments
    )

    var wildcards: [Substring?] = urlComponents.segments

    for (index, pair) in segmentPairs.enumerated() {
      switch pair.0 {
      case .querySeparator:
        throw URIMatchingError.invalidSegment
      case .literal(let value):
        wildcards[index] = nil

        if value != pair.1 {
          throw URIMatchingError.missingSegment
        }

      case let .parameter(name, type) where type == String.self:
        parameters[name] = String(pair.1)
        wildcards[index] = nil

      case let .parameter(name, type):
        guard let value = type.init(String(pair.1)) else {
          throw URIMatchingError.missingSegment
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
          return parameters
        }
      }
    }

    if pathSegments.count == urlComponents.segments.count {
      return parameters
    } else {
      throw URIMatchingError.mismatchingSegmentCount
    }
  }


  private func validateQueryParameters(in urlComponents: URLComponents) throws -> Parameters {
    let parameters = queryParameters(with: urlComponents)
    var newParameters = Parameters()

    for segment in querySegments {
      switch segment {
      case .querySeparator:
        throw URIMatchingError.invalidSegment
      case .literal(let value):
        guard parameters[value] != nil else {
          throw URIMatchingError.missingSegment
        }

        newParameters.wildcards.append(Substring(value))

      case let .parameter(name, type) where type == String.self:
        guard let value = parameters[name] else {
          throw URIMatchingError.missingSegment
        }

        newParameters[name] = value

      case let .parameter(name, type):
        guard let value = parameters[name] as? String,
          let typedValue = type.init(value) else {
          throw URIMatchingError.missingSegment
        }

        newParameters[name] = typedValue
      default:
        continue
      }
    }

    return newParameters
  }
}


public extension URLComponents {
  var segments: [Substring] {
    path.split(separator: "/")
  }
}

func queryParameters(with urlComponents: URLComponents) -> Parameters {
  guard let queryItems = urlComponents.queryItems else { return .init() }

  return Parameters(storage: Dictionary(
    grouping: queryItems,
    by: { $0.name }
  ).mapValues {
    $0.compactMap({ $0.value })
      .joined(separator: ",")
    }
  )
}
