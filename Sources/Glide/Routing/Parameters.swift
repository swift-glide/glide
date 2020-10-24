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

  func string(_ index: String) -> String? {
    self[index] as? String
  }

  func int(_ index: String) -> Int? {
    self[index]?.as(Int.self)
  }

  func float(_ index: String) -> Float? {
    self[index]?.as(Float.self)
  }

  func double(_ index: String) -> Double? {
    self[index]?.as(Double.self)
  }

  func bool(_ index: String) -> Bool {
    self[index]?.as(Bool.self) ?? false
  }

  func contains(_ index: String) -> Bool {
    self[index] != nil
  }
}

extension Int: ParameterRepresentable {}
extension Int8: ParameterRepresentable {}
extension Int16: ParameterRepresentable {}
extension Int32: ParameterRepresentable {}
extension Int64: ParameterRepresentable {}

extension UInt: ParameterRepresentable {}
extension UInt8: ParameterRepresentable {}
extension UInt16: ParameterRepresentable {}
extension UInt32: ParameterRepresentable {}
extension UInt64: ParameterRepresentable {}

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
