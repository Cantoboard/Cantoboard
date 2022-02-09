//
//  String+Extension.swift
//  CantoboardFramework
//
//  Created by Alex Man on 3/27/21.
//

import Foundation
import UIKit

extension String {
    func size(withFont: UIFont) -> CGSize {
        return (self as NSString).size(withAttributes: [NSAttributedString.Key.font: withFont])
    }
    
    func caseChangeCount() -> Int {
        var caseChangeCount = 0
        var isLastCharUppercase: Bool? = nil
        for c in self {
            if isLastCharUppercase != nil && isLastCharUppercase != c.isUppercase {
                caseChangeCount += 1
            }
            isLastCharUppercase = c.isUppercase
        }
        return caseChangeCount
    }
    
    func caseMorph(caseForm: String) -> String {
        return Self.caseMorph(rimeText: self, englishText: caseForm)
    }
    
    func commonSuffix<T: StringProtocol>(with aString: T, options: String.CompareOptions = []) -> String {
        return String(zip(reversed(), aString.reversed())
            .lazy
            .prefix(while: { (lhs: Character, rhs: Character) in
                String(lhs).compare(String(rhs), options: options) == .orderedSame
            })
            .map { (lhs: Character, _: Character) in lhs }
            .reversed())
    }
    
    // Apply the case if english text to rime text. e.g. rime text: a b'c, english text: Abc. Return A b'c
    private static func caseMorph(rimeText: String, englishText: String) -> String {
        var casedMorphedText = ""
        
        var rimeTextCharIndex = rimeText.startIndex, englishTextCharIndex = englishText.startIndex
        while rimeTextCharIndex != rimeText.endIndex && englishTextCharIndex != englishText.endIndex {
            let rc = rimeText[rimeTextCharIndex], ec = englishText[englishTextCharIndex]
            if rc.isEnglishLetter {
                let isEnglishCharUppercased = ec.isUppercase
                if isEnglishCharUppercased {
                    casedMorphedText.append(rc.uppercased())
                } else {
                    casedMorphedText.append(rc.lowercased())
                }
            } else {
                casedMorphedText.append(rc)
            }
            rimeTextCharIndex = rimeText.index(after: rimeTextCharIndex)
            if rc != " " && rc != "'" {
                englishTextCharIndex = englishText.index(after: englishTextCharIndex)
            }
        }
        while rimeTextCharIndex != rimeText.endIndex {
            casedMorphedText.append(rimeText[rimeTextCharIndex])
            rimeTextCharIndex = rimeText.index(after: rimeTextCharIndex)
        }
        return casedMorphedText
    }
    
    var withoutTailingDigit: String {
        if self.isEmpty { return "" }
        if self.last!.isNumber && self.last!.isASCII {
            return String(self.prefix(count - 1))
        } else {
            return self
        }
    }
    
    // Render the string in HK Chinese style. (標點置中)
    func toHKAttributedString(withFont font: UIFont? = nil, withForegroundColor foregroundColor: UIColor? = nil) -> NSAttributedString {
        var attributes: [NSAttributedString.Key : Any] = [:]
        attributes[NSAttributedString.Key(kCTLanguageAttributeName as String)] = "zh-HK"
        
        if let font = font {
            attributes[.font] = font
        }
        
        if let foregroundColor = foregroundColor {
            attributes[.foregroundColor] = foregroundColor
        }
        
        return NSAttributedString(string: self, attributes: attributes)
    }
    
    var toHKAttributedString: NSAttributedString {
        toHKAttributedString()
    }
    
    func char(at: Int) -> Character? {
        guard 0 <= at && at < count else { return nil }
        return self[index(startIndex, offsetBy: at)]
    }
}
