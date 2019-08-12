//
//  AttributedString.swift
//  SwiftMark
//
//  Created by Wes Byrne on 10/29/18.
//  Copyright © 2018 The Noun Project. All rights reserved.
//

import Foundation

public struct HeadingStyle {

    public enum Weight {
        case bold
        case weight(Int)
    }
    public let size: CGFloat
    public let weight: Weight

    public init(size: CGFloat, weight: Weight) {
        self.size = size
        self.weight = weight
    }
}

public protocol HeadingProvider {
    func styleForLevel(_ level: Int) -> HeadingStyle
}

extension Node {
    
    // MARK: - Rendering
    /*-------------------------------------------------------------------------------*/
    
    /// Render the node and it's children as an NSAttributedString
    ///
    /// - Returns: An attributed string that represents the tree starting at the reciever
    public func attributedString(baseFont: NSFont = NSFont.systemFont(ofSize: 13),
                                 color: NSColor? = nil,
                                 paragraphStyle: NSParagraphStyle? = nil,
                                 otherAttributes: [NSAttributedString.Key: Any] = [:],
                                 headingProvider: HeadingProvider? = nil) -> NSAttributedString {
        struct Font {
            let base: NSFont
            var size: CGFloat?
            var color: NSColor?
            var bold: Bool = false
            var italic: Bool = false
            var weight: Int?
            var paragraphStyle: NSParagraphStyle?
            let baseAttributes: [NSAttributedString.Key: Any]
            
            init(base: NSFont, color: NSColor?, paragraphStyle: NSParagraphStyle?, baseAttributes: [NSAttributedString.Key: Any]) {
                self.base = base
                self.color = color
                self.paragraphStyle = paragraphStyle
                self.baseAttributes = baseAttributes
            }
            
            var traits: NSFontTraitMask {
                var t = NSFontTraitMask()
                if self.bold { t.insert(.boldFontMask) }
                if self.italic { t.insert(.italicFontMask) }
                return t
            }
            
            var font: NSFont {
                let manager = NSFontManager.shared
                var _font: NSFont?
                var _size = self.size
                if let weight = self.weight, let fam = base.familyName {
                    _font = manager.font(withFamily: fam, traits: traits, weight: weight, size: _size ?? base.pointSize)
                    _size = nil
                }
                var f = _font ?? manager.convert(base, toHaveTrait: self.traits)
                if let s = _size {
                    f = manager.convert(f, toSize: s)
                }
                return f
            }
            var attributes: [NSAttributedString.Key: Any] {
                var attrs = self.baseAttributes
                attrs[.font] = self.font
                attrs[.foregroundColor] = self.color
                attrs[.paragraphStyle] = self.paragraphStyle
                return attrs
            }
        }
        
        var font = Font(base: baseFont, color: color, paragraphStyle: paragraphStyle, baseAttributes: otherAttributes)
        
        func render(node: Node) -> NSAttributedString {
            func processChildren() -> NSMutableAttributedString {
                return node.children.reduce(into: NSMutableAttributedString()) {
                    let c = render(node: $1)
                    $0.append(c)
                }
            }
            
            switch node.type {
            case let .heading(level):
                if let provided = headingProvider?.styleForLevel(level) {
                    font.size = provided.size
                    switch provided.weight {
                    case .bold: font.bold = true
                    case let .weight(w): font.weight = w
                    }
                } else {
                    font.size = baseFont.pointSize + CGFloat(level * 4)
                    font.bold = true
                }

                defer {
                    font.bold = false
                    font.size = baseFont.pointSize
                    font.weight = nil
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
                guard !node.children.isEmpty else {
                    return list
                }
                let pStyle = font.paragraphStyle

                let listStyle = pStyle?.mutableCopy() as? NSMutableParagraphStyle
                listStyle?.paragraphSpacing = 0
                listStyle?.headIndent = 20
                listStyle?.firstLineHeadIndent = 10
                font.paragraphStyle = listStyle

                for (idx, listItem) in node.children.enumerated() {
//                  Reset the paragraph spacing for the last item
                    if idx == node.children.count - 1 {
                        let s =  listStyle?.mutableDuplicate()
                        s?.paragraphSpacing = pStyle?.paragraphSpacing ?? 0
                        font.paragraphStyle = s
                    }
                    assert(listItem.type == .listItem, "None list item in list")
                    let bullet = ordered ? "\(idx + 1). " : "• "
                    list.append(NSAttributedString(string: bullet, attributes: font.attributes))
                    let itemText = render(node: listItem)
                    list.append(itemText)
                }
                font.paragraphStyle = pStyle

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
        return CGRect(x: 0, y: 0, width: lineFrag.size.width, height: 44)
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
