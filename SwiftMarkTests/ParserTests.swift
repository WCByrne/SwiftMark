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
    /*
    func testBold_extraLeadingMark() {
        let doc = parse("___Bold__")
        print(doc.children)
        XCTAssertEqual(doc.children.count, 2)
        XCTAssertEqual(doc.children[0].type, .text("_"))
        XCTAssertEqual(doc.children[1].type, .strong("__"))
    }
    func testBold_extraTrailingMark() {
        let doc = parse("__Bold___")
        print(doc.children)
        XCTAssertEqual(doc.children.count, 2)
        XCTAssertEqual(doc.children[0].type, .strong("__"))
        XCTAssertEqual(doc.children[1].type, .text("_"))
    }
     */
    
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
    /*
    func testItalic_extraLeadingMark() {
        let doc = parse("__Italic_")
        print(doc.children)
        XCTAssertEqual(doc.children.count, 2)
        XCTAssertEqual(doc.children[0].type, .text("_"))
        XCTAssertEqual(doc.children[1].type, .strong("_"))
    }
    func testItalic_extraTrailingMark() {
        let doc = parse("_Italic__")
        print(doc.children)
        XCTAssertEqual(doc.children.count, 2)
        XCTAssertEqual(doc.children[0].type, .emphasis("_"))
        XCTAssertEqual(doc.children[1].type, .text("_"))
    }

    func testBoldItalic_underscore() {
        let doc = parse("___BoldItalic___")
        print(doc.children)
        XCTAssertEqual(doc.children.count, 1)
        let emph = doc.children[0]
        let bold = emph.children[0]
        XCTAssertEqual(emph.type, .emphasis("*"))
        XCTAssertEqual(emph.children.count, 1)
        XCTAssertEqual(bold.type, .strong("__"))
    }
     */
    
    func testBoldItalic_astriskUnderscore() {
        let doc = parse("*__BoldItalic__*")
        print(doc.children)
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
        let lines = doc.children
        let expected = [
            "Line one\n",
            "\n",
            "Line two\n",
            "\n",
            "Line three"
        ]
        if lines.count == expected.count {
            for idx in 0..<lines.count {
                XCTAssertEqual(lines[idx].type, .text(expected[idx]))
            }
        } else {
            XCTFail("line count does not match expected line count")
        }
    }

    func testMultipleNewlines_allow() {
        let doc = self.parse(newlineTestString, features: .all)
        let lines = doc.children
        let expected = [
        "Line one\n",
        "\n",
        "Line two\n",
        "\n",
        "\n",
        "\n",
        "Line three"
        ]
        if lines.count == expected.count {
            for idx in 0..<lines.count {
                XCTAssertEqual(lines[idx].type, .text(expected[idx]))
            }
        } else {
            XCTFail("line count does not match expected line count")
        }
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
        XCTAssertEqual(doc.children[0].type, .text("Text\n"))
        XCTAssertEqual(doc.children[1].type, .text("\n"))
        XCTAssertEqual(doc.children[2].type, .list(false))
        XCTAssertEqual(doc.children[2].child?.type, .listItem)
        XCTAssertEqual(doc.children[3].type, .text("more text"))
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
        XCTAssertEqual(doc.children[2].type, .text("\n"))
        XCTAssertEqual(doc.children[3].type, .text("more text"))
    }
    
}
