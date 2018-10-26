//
//  Feature.swift
//  SwiftMark
//
//  Created by Wesley Byrne on 10/26/18.
//  Copyright © 2018 The Noun Project. All rights reserved.
//

import Foundation


/// Markdown features that can be enabled for a Parser
public struct Feature: OptionSet {
    /// :nodoc:
    public let rawValue: Int
    /// :nodoc:
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    /// Block Quote
    public static let blockQuote = Feature(rawValue: 1 << 0)
    /// Inline Code
    public static let inlineCode = Feature(rawValue: 1 << 1)
    /// Code Block
    public static let codeBlock = Feature(rawValue: 1 << 2)
    /// Headings
    public static let headings = Feature(rawValue: 1 << 3)
    /// Ordered List
    public static let orderedList = Feature(rawValue: 1 << 4)
    /// Unordered List
    public static let unorderedList = Feature(rawValue: 1 << 5)
    /// Horizontal Rule
    public static let horizontalRule = Feature(rawValue: 1 << 6)
    
    public static let all: Feature = [.blockQuote, .inlineCode, .codeBlock, .headings,
                                      .orderedList, .unorderedList, .horizontalRule]
}
