import HTMLKit

struct HelloTemplate: HTMLTemplate {
    struct Context {
        let name: String
        let title: String
    }

    var body: HTML {
        BaseView(context: context.title) {
            P { "Hello " + context.name + "!" }
        }
    }
}
