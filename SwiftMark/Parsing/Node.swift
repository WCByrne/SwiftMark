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

public extension Node {
    /// The first child if any
    public var child: Node? {
        return children.first
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
