import HTMLKit

struct StaticPage: HTMLPage {
    var body: HTML {
        Div {
          H3("Hello HTMLKit!")
        }.class("main-div")
    }
}
