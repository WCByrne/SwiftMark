//: Playground - noun: a place where people can play

import PlaygroundSupport
import SwiftMark
import Foundation
import AppKit

let rawMarkdown = """
Prefix
## Welcome to _Markdown_
## Welcome to *Markdown*

**Hey, this is _markdown_**.
__Hey, this is *markdown*__.

---

_Hey, this is **markdown**_.
~~*Hey, this is __markdown__*.~~

- Item 3
- Item 1
* Item 2

1. Thing 1
1. Thing 2
1. Thing 3

How does it work - magic!

That's pretty neat 🤣👨‍👩‍👦‍👦

> Did you know?
> [Markdown](www.markdown.com) can be a pain in the ass to parse!
> Test

This is `Code`

```
let name = "Bob"
print("Hey \\(name)")
```

Bold is done with \\*\\*Bold**

You can escape characters with a \\
"""

let parser = Parser(markdown: rawMarkdown, options: [
    .blockQuote,
    .codeBlock,
//    .headings,
    .horizontalRule,
    .inlineCode,
    .orderedList,
    .unorderedList
    ])

let doc = parser.parse()
print(doc)

let output = doc.attributedString()
let view = NSTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
view.textColor = NSColor.textColor
view.backgroundColor = NSColor.white
view.textStorage?.setAttributedString(output)

PlaygroundPage.current.liveView = view
