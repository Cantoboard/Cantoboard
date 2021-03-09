//
//  Character+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation

extension Character {
    var isEnglishLetter: Bool {
        isASCII && isLetter
    }
    
    var isSentensePunctuation: Bool {
        self == ":" || self == ";" || self == "." || self == "," || self == "?" || self == "!" || self == "'" || self ==  "\n" ||
            isFullShapeSentensePunctuation
    }
    
    var isFullShapeSentensePunctuation: Bool {
        self == "，" || self == "。" || self == "？" || self == "！"
    }
    
    var lowercasedChar: Character {
        lowercased().first!
    }
    
    var isRimeSpecialChar: Bool {
        isNumber || self == "'"
    }
    
    var isChineseChar: Bool {!isASCII /* TODO if char is in CJK range */
    }
}
