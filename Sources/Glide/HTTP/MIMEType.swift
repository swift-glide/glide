public struct MIMEType: Hashable, CustomStringConvertible, Equatable {
  /// Represets the general category into which the data type falls.
  public var type: DiscreteType

  /// Represents the exact kind of data.
  public var subtype: String

  /// Optional parameter used to provide additional details
  public var parameter: (String, String)?

  public enum DiscreteType: String, Equatable {
    case application
    case text
    case image
    case audio
    case video
    case multipart
    case message
    case model
    case example
    case font
  }

  /// Create a new MIME tpe.
  /// - Parameters:
  ///   - type: The discrete type. Can be `application`, `audio`, `example`, `font`,  `image`, `model`, `text`, or `video`.
  ///   - subtype: The exact type of the media type.
  ///   - parameter: An optional key and value.
  public init(
    _ type: DiscreteType,
    subtype: String,
    parameter: (String, String)? = nil
  ) {
    self.type = type
    self.subtype = subtype
    self.parameter = parameter
  }

  public var description: String {
    var desc = "\(type.rawValue)/\(subtype)"

    if let (key, value) = parameter {
      desc += "; \(key)=\(value)"
    }

    return desc
  }

  public func hash(into hasher: inout Hasher) {
    self.type.hash(into: &hasher)
    self.subtype.hash(into: &hasher)
  }

  public static func == (lhs: MIMEType, rhs: MIMEType) -> Bool {
    lhs.type == rhs.type && (
      lhs.subtype == rhs.subtype ||
        lhs.subtype == "*" ||
        rhs.subtype == "*"
    )
  }
}

extension MIMEType: LosslessStringConvertible {
  public init?(_ string: String) {
    var parameter: (String, String)? = nil

    let parts = string.split(separator: ";").map {
      $0.trimmingCharacters(in: .whitespaces)
    }

    guard let typeParts = parts.first?.split(separator: "/") else { return nil }

    guard typeParts.count == 2,
      let type = typeParts.first,
          let discreteType = DiscreteType.init(rawValue: String(type))
    else { return nil }

    if parts.count == 2 {
      let parameterParts = parts[1].split(separator: "=")
      if parameterParts.count == 2 {
        parameter = (
          String(parameterParts[0]),
          String(parameterParts[1])
        )
      }
    }

    self = .init(
      discreteType,
      subtype: String(typeParts[1]),
      parameter: parameter
    )
  }
}

public extension MIMEType {
  static var plainText = MIMEType(.text, subtype: "plain", parameter: ("charset", "utf-8"))
  static var json = MIMEType(.application, subtype: "json", parameter: ("charset", "utf-8"))
  static var html = MIMEType(.text, subtype: "html", parameter: ("charset", "utf-8"))
  static var css = MIMEType(.text, subtype: "css", parameter: ("charset", "utf-8"))
  static var xml = MIMEType(.application, subtype: "xml", parameter: ("charset", "utf-8"))
  static var formURLEncoded = MIMEType(.application, subtype: "x-www-form-urlencoded", parameter: ("charset", "utf-8"))
}
