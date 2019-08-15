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

public struct BlockQuoteStyle {
    let textColor: NSColor?
    let borderColor: NSColor
    let borderWidth: CGFloat
    let insets: NSEdgeInsets
    let size: CGFloat?
    let bold: Bool
    let backgroundColor: NSColor?
    
    public init(textColor: NSColor? = nil, borderColor: NSColor = NSColor.red, borderWidth: CGFloat = 3, background: NSColor? = nil, insets: NSEdgeInsets = NSEdgeInsets(top: 4, left: 24, bottom: 4, right: 4), size: CGFloat? = nil, bold: Bool = false) {
        self.textColor = textColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.insets = insets
        self.size = size
        self.bold = bold
        self.backgroundColor = background
    }
}

public extension NSAttributedString.Key {
    static let inlineCode = NSAttributedString.Key("SwiftMarkInlineCode")
}

public protocol AttributedStringRenderer {
    func styleForLevel(_ level: Int) -> HeadingStyle?
    func blockQuoteStyle() -> BlockQuoteStyle
}

extension AttributedStringRenderer {
    func styleForLevel(_ level: Int) -> HeadingStyle? {
        return nil
    }
    func blockQuoteStyle() -> BlockQuoteStyle {
        return BlockQuoteStyle(borderColor: NSColor.red)
    }
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
                                 renderer: AttributedStringRenderer? = nil) -> NSAttributedString {
        
        struct Font {
            var base: NSFont
            var size: CGFloat?
            var color: NSColor?
            var bold: Bool = false
            var italic: Bool = false
            var backgroundColor: NSColor?
            var weight: Int?
            var paragraphStyle: NSParagraphStyle?
            let baseAttributes: [NSAttributedString.Key: Any]
            var customAttributes: [NSAttributedString.Key: Any] = [:]
            
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
                attrs[.backgroundColor] = self.backgroundColor
                for (k, v) in self.customAttributes {
                    attrs[k] = v
                }
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
                if let provided = renderer?.styleForLevel(level) {
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
                listStyle?.paragraphSpacing = pStyle?.lineSpacing ?? 0
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

            case let .blockQuote(level):
                let style = renderer?.blockQuoteStyle() ?? BlockQuoteStyle()

                font.size = style.size
                font.color = style.textColor
                font.bold = style.bold

                let pStyle = font.paragraphStyle
                let tempStyle = pStyle?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
                tempStyle.textBlocks = [
                    QuoteBlock(level: level,
                               insets: style.insets,
                               border: (style.borderWidth, style.borderColor),
                               background: style.backgroundColor)
                ]
                tempStyle.paragraphSpacingBefore = 4
                font.paragraphStyle = tempStyle

                defer {
                    font.size = nil
                    font.color = nil
                    font.bold = false
                    font.paragraphStyle = pStyle
                }
                return processChildren()

            case .inlineCode:
                let _font = font.base
                font.customAttributes[.inlineCode] = true
                if let f = NSFont(name: "SFMono-Regular", size: 14) {
                    font.base = f
                }
                defer {
                    font.customAttributes[.inlineCode] = nil
                    font.base = _font
                }
                return processChildren()

            case .codeBlock:
                let pStyle = font.paragraphStyle

                let tempStyle = pStyle?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
                tempStyle.textBlocks = [
                    CodeBlock(title: "", background: NSColor.lightGray, border: (1, NSColor.darkGray))
                ]
                tempStyle.paragraphSpacingBefore = 4
                font.paragraphStyle = tempStyle

                defer {
                    font.paragraphStyle = pStyle
                }
                return processChildren()

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

class QuoteBlock: NSTextBlock {

    private let level: Int
    private let border: (CGFloat, NSColor)
    private let background: NSColor?
    private let insets: NSEdgeInsets

    init(level: Int, insets: NSEdgeInsets, border: (CGFloat, NSColor), background: NSColor?) {
        self.level = level
        self.border = border
        self.background = background
        self.insets = insets
        super.init()

        let level = max(CGFloat(level), 1)
        self.setWidth(insets.left * level, type: .absoluteValueType, for: .padding)
        self.setWidth(insets.top, type: .absoluteValueType, for: .padding, edge: .minY)
        self.setWidth(insets.bottom, type: .absoluteValueType, for: .padding, edge: .maxY)
    }

    required init?(coder aDecoder: NSCoder) {
        self.level = 0
        self.border = (4, NSColor.controlColor)
        self.background = nil
        self.insets = NSEdgeInsetsZero
        super.init(coder: aDecoder)
    }

    override func boundsRect(forContentRect contentRect: NSRect, in rect: NSRect, textContainer: NSTextContainer, characterRange charRange: NSRange) -> NSRect {
        return super.boundsRect(forContentRect: contentRect, in: rect, textContainer: textContainer, characterRange: charRange)
    }

    override func rectForLayout(at startingPoint: NSPoint, in rect: NSRect, textContainer: NSTextContainer, characterRange charRange: NSRange) -> NSRect {
        var res = super.rectForLayout(at: startingPoint, in: rect, textContainer: textContainer, characterRange: charRange)
        res.size.width = rect.size.width
        return res
    }

    override func drawBackground(withFrame frameRect: NSRect, in controlView: NSView, characterRange charRange: NSRange, layoutManager: NSLayoutManager) {

        let adjustedFrame = CGRect(x: frameRect.origin.x,
                                   y: frameRect.origin.y + 2,
                                   width: controlView.frame.size.width - (frameRect.origin.x * 2),
                                   height: frameRect.size.height - 2)

        super.drawBackground(withFrame: adjustedFrame, in: controlView, characterRange: charRange, layoutManager: layoutManager)
        
        NSGraphicsContext.saveGraphicsState()

        if let bg = self.background {
            let path = NSBezierPath(roundedRect: adjustedFrame, xRadius: 5, yRadius: 5)
            bg.setFill()
            path.fill()
        }
        
        var maxY = adjustedFrame.maxY
        let lastCharRange = NSRange(location: charRange.location + charRange.length - 1, length: 1)
        if layoutManager.attributedString().attributedSubstring(from: lastCharRange).string == "\n" {
            maxY -= 7
        }

        self.border.1.setStroke()
        let offset = self.border.0/2
        for idx in 0..<self.level {
            let path = NSBezierPath()
            path.lineWidth = self.border.0
            let x = offset + adjustedFrame.origin.x + (CGFloat(idx) * self.insets.left)
            path.move(to: CGPoint(x: x, y: adjustedFrame.minY))
            path.line(to: CGPoint(x: x, y: maxY))
            path.stroke()
        }
        NSGraphicsContext.restoreGraphicsState()
    }
}

class CodeBlock: NSTextBlock {

    let titleFont = NSFont.boldSystemFont(ofSize: 11)
    let title: String?

    init(title: String? = nil, background: NSColor, border: (CGFloat, NSColor)?) {
        self.title = title?.isEmpty != false ? nil : title
        super.init()

        self.setWidth(8, type: .absoluteValueType, for: .padding)
        self.setWidth(self.title == nil ? 4 : 20, type: .absoluteValueType, for: .padding, edge: .minY)
        self.setWidth(4, type: .absoluteValueType, for: .padding, edge: .maxY)

        self.backgroundColor = background
        if let b = border {
            self.setBorderColor(b.1, for: .minX)
            self.setWidth(b.0, type: .absoluteValueType, for: .border)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        self.title = nil
        super.init(coder: aDecoder)
    }

    private var origin = CGPoint.zero
    override func rectForLayout(at startingPoint: NSPoint, in rect: NSRect, textContainer: NSTextContainer, characterRange charRange: NSRange) -> NSRect {
        self.origin = startingPoint
        var res = super.rectForLayout(at: startingPoint, in: rect, textContainer: textContainer, characterRange: charRange)
        //        res.origin.y = startingPoint.y
        res.size.width = rect.size.width
        return res
    }

    override func drawBackground(withFrame frameRect: NSRect, in controlView: NSView, characterRange charRange: NSRange, layoutManager: NSLayoutManager) {

        let x = frameRect.origin.x

        if let title = self.title {
            let adjustedFrame = CGRect(x: x,
                                       y: frameRect.origin.y + 4,
                                       width: controlView.frame.size.width - (x * 2),
                                       height: frameRect.size.height)
            super.drawBackground(withFrame: adjustedFrame, in: controlView, characterRange: charRange, layoutManager: layoutManager)

            let drawPoint = CGPoint(x: adjustedFrame.origin.x + 12, y: adjustedFrame.origin.y + 4)
            let drawString = NSString(string: title)
            let attributes = [NSAttributedString.Key.font: self.titleFont,
                              NSAttributedString.Key.foregroundColor: NSColor.placeholderTextColor]
            drawString.draw(at: drawPoint, withAttributes: attributes)
        }
        else {
            let adjustedFrame = CGRect(x: x,
                                       y: frameRect.origin.y + 4,
                                       width: controlView.frame.size.width - (x * 2),
                                       height: frameRect.size.height)
            super.drawBackground(withFrame: adjustedFrame, in: controlView, characterRange: charRange, layoutManager: layoutManager)
        }

    }
}
