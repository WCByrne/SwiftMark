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

    func parse(_ string: String, features: Feature = .all) -> Node {
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
        XCTAssertEqual(bold.children[0].type, .text("BoldItalic"))
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
            XCTAssertEqual(listItem.children[0].type, .text(text))
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
            XCTAssertEqual(listItem.children[0].type, .text(text))
        }
    }

}
