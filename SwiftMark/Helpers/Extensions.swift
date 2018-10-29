//
//  Extensions.swift
//  SwiftMark
//
//  Created by Wesley Byrne on 10/26/18.
//  Copyright © 2018 The Noun Project. All rights reserved.
//

import Foundation

extension NSAttributedString {
    var range: NSRange {
        return NSRange(location: 0, length: self.length)
    }
}

extension String {
    var isRepeatedCharacter: Bool {
        guard let first = self.first else { return false }
        return !self.contains { return $0 != first }
    }
    func removingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
