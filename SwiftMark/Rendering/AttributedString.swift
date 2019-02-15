//
//  AttributedString.swift
//  SwiftMark
//
//  Created by Wes Byrne on 10/29/18.
//  Copyright © 2018 The Noun Project. All rights reserved.
//

import Foundation

public extension Node {
    
    // MARK: - Rendering
    /*-------------------------------------------------------------------------------*/
    
    /// Render the node and it's children as an NSAttributedString
    ///
    /// - Returns: An attributed string that represents the tree starting at the reciever
    public func attributedString(baseFont: NSFont = NSFont.systemFont(ofSize: 13)) -> NSAttributedString {
        struct Font {
            let base: NSFont
            var size: CGFloat?
            var color: NSColor?
            var bold: Bool = false
            var italic: Bool = false
            
            init(base: NSFont) {
                self.base = base
            }
            
            var traits: NSFontTraitMask {
                var t = NSFontTraitMask()
                if self.bold { t.insert(.boldFontMask) }
                if self.italic { t.insert(.italicFontMask) }
                return t
            }
            
            var font: NSFont {
                let manager = NSFontManager.shared
                var f = manager.convert(base, toHaveTrait: self.traits)
                if let s = self.size {
                    f = manager.convert(f, toSize: s)
                }
                return f
            }
            var attributes: [NSAttributedString.Key: Any] {
                return [
                    .font: self.font
                ]
            }
        }
        
        var font = Font(base: baseFont)
        
        func render(node: Node) -> NSAttributedString {
            func processChildren() -> NSMutableAttributedString {
                return node.children.reduce(into: NSMutableAttributedString()) {
                    let c = render(node: $1)
                    $0.append(c)
                }
            }
            
            switch node.type {
            case let .heading(level):
                font.size = baseFont.pointSize + CGFloat(level * 4)
                font.bold = true
                defer {
                    font.bold = false
                    font.size = baseFont.pointSize
                }
                return processChildren()
            case .emphasis:
                font.italic = true
                defer { font.italic = false }
                return processChildren()
            case .strong:
                font.bold = true
                defer { font.bold = false }
                return processChildren()
            case .horizontalRule:
                let attachment = NSTextAttachment(fileWrapper: nil)
                attachment.attachmentCell = HorizontalRuleAttachmentCell(imageCell: nil)
                return NSAttributedString(attachment: attachment)
                
            case let .list(ordered):
                let list = NSMutableAttributedString()
                for (idx, listItem) in node.children.enumerated() {
                    assert(listItem.type == .listItem, "None list item in list")
                    let bullet = ordered ? "\(idx + 1). " : "● "
                    list.append(NSAttributedString(string: bullet))
                    let itemText = render(node: listItem)
                    list.append(itemText)
                }
                return list
                
            case let .text(str):
                return NSAttributedString(string: str, attributes: font.attributes)
            case .strike:
                let result = processChildren()
                result.addAttributes([.strikethroughStyle: NSUnderlineStyle.single.rawValue],
                                     range: result.range)
                return result
            case let .link(title, url):
                var attrs = font.attributes
                attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                attrs[.link] = URL(string: url)?.validatingScheme
                return NSAttributedString(string: title, attributes: attrs)
                
            default:
                return processChildren()
            }
        }
        
        return render(node: self)
    }
}

private class HorizontalRuleAttachmentCell: NSTextAttachmentCell {
    override func cellFrame(for textContainer: NSTextContainer, proposedLineFragment lineFrag: NSRect, glyphPosition position: NSPoint, characterIndex charIndex: Int) -> NSRect {
        return CGRect(x: 0, y: 0, width: lineFrag.size.width, height: 24)
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        NSColor(white: 0.8, alpha: 1).set()
        var inset = cellFrame.insetBy(dx: 2, dy: 0)
        inset.origin.x += 2
        inset.origin.y += 11
        inset.size.height = 1
        inset.size.width -= 20
        inset.fill()
    }
}
