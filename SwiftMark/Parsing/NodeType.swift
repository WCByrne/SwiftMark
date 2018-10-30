//
//  NodeType.swift
//  SwiftMark
//
//  Created by Wesley Byrne on 10/26/18.
//  Copyright © 2018 The Noun Project. All rights reserved.
//

import Foundation

/// The type of nodes that can be parsed from a markdown string
///
/// - document: Always the root of the AST
/// - text: Basic text that inherits the formatting of parent nodes
/// - heading: A heading with a given level
/// - blockQuote: A block quote with a given level
/// - list: A list, ordered if true. All children will be of node type ListItems
/// - listItem: A list item, always the children of a list node
/// - inlineCode: Inline code
/// - horizontalRule: A horizontal rule
/// - codeBlock: A code block
/// - emphasis: Italicize
/// - strong: Bold
/// - strike: Strike through
/// - link: Link with the title and target
/// - image: Image with name and url
public enum NodeType: Equatable {
    case document
    case text(String)
    case heading(Int)
    case blockQuote(Int)
    case list(Bool)
    case listItem
    case inlineCode
    case horizontalRule
    case codeBlock
    case emphasis(String)
    case strong(String)
    case strike(String)
    case link(String, String)
    case image(String, String)
}

extension NodeType {
    var asText: NodeType? {
        switch self {
        case .document: return nil
        case .text: return self
        case let .heading(level): return .text(String(repeating: "#", count: level))
        case .list: return nil
        case .listItem: return nil
        case .horizontalRule: return nil
        case .inlineCode: return nil
        case .codeBlock: return nil
        case .blockQuote: return nil
        case let .emphasis(str): return .text(str)
        case let .strong(str): return .text(str)
        case let .strike(str): return .text(str)
        case .link: return nil
        case .image: return nil
        }
    }
}

extension Sequence where Element == NodeType {
    func reducingText() -> [NodeType] {
        var join: String?
        var reduced = self.reduce(into: [NodeType]()) { (res, node) in
            switch node {
            case let .text(str):
                join = (join ?? "") + str
            default:
                if let str = join {
                    res.append(.text(str))
                    join = nil
                }
                res.append(node)
            }
        }
        if let str = join {
            reduced.append(.text(str))
        }
        return reduced
    }
}
