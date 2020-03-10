extension Optional {
  public func unwrap(_ f: (Wrapped) -> Void) {
    if let x = self { f(x) }
  }
}
