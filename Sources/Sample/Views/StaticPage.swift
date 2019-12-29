import HTMLKit

struct StaticPage: HTMLPage {
    var body: HTML {
        Div {
          H3("This is a Static Page")
        }.class("main-div")
    }
}
