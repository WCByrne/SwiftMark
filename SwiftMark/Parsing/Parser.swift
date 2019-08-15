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
    public init(markdown: String, features: Feature = .standard) {
        self.markdown = markdown
        self.features = features
    }
    
    // MARK: - Parsing
    /*-------------------------------------------------------------------------------*/
    
    /// Parse the raw string into Nodes
    ///
    /// - Returns: The root document node that is the top of the tree
    public func parse() -> Node {
        
        // This should be replaced by scanning the newlines but this was a quick hack
        let lines = self.markdown.components(separatedBy: .newlines)
        var document = Node(type: .document)
        
        var wasNewline = false
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
        var codeBlock: Node?
        var skipNewline: Bool = false
        
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
            if let node = list, case let .list(o) = node.type, o != ordered {
                closeList()
            }
            if list == nil {
                list = Node(type: .list(ordered))
            }
        }
        
        func openCodeBlock() {
            if codeBlock == nil {
                codeBlock = Node(type: .codeBlock)
            }
        }
        func closeCodeBlock() {
            if let block = codeBlock {
                block.children = block.children
                    .compactMap { $0.type.asText }
                    .reducingText()
                    .map { Node(type: $0) }
                (quote ?? document).children.append(block)
                quote = nil
            }
        }
        
        for (lineIndex, _line) in lines.enumerated() {
            skipNewline = false
            let isLastLine = lineIndex == lines.count - 1
            isNewline = true
            let line = _line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let scanner = Scanner(string: line)
            var lastEmph = ""
            scanner.charactersToBeSkipped = CharacterSet()
            var stack = [NodeType]()
            
            func append(newNodes: [Node]) {
                (codeBlock ?? quote ?? document).children.append(contentsOf: newNodes)
            }
            
            if line.isEmpty {
                closeList()
                closeQuote()
                if !wasNewline || features.contains(.allowMultipleLineBreaks) {
                    append(newNodes: [Node(type: .text("\n"))])
                }
                wasNewline = true
                continue
            }
            wasNewline = false
            
            while true {
                if isNewline {
                    
                    if features.contains(.codeBlock), _line == "```" {
                        if codeBlock == nil { openCodeBlock() }
                        else { closeCodeBlock() }
                        skipNewline = true
                        break
                    }
//
                    if let block = codeBlock {
                        print(_line)
                        block.children.append(Node(type: .text(_line)))
                        break
                    }
                    
                    if features.contains(.blockQuote), let text = scanner.scanCharacters(in: "> ") {
                        let level = text.filter { return $0 == ">" }.count
                        
                        if let node = quote, case let .blockQuote(l) = node.type, l != level {
                            closeQuote()
                        }
                        
                        // Check if we are already in a block
                        if quote == nil {
                            quote = Node(type: .blockQuote(level))
                        }
                    } else if quote != nil {
                        closeQuote()
                        closeList()
                    }
                    
                    if features.contains(.headings), let text = scanner.scanHeading() {
                        stack.append(.heading(text.count))
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
                
                let markCharacters = CharacterSet(charactersIn: "*_-~`[\\")
                let nonCodeMarks = CharacterSet(charactersIn: "*_-~[\\")
                print("Location : -- \(scanner.scanLocation)")
                if let text = scanner.scanUpToCharacters(from: markCharacters) {
                    stack.append(.text(text))
                } else if features.contains(.inlineCode), let codeFence = scanner.scanInlineCode() {
                    print("CODE FENCE : \(codeFence) -- \(scanner.scanLocation)")
                    if let code = scanner.scanUpToString("`") {
                        _ = scanner.scanString("`")
                        stack.append(.inlineCode)
                        stack.append(.text(code))
                        print("CODE: \(code)")
                        stack.append(.inlineCode)
                    } else {
                        stack.append(.text(codeFence))
                    }
                }
                else if let markText = scanner.scanCharacters(from: nonCodeMarks) {
                    var marks = [String]()
                    var last: String = ""
                    func commitLast() {
                        if !last.isEmpty {
                            if last.first == "_" || last.first == "*" {
                                lastEmph = last
                            }
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
                        case _ where last.last == char && (char == "_" || char == "*"):
//                            if last == lastEmph {
//                                commitLast()
//                                lastEmph = ""
//                            } else
                            if last.count == 2 {
                                commitLast()
                            }
                            last.append(char)
                        case _ where last.isEmpty || last.last == char:
                                last.append(char)
                        default:
                            commitLast()
                            last.append(char)
                        }
                    }
                    commitLast()
                    stack.append(contentsOf: marks.map { return nodeType(for: $0) })
                } else if let str = scanner.scanCharacters(from: markCharacters) {
                    stack.append(NodeType.text(str))
                }
                if scanner.isAtEnd { break }
                isNewline = false
            }
            
            if !isLastLine && !skipNewline {
                stack.append(NodeType.text("\n"))
            }
            
            print(stack)
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
                    print("current: \(current)")
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
                    case .blockQuote:
                        print("Got block quote when parsing children ??")
                    case .link:
                        res.append(Node(type: current))
                        
                    case let .strong(mark):
                        let char = "\(mark.first!)"
                        if let close = next(indexOf: current) {
                            res.append(Node(type: current, children: nodes(upTo: close)))
                            cursor += 1
                        } else if let close = next(indexOf: NodeType.emphasis(char)) {
                            res.append(Node(type: .text(char)))
                            res.append(Node(type: .emphasis(char), children: nodes(upTo: close)))
                            cursor += 1
                        }  else if let txt = current.asText {
                            res.append(Node(type: txt))
                        }
//                    case .inlineCode:
//                        if let close = next(indexOf: current) {
//                            print("Found closing inline code mark")
//                            let code = nodes(upTo: close)
//                                .compactMap { return $0.type.asText }
//                                .reducingText()
//                                .map { return Node(type: $0) }
//                            res.append(Node(type: current, children: code))
//                        } else if let txt = current.asText {
//                            res.append(Node(type: txt))
//                        }
                    case .codeBlock:
                        print("Found code block")
                        if let close = next(indexOf: current) {
                            print("Found closing code block")
                            let code = nodes(upTo: close)
                                .compactMap { return $0.type.asText }
                                .map { return Node(type: $0) }
                            res.append(Node(type: current, children: code))
                        } else if let txt = current.asText {
                            res.append(Node(type: txt))
                        }
                        
                    case let .emphasis(mark):
                        let char = "\(mark.first!)"
                        if let close = next(indexOf: current) {
                            res.append(Node(type: current, children: nodes(upTo: close)))
                            cursor += 1
                        } else if let close = next(indexOf: NodeType.strong("\(char)\(char)")) {
                            res.append(Node(type: .emphasis(char), children: nodes(upTo: close)))
                            res.append(Node(type: .text(char)))
                            cursor += 1
                        } else if let txt = current.asText {
                            res.append(Node(type: txt))
                        }
                        
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
            append(newNodes: newNodes)
        }
        closeList()
        closeQuote()
        if document.children.last?.type == .text("\n") {
            _ = document.children.popLast()
        }

        document.reduceText()
        return document
    }
}
