import Foundation

public enum PathSegmentDescriptor: Equatable {
  case fixed(String)
  case int(String)
  case string(String)
  case anything
  case catchall

  init?(_ string: Substring) {
    if string.isEmpty { return nil }

    let tokenMatch = pathToken.run(String(string))

    if let matchedToken = tokenMatch.match.map(String.init) {
      let parsed = prefix(while: { $0 != ":" }).run(matchedToken)
      let rest = parsed.rest
      let match = String(parsed.match ?? "")

       if rest == ":int" {
         self = .int(match)
       } else if rest == ":string" {
         self = .string(match)
       } else {
         self = .string(match)
       }
    } else {
      self = .fixed(String(string))
    }
  }

  var optional: Bool {
    switch self {
    case .anything, .catchall:
      return true
    default:
      return false
    }
  }
}

extension PathSegmentDescriptor: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .fixed(value)
  }
}

let pathToken = charactersBetween(start: "{", end: "}")

let pathSegmentParser = zeroOrMore(
  prefix(while: { $0 != "/"}),
  separatedBy: literalParser("/"))
  .map { strings in
    strings.compactMap(PathSegmentDescriptor.init)
}
