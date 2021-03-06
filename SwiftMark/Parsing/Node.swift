//
//  Node.swift
//  SwiftMark
//
//  Created by Wesley Byrne on 10/26/18.
//  Copyright © 2018 The Noun Project. All rights reserved.
//

import Foundation
import AppKit

/// Nodes represent markdown features in an AST
public class Node {
    /// The type of the node
    public let type: NodeType
    /// Children of the node
    public var children = [Node]()
    
    init(type: NodeType, children: [Node] = []) {
        self.type = type
        self.children = children
    }
}

extension Node {
    /// The first child if any
    public var child: Node? {
        return children.first
    }
}

extension Node {
    func reduceText() {
        var join: String?
        var reduced = self.children.reduce(into: [Node]()) { (res, node) in
            switch node.type {
            case let .text(str):
                join = (join ?? "") + str
            default:
                if let str = join {
                    res.append(Node(type: .text(str)))
                    join = nil
                }
                node.reduceText()
                res.append(node)
            }
        }
        if let str = join {
            reduced.append(Node(type: .text(str)))
        }
        self.children = reduced
    }
}

extension Node: CustomDebugStringConvertible {
    /// :nodoc:
    public var debugDescription: String {
        return formattedDescription(level: 0)
    }
    
    func formattedDescription(level: Int) -> String {
        var comps = [String(repeating: "\t", count: level) + "↳ \(self.type)"]
        let _children = children.map { return $0.formattedDescription(level: level + 1) }
        comps.append(contentsOf: _children)
        return comps.joined(separator: "\n")
    }
}

extension Node {
    /// Enumerate the node and its children
    ///
    /// - Parameter enumerator: A block to call with each touched node
    func enumerate(_ enumerator: (Node) -> Void) {
        enumerator(self)
        for c in self.children {
            c.enumerate(enumerator
            )
        }
    }
}
