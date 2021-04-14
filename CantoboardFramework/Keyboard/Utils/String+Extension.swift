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
    
    func caseMorph(caseForm: String) -> String {
        return Self.caseMorph(rimeText: self, englishText: caseForm)
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
}
