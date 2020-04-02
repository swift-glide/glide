import Foundation

@dynamicMemberLookup
public struct Parameters {
  private var storage = [String: ParameterRepresentable]()
  var wildcards = [Substring]()

  init(storage: [String: ParameterRepresentable] = [:]) {
    self.storage = storage
  }

  public subscript(index: String) -> ParameterRepresentable? {
    get {
      storage[index]
    }

    set(new) {
      storage[index] = new
    }
  }

  public subscript<T: ParameterRepresentable>(dynamicMember member: String) -> T? {
    guard let value = storage[member] else { return nil }
    return value.as(T.self)
  }
}

public protocol ParameterRepresentable: CustomStringConvertible {
  init?(_ string: String)
}

extension ParameterRepresentable {
  func `as`<T: ParameterRepresentable>(_ type: T.Type) -> T? {
    self as? T ?? T(description)
  }
}

extension Int: ParameterRepresentable {}
extension String: ParameterRepresentable {}
extension Substring: ParameterRepresentable {}
extension Double: ParameterRepresentable {}
extension Float: ParameterRepresentable {}
extension Bool: ParameterRepresentable {}
