//
//  SwiftMarkTests.swift
//  SwiftMarkTests
//
//  Created by Wesley Byrne on 10/26/18.
//  Copyright © 2018 The Noun Project. All rights reserved.
//

import XCTest
@testable import SwiftMark

class ParserPerformanceTests: XCTestCase {

    func testParserPerformance() {
        let parser = Parser(markdown: TestSource.superComplex)
        self.measure {
            _ = parser.parse()
        }
    }
    
    func testAttributedStringPerformance() {
        let parser = Parser(markdown: TestSource.superComplex)
        let doc = parser.parse()
        self.measure {
            _ = doc.attributedString()
        }
    }
    
    func testAST_AttributedString_Performance() {
        let parser = Parser(markdown: TestSource.superComplex)
        self.measure {
            let doc = parser.parse()
            _ = doc.attributedString()
        }
    }
}
