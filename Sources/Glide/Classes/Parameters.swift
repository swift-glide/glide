import Foundation

@dynamicMemberLookup
public struct Parameters {
  var storage = [String: ParameterRepresentable]()

  public subscript(dynamicMember member: String) -> Int? {
    storage[member]?.asInt()
  }

  public subscript(dynamicMember member: String) -> String? {
    storage[member]?.asString()
  }

  public subscript(dynamicMember member: String) -> Double? {
    storage[member]?.asDouble()
  }

  public subscript(dynamicMember member: String) -> Float? {
    storage[member]?.asFloat()
  }

  public subscript(dynamicMember member: String) -> Bool? {
    storage[member]?.asBool()
  }
}

protocol ParameterRepresentable: CustomStringConvertible {
  init?(_ string: String)
}

extension ParameterRepresentable {
  func asInt() -> Int? {
    self as? Int ?? Int(description)
  }

  func asString() -> String {
    self as? String ?? description
  }

  func asDouble() -> Double? {
    self as? Double ?? Double(description)
  }

  func asFloat() -> Float? {
    self as? Float ?? Float(description)
  }

  func asBool() -> Bool? {
    self as? Bool ?? Bool(description)
  }
}


extension Int: ParameterRepresentable {}
extension String: ParameterRepresentable {}
extension Substring: ParameterRepresentable {}
extension Double: ParameterRepresentable {}
extension Float: ParameterRepresentable {}
extension Bool: ParameterRepresentable {}
