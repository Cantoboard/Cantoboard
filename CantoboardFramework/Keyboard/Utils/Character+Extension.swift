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
    
    var isPunctuation: Bool {
        // TODO Distingish apostrophe & single quote.
        self == ":" || self == ";" || self == "." || self == "," || self == "?" || self == "!" || self == "'" || self ==  "\n" ||
            self == ")" || self == "}" || self == "]" ||
            isFullShapePunctuation
    }
    
    var isFullShapePunctuation: Bool {
        self == "，" || self == "。" || self == "？" || self == "！"
    }
    
    var isHalfShapeTerminalPunctuation: Bool {
        // TODO Distingish apostrophe & single quote.
        self == "." || self == "?" || self == "!"
    }
    
    var isFullShapeTerminalPunctuation: Bool {
        self == "。" || self == "？" || self == "！"
    }
    
    var couldBeFollowedBySmartSpace: Bool {
        self != ":" && self != ";" && self != "." && self != "," && self != "?" && self != "!" && self != " " &&
        self != "，" && self != "。" && self != "？" && self != "！"
    }
    
    var lowercasedChar: Character {
        lowercased().first!
    }
    
    var isRimeSpecialChar: Bool {
        Settings.cached.rimeSettings.toneInputMode == .longPress ? (isNumber || self == "'") : (self == "'")
    }
    
    var isChineseChar: Bool {
        !isASCII /* TODO if char is in CJK range */
    }
    
    var isVowel: Bool {
        return self == "a" || self == "e" || self == "i" || self == "o" || self == "u" ||
            self == "A" || self == "E" || self == "I" || self == "O" || self == "U"
    }
}
