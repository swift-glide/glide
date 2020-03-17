import Foundation

public enum PathSegmentDescriptor: Equatable {
  case constant(String)
  case int(String)
  case string(String)
  case wildcard
  case matchAll

  init?(_ string: Substring) {
    if string.isEmpty { return nil }

    let tokenMatch = pathToken.run(String(string))

    if let matchedToken = tokenMatch.match.map(String.init) {
      let parsed = prefix(while: { $0 != ":" }).run(matchedToken)
      let rest = parsed.rest
      let match = String(parsed.match ?? "")

      switch match {
      case "*":
        self = .wildcard
        return
      case "**":
        self = .matchAll
        return
      default:
        switch rest {
        case ":int":
          self = .int(match)
        case ":string":
          self = .string(match)
        default:
          self = .string(match)
        }
      }
    } else {
      self = .constant(String(string))
    }
  }
}

extension PathSegmentDescriptor: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .constant(value)
  }
}

let pathToken = charactersBetween(start: "{", end: "}")

let pathSegmentParser = zeroOrMore(
  prefix(while: { $0 != "/"}),
  separatedBy: literalParser("/"))
  .map { strings in
    strings.compactMap(PathSegmentDescriptor.init)
}
