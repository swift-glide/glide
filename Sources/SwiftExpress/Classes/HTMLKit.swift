import HTMLKit

public class HTMLKit {
  public static let shared = HTMLKit()

  var renderer = HTMLRenderer()

  public func addTemplate<T: HTMLTemplate>(view: T) {
    do {
      try renderer.add(view: view)
    } catch {
      print("Template Error:", error)
    }
  }

  public func addStaticPage<T: HTMLPage>(view: T) {
    do {
      try renderer.add(view: view)
    } catch {
      print("Static Page Error:", error)
    }
  }

  public func registerLocalization(atPath path: String, defaultLocale: String)  {
    do {
      try renderer.registerLocalization(atPath: path, defaultLocale: defaultLocale)
    } catch {
      print("Localization Error:", error)
    }
  }
}

extension SwiftExpress {
  public func useHTML(setup: (HTMLKit) -> Void) {
    setup(HTMLKit.shared)

    self.use(
      html(renderer: HTMLKit.shared.renderer)
    )
  }
}
