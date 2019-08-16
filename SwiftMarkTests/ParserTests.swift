//
//  ParserTests.swift
//  SwiftMarkTests
//
//  Created by Wesley Byrne on 10/26/18.
//  Copyright © 2018 The Noun Project. All rights reserved.
//

import XCTest
@testable import SwiftMark

class ParserTests: XCTestCase {

    func parse(_ string: String, features: Feature = .standard) -> Node {
        let parser = Parser(markdown: string, features: features)
        return parser.parse()
    }

    func testBold_astrisk() {
        let doc = parse("**Bold**")
        XCTAssertEqual(doc.children.count, 1)
        XCTAssertEqual(doc.children[0].type, .strong("**"))
    }
    func testBold_underscore() {
        let doc = parse("__Bold__")
        XCTAssertEqual(doc.children.count, 1)
        XCTAssertEqual(doc.children[0].type, .strong("__"))
    }
    
    func testBold_extraLeadingMark() {
        let doc = parse("___Bold__")
        XCTAssertEqual(doc.children.count, 1)
        let strong = doc.children[0]
        XCTAssertEqual(strong.type, .strong("__"))
        XCTAssertEqual(strong.children[0].type, .text("_Bold"))
    }
    func testBold_extraTrailingMark() {
        let doc = parse("__Bold___")
        XCTAssertEqual(doc.children.count, 2)
        XCTAssertEqual(doc.children[0].type, .strong("__"))
        XCTAssertEqual(doc.children[0].child?.type, .text("Bold"))
        XCTAssertEqual(doc.children[1].type, .text("_"))
    }
    
    func testItalic_astrisk() {
        let doc = parse("*Italic*")
        XCTAssertEqual(doc.children.count, 1)
        XCTAssertEqual(doc.children[0].type, .emphasis("*"))
    }
    func testItalic_underscore() {
        let doc = parse("_Italic_")
        XCTAssertEqual(doc.children.count, 1)
        XCTAssertEqual(doc.children[0].type, .emphasis("_"))
    }
    
    func testItalic_extraLeadingMark() {
        let doc = parse("__Italic_")
        XCTAssertEqual(doc.children.count, 2)
        XCTAssertEqual(doc.children[0].type, .text("_"))
        XCTAssertEqual(doc.children[1].type, .emphasis("_"))
    }
    func testItalic_extraTrailingMark() {
        let doc = parse("_Italic__")
        XCTAssertEqual(doc.children.count, 2)
        XCTAssertEqual(doc.children[0].type, .emphasis("_"))
        XCTAssertEqual(doc.children[1].type, .text("_"))
    }
    
    func testBoldItalic_astriskUnderscore() {
        let doc = parse("*__BoldItalic__*")
        XCTAssertEqual(doc.children.count, 1)
        let emph = doc.children[0]
        let bold = emph.children[0]
        XCTAssertEqual(emph.type, .emphasis("*"))
        XCTAssertEqual(emph.children.count, 1)
        XCTAssertEqual(bold.type, .strong("__"))
        XCTAssertEqual(bold.child?.type, .text("BoldItalic"))
    }
    
    func testUnorderedList() {
        let doc = parse("""
        * One
        * Two
        * Three
        """)
        let list = doc.children[0]
        XCTAssertEqual(list.type, .list(false))
        // TODO: these newlines should be handled better
        let items = ["One\n", "Two\n", "Three"]
        for (idx, text) in items.enumerated() {
            let listItem = list.children[idx]
            XCTAssertEqual(listItem.type, .listItem)
            XCTAssertEqual(listItem.child?.type, .text(text))
        }
    }
    
    func testUnorderedList_dashes() {
        let doc = parse("""
        - One
        - Two
        - Three
        """)
        let list = doc.children[0]
        XCTAssertEqual(list.type, .list(false))
        
        // TODO: these newlines should be handled better
        let items = ["One\n", "Two\n", "Three"]
        for (idx, text) in items.enumerated() {
            let listItem = list.children[idx]
            XCTAssertEqual(listItem.type, .listItem)
            XCTAssertEqual(listItem.child?.type, .text(text))
        }
    }
    
    func testOrderedList() {
        let doc = parse("""
        1. One
        1. Two
        1. Three
        """)
        let list = doc.children[0]
        XCTAssertEqual(list.type, .list(true))

        // TODO: these newlines should be handled better
        let items = ["One\n", "Two\n", "Three"]
        for (idx, text) in items.enumerated() {
            let listItem = list.children[idx]
            XCTAssertEqual(listItem.type, .listItem)
            XCTAssertEqual(listItem.child?.type, .text(text))
        }
    }
    
    func testUnorderedList_Italic() {
        // Previous parsing strategies caused this to fail because all leading
        // asteisks and whitespace were consumed by the parser
        let doc = self.parse("""
        * *Italic list item*
        * **Bold list item**
        """)
        let items = doc.children[0].children
        XCTAssertEqual(items[0].child?.type, .emphasis("*"))
        XCTAssertEqual(items[0].child?.child?.type, .text("Italic list item"))
        XCTAssertEqual(items[1].child?.type, .strong("**"))
        XCTAssertEqual(items[1].child?.child?.type, .text("Bold list item"))
    }
    
    func testListFollowedByBlockquote() {
        let str = """
        1. one
        2. two
        > quote
        """
        let doc = parse(str)
        XCTAssertEqual(doc.children[0].type, .list(true))
        XCTAssertEqual(doc.children[1].type, .blockQuote(1))
    }
    
    // MARK: - Multiple Newline
    /*-------------------------------------------------------------------------------*/
    var newlineTestString: String {
        return """
        Line one
        
        Line two
        
        
        
        Line three
        """
    }
    
    func testMultipleNewlines_standrd() {
        let doc = self.parse(newlineTestString)
        let expected = """
        Line one

        Line two

        Line three
        """
        XCTAssertEqual(doc.children[0].type, .text(expected))
    }

    func testMultipleNewlines_allow() {
        let doc = self.parse(newlineTestString, features: .all)
        XCTAssertEqual(doc.children[0].type, .text(newlineTestString))
    }
    
    // List newline padding
    /*-------------------------------------------------------------------------------*/
    // A previous bug caused newlines to be inserted or removed incorrectly around lists
    
    func testListWithNewlineBefore() {
        let doc = parse("""
        Text

        * List item
        more text
        """)
        XCTAssertEqual(doc.children[0].type, .text("Text\n\n"))
        XCTAssertEqual(doc.children[1].type, .list(false))
        XCTAssertEqual(doc.children[1].child?.type, .listItem)
        XCTAssertEqual(doc.children[2].type, .text("more text"))
    }
    
    func testListWithNewlineAfter() {
        let doc = parse("""
        Text
        * List item
        
        more text
        """)
        XCTAssertEqual(doc.children[0].type, .text("Text\n"))
        XCTAssertEqual(doc.children[1].type, .list(false))
        XCTAssertEqual(doc.children[1].child?.type, .listItem)
        XCTAssertEqual(doc.children[2].type, .text("\nmore text"))
    }
    
    func testInlineCode() {
        let doc = parse("This is `code`")
        XCTAssertEqual(doc.children[0].type, .text("This is "))
        XCTAssertEqual(doc.children[1].type, .inlineCode)
        XCTAssertEqual(doc.children[1].child?.type, .text("code"))
    }
    
    func testInlineCodeEscapes() {
        let doc = parse("This is `*code*`")
        XCTAssertEqual(doc.children[0].type, .text("This is "))
        XCTAssertEqual(doc.children[1].type, .inlineCode)
        XCTAssertEqual(doc.children[1].child?.type, .text("*code*"))
    }
    
    func testBoldInlineCode() {
        let doc = parse("This is **`code`**")
        XCTAssertEqual(doc.children[0].type, .text("This is "))
        XCTAssertEqual(doc.children[1].type, .strong("**"))
        XCTAssertEqual(doc.children[1].child?.type, .inlineCode)
        XCTAssertEqual(doc.children[1].child?.child?.type, .text("code"))
    }
    
    func testCodeBlock() {
        let doc = parse("```\nthis is code\n```")
        XCTAssertEqual(doc.children[0].type, .codeBlock)
        XCTAssertEqual(doc.children[0].child?.type, .text("this is code\n"))
    }
    
    func testCodeBlockReduceText() {
        let doc = parse("```\nthis is code\nwith multiple lines\n```")
        XCTAssertEqual(doc.children[0].type, .codeBlock)
        XCTAssertEqual(doc.children[0].child?.type, .text("this is code\nwith multiple lines\n"))
    }
    
    func testCodeBlockPreserveNewlines() {
        let doc = parse("```\n\nthis is code\n```")
        XCTAssertEqual(doc.children[0].type, .codeBlock)
        XCTAssertEqual(doc.children[0].child?.type, .text("\nthis is code\n"))
    }

    func testCodeBlock_disabled() {
        let str = """
            Use this code for things
            ```
            This is code
            ```
            """
        let doc = parse(str, features: [.inlineCode])
        XCTAssertEqual(doc.children[0].type, .text(str))
    }
    
}
