//
//  Scanner.swift
//  SwiftMark
//
//  Created by Wesley Byrne on 10/26/18.
//  Copyright © 2018 The Noun Project. All rights reserved.
//

import Foundation

extension Scanner {
    func scanCharacters(from set: CharacterSet) -> String? {
        var temp: NSString?
        self.scanCharacters(from: set, into: &temp)
        return temp as String?
    }
    
    func scanCharacters(in string: String) -> String? {
        let set = CharacterSet(charactersIn: string)
        var temp: NSString?
        self.scanCharacters(from: set, into: &temp)
        return temp as String?
    }
    
    @discardableResult func scanWhitespace() -> String? {
        let set = CharacterSet.whitespaces
        var temp: NSString?
        self.scanCharacters(from: set, into: &temp)
        return temp as String?
    }
    
    func scanUpToCharacters(from set: CharacterSet) -> String? {
        var temp: NSString?
        self.scanUpToCharacters(from: set, into: &temp)
        return temp as String?
    }
    
    func scanUpToString(_ string: String) -> String? {
        var temp: NSString?
        self.scanUpTo(string, into: &temp)
        return temp as String?
    }
    
    func scanString(_ string: String) -> String? {
        var temp: NSString?
        self.scanString(string, into: &temp)
        return temp as String?
    }
    
    func scanHRule() -> String? {
        let loc = self.scanLocation
        guard let mark = self.scanCharacters(in: "-") else { return nil }
        self.scanWhitespace()
        if mark.count >= 3 && self.isAtEnd {
            return mark
        }
        self.scanLocation = loc
        return nil
    }
    
    func scanUnorderedList() -> String? {
        let loc = self.scanLocation
        self.scanWhitespace()
        for check in ["- ", "* "] {
            if let mark = self.scanString(check) {
                return mark
            }
        }
        self.scanLocation = loc
        return nil
    }
    
    func scanOrderedList() -> String? {
        let loc = self.scanLocation
        guard let mark = self.scanCharacters(in: "0123456789") else { return nil }
        if self.scanString(". ") != nil {
            return mark
        }
        self.scanLocation = loc
        return nil
    }
    
    /// Returns a Double if scanned, or `nil` if not found.
    func scanDouble() -> Double? {
        var value = 0.0
        scanDouble(&value)
        return value
    }
    
    /// Returns a Float if scanned, or `nil` if not found.
    func scanFloat() -> Float? {
        var value: Float = 0.0
        scanFloat(&value)
        return value
    }
    
    /// Returns an Int if scanned, or `nil` if not found.
    func scanInteger() -> Int? {
        var value = 0
        scanInt(&value)
        return value
    }
}
