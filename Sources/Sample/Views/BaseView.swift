import HTMLKit

struct BaseView<Root>: HTMLComponent {
    let context: TemplateValue<Root, String>
    let content: HTML

    init(context: TemplateValue<Root, String>, @HTMLBuilder content: () -> HTML) {
        self.context = context
        self.content = content()
    }

    var body: HTML {
        Document(type: .html5) {
            HTMLNode {
                Head {
                    Title { context }
                    Meta()
                        .name(.viewport)
                        .content("width=device-width, initial-scale=1.0")
                }
                Body {
                    content
                }
            }
        }
    }
}
