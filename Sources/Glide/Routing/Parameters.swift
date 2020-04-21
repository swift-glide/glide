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

public extension ParameterRepresentable {
  func `as`<T: ParameterRepresentable>(_ type: T.Type) -> T? {
    self as? T ?? T(description)
  }
}

public extension Parameters {
  func JSONData() throws -> Data {
    try JSONSerialization.data(withJSONObject: storage)
  }

  func merge(with params: Parameters) -> Parameters {
    var mergedParameters = Parameters(
      storage: storage.merging(
        params.storage,
        uniquingKeysWith: { lhp, rhp in return lhp }
      )
    )
    mergedParameters.wildcards = wildcards + params.wildcards

    return mergedParameters
  }
}

extension Int: ParameterRepresentable {}
extension UInt: ParameterRepresentable {}
extension String: ParameterRepresentable {}
extension Double: ParameterRepresentable {}
extension Float: ParameterRepresentable {}
extension Bool: ParameterRepresentable {}

extension Array: ParameterRepresentable where Element: ParameterRepresentable {
  public init?(_ string: String) {
    self = string
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .compactMap {
        Element($0)
      }
  }
}
