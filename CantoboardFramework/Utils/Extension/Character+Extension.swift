//
//  Character+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation

extension Character {
    private var properties: UnicodeScalar.Properties? {
        unicodeScalars.first?.properties
    }
    
    private var category: Unicode.GeneralCategory? {
        properties?.generalCategory
    }
    
    var isEnglishLetter: Bool {
        isASCII && isLetter
    }
    
    var isEnglishLetterOrDigit: Bool {
        isASCII && (isLetter || isNumber || category == .openPunctuation)
    }
    
    var shouldKeepSmartSpace: Bool {
        category == .initialPunctuation || isSymbol
    }
    
    var isPunctuation: Bool {
        category == .otherPunctuation
    }
    
    var isASCIIPunctuation: Bool {
        isPunctuation && isASCII
    }
    
    var isNonASCIIPunctuation: Bool {
        isPunctuation && !isASCII
    }
    
    var isSentenceTerminal: Bool {
        properties?.isSentenceTerminal ?? false
    }
    
    var isASCIISentenceTerminal: Bool {
        isSentenceTerminal && isASCII
    }
    
    var isNonASCIISentenceTerminal: Bool {
        isSentenceTerminal && !isASCII
    }
    
    var couldBeFollowedBySmartSpace: Bool {
        !isPunctuation && !isWhitespace
    }
    
    var isRimeSpecialChar: Bool {
        let isFixedRimeSpecialChar = self == "'" || self == "/"
        let isModeDependentRimeSpecialChar = Settings.cached.toneInputMode == .longPress && "123456".contains(self)
        return isFixedRimeSpecialChar || isModeDependentRimeSpecialChar
    }
    
    var isIdeographic: Bool {
        // (isLetter || isSymbol || isNumber) && (isIdeographic || [Han, Hiragana, Katakana].contains(script) || scriptExtensions & (Hani | Hira | Kana) != 0)
        switch unicodeScalars.first?.value ?? 0 {
        case 0x2E80...0x2E99, 0x2E9B...0x2EF3, 0x2F00...0x2FD5, 0x3005, 0x3013, 0x3031...0x3035, 0x3037, 0x303B...0x303C, 0x303E...0x303F, 0x3041...0x3096, 0x309B...0x309F, 0x30A1...0x30FA, 0x30FC...0x30FF, 0x3190...0x319F, 0x31C0...0x31E3, 0x31F0...0x31FF, 0x3220...0x3247, 0x3280...0x32B0, 0x32C0...0x32CB, 0x32D0...0x3370, 0x337B...0x337F, 0x33E0...0x33FE, 0xA700...0xA707, 0xFF66...0xFF9F, 0x16FE3, 0x1AFF0...0x1AFF3, 0x1AFF5...0x1AFFB, 0x1AFFD...0x1AFFE, 0x1B000...0x1B122, 0x1B150...0x1B152, 0x1B164...0x1B167, 0x1D360...0x1D371, 0x1F200, 0x1F250...0x1F251: return true
        case 0x16FE4: return false
        default: return properties?.isIdeographic ?? false
        }
    }
    
    var isLetterLike: Bool {
        (isLetter || isNumber) && !isIdeographic
    }
    
    var isNonLetterLike: Bool {
        !isLetter && !isNumber
    }
    
    var isSpace: Bool {
        isWhitespace && !isNewline
    }
    
    var isApostrophe: Bool {
        self == "'" || self == "’"
    }
}
