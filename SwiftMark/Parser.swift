//
//  File.swift
//  SwiftMark
//
//  Created by Wesley Byrne on 10/26/18.
//  Copyright © 2018 The Noun Project. All rights reserved.
//

import Foundation
import AppKit

/// A Parser, initialized with raw markdown can parse the markdown nodes according to the options provided.
open class Parser {
    
    // MARK: - Features
    /*-------------------------------------------------------------------------------*/
    /// Optionally enabled markdown features
    public var features: Feature
    
    // MARK: - Initialization
    /*-------------------------------------------------------------------------------*/
    
    /// The raw markdown string
    open var markdown: String
    
    /// Initialize a new parser
    ///
    /// - Parameters:
    ///   - markdown: The raw markdown string to be parsed
    ///   - options: Options for enabling specific markdown features
    public init(markdown: String, features: Feature = .all) {
        self.markdown = markdown
        self.features = features
    }
    
    // MARK: - Parsing
    /*-------------------------------------------------------------------------------*/
    
    /// Parse the raw string into Nodes
    ///
    /// - Returns: The root document node that is the top of the tree
    public func parse() -> Node {
        
        let lines = self.markdown.components(separatedBy: .newlines)
        let markCharacters = CharacterSet(charactersIn: "*_-#>~`[\\")
        var document = Node(type: .document)
        
        var isNewline = true
        
        func nodeType(for string: String) -> NodeType {
            guard let char = string.first else {
                return .text(string)
            }
            switch char {
            case "\\" where string.count > 1:
                return .text(String(string.dropFirst()))
                //            case "-" where isNewline && string.count == 1,
                //                 "*" where isNewline && string.count == 1,
                //                 "+" where isNewline && string.count == 1:
            //                return .listItem
            case "*" where string.count == 1,
                 "_" where string.count == 1:
                return .emphasis(string)
            case "*" where string.isRepeatedCharacter,
                 "_" where string.isRepeatedCharacter:
                return .strong(string)
            case "~" where string.count > 1 && string.isRepeatedCharacter:
                return .strike(string)
            case "`" where string.count == 1:
                return .inlineCode
            default:
                return .text(string)
            }
        }
        
        var quote: Node?
        var code: Node?
        var list: Node?
        
        func closeList() {
            if let l = list {
                (quote ?? document).children.append(l)
                list = nil
            }
        }
        func closeQuote() {
            if let q = quote {
                document.children.append(q)
                quote = nil
            }
        }
        func openList(ordered: Bool) {
            if list == nil {
                list = Node(type: .list(ordered))
            }
        }
        
        for _line in lines {
            isNewline = true
            let line = _line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let scanner = Scanner(string: line)
            scanner.charactersToBeSkipped = CharacterSet()
            var stack = [NodeType]()
            
            while true {
                if isNewline {
                    if features.contains(.blockQuote), let text = scanner.scanCharacters(in: "> ") {
                        let level = text.filter { return $0 == ">" }.count
                        // Check if we are already in a block
                        if quote == nil {
                            quote = Node(type: .blockQuote(level))
                        }
                    } else if quote != nil {
                        closeQuote()
                        closeList()
                    }
                    
                    if features.contains(.headings), let text = scanner.scanCharacters(in: "#") {
                        stack.append(.heading(text.count))
                        scanner.scanWhitespace()
                    } else if features.contains(.horizontalRule), scanner.scanHRule() != nil {
                        stack.append(.horizontalRule)
                    } else if features.contains(.unorderedList), scanner.scanUnorderedList() != nil {
                        stack.append(.listItem)
                        openList(ordered: false)
                    } else if features.contains(.orderedList), scanner.scanOrderedList() != nil {
                        stack.append(.listItem)
                        openList(ordered: true)
                        
                    }
                    if stack.last != .listItem {
                        closeList()
                    }
                    
                }
                if let text = scanner.scanUpToCharacters(from: markCharacters) {
                    stack.append(.text(text))
                }
                else if let markText = scanner.scanCharacters(from: markCharacters) {
                    var marks = [String]()
                    var last: String = ""
                    
                    func commitLast() {
                        if !last.isEmpty {
                            marks.append(last)
                        }
                        last = ""
                    }
                    for char in markText {
                        switch char {
                        case _ where last == "\\":
                            last = "\\\(char)"
                            commitLast()
                        case "\\":
                            commitLast()
                            last = "\\"
                        case "[":
                            let loc = scanner.scanLocation
                            if let title = scanner.scanUpToString("]("),
                                let link = scanner.scanUpToString(")")?.removingPrefix("](") {
                                scanner.scanString(")", into: nil)
                                stack.append(.link(title, link))
                            } else {
                                scanner.scanLocation = loc
                                commitLast()
                                last.append(char)
                            }
                        case _ where last.isEmpty || last.last == char:
                            last.append(char)
                        default:
                            commitLast()
                            last.append(char)
                        }
                    }
                    commitLast()
                    stack.append(contentsOf: marks.map { return nodeType(for: $0) })
                }
                if scanner.isAtEnd { break }
                isNewline = false
            }
            
            stack.append(NodeType.text("\n"))
            stack = stack.reducingText()
            
            var cursor = 0
            func nodes(upTo end: Int) -> [Node] {
                var res = [Node]()
                
                func next(indexOf node: NodeType) -> Int? {
                    var c = cursor
                    while c < end {
                        if stack[c] == node { return c }
                        c += 1
                    }
                    return nil
                }
                
                while cursor < end {
                    let current = stack[cursor]
                    cursor += 1
                    
                    switch current {
                    case .text:
                        res.append(Node(type: current))
                    case .heading:
                        res.append(Node(type: current,
                                        children: nodes(upTo: end)))
                    case .horizontalRule:
                        res.append(Node(type: current))
                    case .listItem:
                        assert(list != nil, "list item with not list open")
                        
                        let item = Node(type: current,
                                        children: nodes(upTo: end))
                        list!.children.append(item)
                    //                        res.append(list!)
                    case .blockQuote:
                        print("Got block quote when parsing children ??")
                        //                        res.append(Node(type: current,
                    //                                        children: nodes(upTo: end)))
                    case .link:
                        res.append(Node(type: current))
                    default:
                        if let close = next(indexOf: current) {
                            res.append(Node(type: current,
                                            children: nodes(upTo: close)))
                            cursor += 1
                        }
                        else if let txt = current.asText {
                            print("Unable to find matching closing mark: \(current)")
                            res.append(Node(type: txt))
                        }
                    }
                }
                return res
            }
            let newNodes = nodes(upTo: stack.count)
            (quote ?? document).children.append(contentsOf: newNodes)
        }
        closeList()
        closeQuote()
        if document.children.last?.type == .text("\n") {
            _ = document.children.popLast()
        }
        return document
    }
}
